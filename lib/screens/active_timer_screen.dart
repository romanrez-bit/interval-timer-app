import 'dart:async';
import 'package:flutter/material.dart';
import '../widgets/rpe_dialog.dart';

enum _Phase { prep, work, rest, done }

class ActiveTimerScreen extends StatefulWidget {
  final int prepSeconds;
  final int workSeconds;
  final int restSeconds;
  final int numCircuits;

  const ActiveTimerScreen({
    super.key,
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
  static const _muted = Color(0xFF8A8A86);

  Timer? _timer;
  _Phase _phase = _Phase.prep;
  int _secondsLeft = 0;
  int _currentCircuit = 1;
  bool _isPaused = false;
  final List<double> _rpeLog = [];

  @override
  void initState() {
    super.initState();
    _secondsLeft = widget.prepSeconds;
    _startTicking();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTicking() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (_isPaused) return;
    if (_secondsLeft > 1) {
      setState(() => _secondsLeft--);
    } else if (_phase == _Phase.work) {
      _handleWorkComplete();
    } else {
      _advancePhase();
    }
  }

  Future<void> _handleWorkComplete() async {
    setState(() => _isPaused = true);
    final rpe = await showRpeDialog(
      context,
      circuitNumber: _currentCircuit,
      totalCircuits: widget.numCircuits,
    );
    if (!mounted) return;
    int restDuration = widget.restSeconds;
    if (rpe != null) {
      _rpeLog.add(rpe);
    } else {
      restDuration = (widget.restSeconds - 5).clamp(0, widget.restSeconds);
    }
    setState(() {
      _isPaused = false;
      _phase = _Phase.rest;
      _secondsLeft = restDuration;
    });
  }

  void _advancePhase() {
    setState(() {
      switch (_phase) {
        case _Phase.prep:
          _phase = _Phase.work;
          _secondsLeft = widget.workSeconds;
          break;
        case _Phase.rest:
          if (_currentCircuit >= widget.numCircuits) {
            _phase = _Phase.done;
            _timer?.cancel();
          } else {
            _currentCircuit++;
            _phase = _Phase.work;
            _secondsLeft = widget.workSeconds;
          }
          break;
        case _Phase.work:
        case _Phase.done:
          break;
      }
    });
  }

  void _togglePause() {
    setState(() => _isPaused = !_isPaused);
  }

  Color get _phaseColor {
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
    final m = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    final s = (_secondsLeft % 60).toString().padLeft(2, '0');
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
              Text(
                isDone ? '' : 'круг $_currentCircuit / ${widget.numCircuits}',
                style: const TextStyle(
                  color: _muted,
                  fontSize: 26,
                  fontWeight: FontWeight.w500,
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
              SizedBox(
                width: double.infinity,
                child: isDone
                    ? ElevatedButton(
                        onPressed: () => Navigator.pop(context),
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
            ],
          ),
        ),
      ),
    );
  }
}
