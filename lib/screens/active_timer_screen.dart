import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../services/notification_service.dart';
import '../widgets/rpe_dialog.dart';
import 'summary_screen.dart';

enum _Phase { prep, work, rest, done }

class ActiveTimerScreen extends StatefulWidget {
  final String workoutName;
  final int prepSeconds;
  final int workSeconds;
  final int restSeconds;
  final int numCircuits;

  const ActiveTimerScreen({
    super.key,
    required this.workoutName,
    required this.prepSeconds,
    required this.workSeconds,
    required this.restSeconds,
    required this.numCircuits,
  });

  @override
  State<ActiveTimerScreen> createState() => _ActiveTimerScreenState();
}

class _ActiveTimerScreenState extends State<ActiveTimerScreen> {
  static const _colorPrep = Color(0xFFD4A017);
  static const _colorWork = Color(0xFFE3620F);
  static const _colorRest = Color(0xFF4ADE80);
  static const _colorExtraPause = Color(0xFF7A93A6);
  static const _muted = Color(0xFF8A8A86);

  Timer? _timer;
  _Phase _phase = _Phase.prep;
  int _secondsLeft = 0;
  int _currentCircuit = 1;
  bool _isPaused = false;
  final List<double?> _rpeLog = [];

  bool _isExtraPause = false;
  int _extraPauseSeconds = 0;
  int _totalExtraPauseSeconds = 0;

  final AudioPlayer _audioPlayer = AudioPlayer();
  late final DateTime _startedAt;

  @override
  void initState() {
    super.initState();
    _startedAt = DateTime.now();
    _secondsLeft = widget.prepSeconds;
    _startTicking();
    WakelockPlus.enable();
    _scheduleCurrentPhaseNotification();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioPlayer.dispose();
    WakelockPlus.disable();
    NotificationService.instance.cancelPhaseNotification();
    super.dispose();
  }

  void _startTicking() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  /// Планирует уведомление на конец текущей фазы.
  void _scheduleCurrentPhaseNotification() {
    if (_phase == _Phase.done || _isPaused || _isExtraPause) return;
    String title;
    String body;
    switch (_phase) {
      case _Phase.prep:
        title = 'Работа';
        body = 'Подготовка окончена — начинай!';
        break;
      case _Phase.work:
        title = 'Круг завершён';
        body = 'Открой приложение, чтобы оценить круг';
        break;
      case _Phase.rest:
        title = 'Работа';
        body = 'Отдых окончен — круг ${_currentCircuit + 1}';
        break;
      case _Phase.done:
        return;
    }
    NotificationService.instance.schedulePhaseNotification(
      title: title,
      body: body,
      seconds: _secondsLeft,
    );
  }

  void _cancelPhaseNotification() {
    NotificationService.instance.cancelPhaseNotification();
  }

  Future<void> _playSound(String fileName) async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource('sounds/$fileName'));
    } catch (_) {
      // если файл ещё не добавлен — просто не будет звука
    }
  }

  void _signalTransition(String soundFile) {
    _playSound(soundFile);
    HapticFeedback.mediumImpact();
  }

  void _tick() {
    if (_isExtraPause) {
      setState(() => _extraPauseSeconds++);
      return;
    }
    if (_isPaused) return;
    if (_secondsLeft > 1) {
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 5 && _secondsLeft >= 1) {
        _playSound('tick.mp3');
      }
    } else if (_phase == _Phase.work) {
      _handleWorkComplete();
    } else {
      _advancePhase();
    }
  }

  Future<void> _handleWorkComplete() async {
    setState(() => _isPaused = true);
    _cancelPhaseNotification();
    await _audioPlayer.stop();
    final rpe = await showRpeDialog(
      context,
      circuitNumber: _currentCircuit,
      totalCircuits: widget.numCircuits,
    );
    if (!mounted) return;
    _rpeLog.add(rpe);
    if (_currentCircuit >= widget.numCircuits) {
      _timer?.cancel();
      setState(() {
        _isPaused = false;
        _phase = _Phase.done;
      });
      _signalTransition('workout_complete.mp3');
      return;
    }
    int restDuration = widget.restSeconds;
    if (rpe == null) {
      restDuration = (widget.restSeconds - 5).clamp(0, widget.restSeconds);
    }
    setState(() {
      _isPaused = false;
      _phase = _Phase.rest;
      _secondsLeft = restDuration;
    });
    _signalTransition('phase_start.mp3');
    _scheduleCurrentPhaseNotification();
  }

  void _advancePhase() {
    String? soundFile;
    switch (_phase) {
      case _Phase.prep:
        soundFile = 'phase_start.mp3';
        break;
      case _Phase.rest:
        soundFile = 'circuit_complete.mp3';
        break;
      case _Phase.work:
      case _Phase.done:
        break;
    }
    if (soundFile != null) {
      _signalTransition(soundFile);
    }
    setState(() {
      switch (_phase) {
        case _Phase.prep:
          _phase = _Phase.work;
          _secondsLeft = widget.workSeconds;
          break;
        case _Phase.rest:
          _currentCircuit++;
          _phase = _Phase.work;
          _secondsLeft = widget.workSeconds;
          break;
        case _Phase.work:
        case _Phase.done:
          break;
      }
    });
    _scheduleCurrentPhaseNotification();
  }

  void _togglePause() {
    final pausing = !_isPaused;
    setState(() => _isPaused = pausing);
    if (pausing) {
      _audioPlayer.stop();
      _cancelPhaseNotification();
    } else {
      _scheduleCurrentPhaseNotification();
    }
  }

  void _toggleExtraPause() {
    setState(() {
      if (_isExtraPause) {
        _totalExtraPauseSeconds += _extraPauseSeconds;
        _extraPauseSeconds = 0;
        _isExtraPause = false;
      } else {
        _isExtraPause = true;
        _extraPauseSeconds = 0;
      }
    });
    if (_isExtraPause) {
      _cancelPhaseNotification();
    } else {
      _scheduleCurrentPhaseNotification();
    }
  }

  void _openSummary() {
    final elapsed = DateTime.now().difference(_startedAt).inSeconds;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => SummaryScreen(
          workoutName: widget.workoutName,
          startedAt: _startedAt,
          totalDurationSeconds: elapsed,
          totalExtraPauseSeconds: _totalExtraPauseSeconds,
          completedCircuits: _rpeLog.length,
          plannedCircuits: widget.numCircuits,
          rpeLog: List<double?>.from(_rpeLog),
          prepSeconds: widget.prepSeconds,
          workSeconds: widget.workSeconds,
          restSeconds: widget.restSeconds,
        ),
      ),
    );
  }

  Future<void> _confirmStopWorkout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161616),
        title: const Text(
          'Закончить тренировку?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Текущий прогресс не сохранится.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Закончить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      _timer?.cancel();
      _audioPlayer.stop();
      _cancelPhaseNotification();
      Navigator.pop(context);
    }
  }

  Color get _phaseColor {
    if (_isExtraPause) return _colorExtraPause;
    switch (_phase) {
      case _Phase.prep:
        return _colorPrep;
      case _Phase.work:
        return _colorWork;
      case _Phase.rest:
        return _colorRest;
      case _Phase.done:
        return Colors.white;
    }
  }

  String get _phaseLabel {
    if (_isExtraPause) return 'ДОП. ПАУЗА';
    switch (_phase) {
      case _Phase.prep:
        return 'ПОДГОТОВКА';
      case _Phase.work:
        return 'РАБОТА';
      case _Phase.rest:
        return 'ОТДЫХ';
      case _Phase.done:
        return 'ГОТОВО';
    }
  }

  String get _timeText {
    final seconds = _isExtraPause ? _extraPauseSeconds : _secondsLeft;
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final isDone = _phase == _Phase.done;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                width: double.infinity,
                height: 40,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(
                      isDone
                          ? ''
                          : 'круг $_currentCircuit / ${widget.numCircuits}',
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 22,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (!isDone)
                      Positioned(
                        right: 0,
                        child: IconButton(
                          onPressed: _confirmStopWorkout,
                          icon: const Icon(
                            Icons.stop_circle_outlined,
                            color: Colors.redAccent,
                            size: 26,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Column(
                children: [
                  Text(
                    _phaseLabel,
                    style: TextStyle(
                      color: _phaseColor,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isDone ? '' : _timeText,
                    style: TextStyle(
                      color: _phaseColor,
                      fontSize: 120,
                      fontWeight: FontWeight.w700,
                      height: 1,
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: isDone
                        ? ElevatedButton(
                            onPressed: _openSummary,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _colorRest,
                              padding: const EdgeInsets.symmetric(vertical: 22),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
                              'готово',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1,
                              ),
                            ),
                          )
                        : _isExtraPause
                        ? ElevatedButton(
                            onPressed: _toggleExtraPause,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _colorExtraPause,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
                              'продолжить',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1,
                              ),
                            ),
                          )
                        : OutlinedButton(
                            onPressed: _togglePause,
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                color: Color(0xFF4A4A46),
                                width: 1.5,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              _isPaused ? 'продолжить' : 'пауза',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                  ),
                  if (!isDone && !_isExtraPause) ...[
                    const SizedBox(height: 14),
                    TextButton.icon(
                      onPressed: _toggleExtraPause,
                      icon: const Icon(
                        Icons.pause_circle_outline,
                        color: _muted,
                        size: 18,
                      ),
                      label: const Text(
                        'доп. пауза',
                        style: TextStyle(
                          color: _muted,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
