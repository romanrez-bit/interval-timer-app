import 'package:flutter/material.dart';
import '../models/workout.dart';
import '../services/database_service.dart';
import '../widgets/rpe_dialog.dart';

class SummaryScreen extends StatelessWidget {
  final String workoutName;
  final DateTime startedAt;
  final int totalDurationSeconds;
  final int totalExtraPauseSeconds;
  final int completedCircuits;
  final int plannedCircuits;
  final List<double?> rpeLog;
  final int prepSeconds;
  final int workSeconds;
  final int restSeconds;

  const SummaryScreen({
    super.key,
    required this.workoutName,
    required this.startedAt,
    required this.totalDurationSeconds,
    required this.totalExtraPauseSeconds,
    required this.completedCircuits,
    required this.plannedCircuits,
    required this.rpeLog,
    required this.prepSeconds,
    required this.workSeconds,
    required this.restSeconds,
  });

  static const _colorWork = Color(0xFFE3620F);
  static const _colorExtraPause = Color(0xFF7A93A6);
  static const _cardBg = Color(0xFF161616);
  static const _muted = Color(0xFF8A8A86);

  static const _months = [
    'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
    'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря'
  ];

  String get _dateText {
    final d = startedAt;
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    return '${d.day} ${_months[d.month - 1]} ${d.year}, $hh:$mm';
  }

  String _formatDuration(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  double get _avgRpe {
    final values = rpeLog.whereType<double>().toList();
    if (values.isEmpty) return 0;
    final sum = values.fold<double>(0, (a, b) => a + b);
    return sum / values.length;
  }

  RpeOption? _optionForValue(double value) {
    for (final option in rpeOptions) {
      if (option.value == value) return option;
    }
    return null;
  }

  Future<void> _save(BuildContext context) async {
    final workout = Workout(
      name: workoutName,
      date: startedAt.toIso8601String(),
      totalDuration: totalDurationSeconds,
      avgRpe: _avgRpe,
      prepSeconds: prepSeconds,
      workSeconds: workSeconds,
      restSeconds: restSeconds,
      numCircuits: plannedCircuits,
      completedCircuits: completedCircuits,
      totalExtraPauseSeconds: totalExtraPauseSeconds,
    );

    final logs = <CircuitLog>[];
    for (var i = 0; i < rpeLog.length; i++) {
      logs.add(CircuitLog(
        workoutId: 0, // проставится при сохранении
        circuitNumber: i + 1,
        rpe: rpeLog[i],
      ));
    }

    await DatabaseService.instance.saveWorkout(workout, logs);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Тренировка сохранена')),
      );
      Navigator.popUntil(context, (route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
          child: Column(
            children: [
              Text(
                workoutName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: _colorWork,
                    fontSize: 22,
                    fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 5),
              Text('завершена · $_dateText',
                  style: const TextStyle(color: _muted, fontSize: 13)),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(
                    child: _statTile('длительность',
                        _formatDuration(totalDurationSeconds), Colors.white)),
                const SizedBox(width: 10),
                Expanded(
                    child: _statTile('кругов',
                        '$completedCircuits / $plannedCircuits', Colors.white)),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                    child: _statTile(
                        'средний RPE',
                        _avgRpe == 0 ? '—' : _avgRpe.toStringAsFixed(1),
                        _colorWork)),
                const SizedBox(width: 10),
                Expanded(
                    child: _statTile(
                        'доп. паузы',
                        _formatDuration(totalExtraPauseSeconds),
                        _colorExtraPause)),
              ]),
              const SizedBox(height: 20),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('RPE по кругам',
                    style: TextStyle(color: _muted, fontSize: 12)),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                      color: _cardBg,
                      borderRadius: BorderRadius.circular(12)),
                  child: rpeLog.isEmpty
                      ? const Center(
                    child: Text('нет данных',
                        style:
                        TextStyle(color: _muted, fontSize: 13)),
                  )
                      : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    itemCount: rpeLog.length,
                    itemBuilder: (context, index) =>
                        _circuitRow(index, rpeLog[index]),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.popUntil(
                          context, (route) => route.isFirst),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                            color: Color(0xFF4A4A46), width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('не сохранять',
                          style:
                          TextStyle(color: Colors.white, fontSize: 15)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _save(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _colorWork,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('сохранить',
                          style: TextStyle(
                              color: Colors.black,
                              fontSize: 15,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statTile(String label, String value, Color valueColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: _cardBg, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: _muted, fontSize: 11)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  color: valueColor,
                  fontSize: 22,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _circuitRow(int index, double? rpe) {
    final option = rpe == null ? null : _optionForValue(rpe);
    final isLast = index == rpeLog.length - 1;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
            bottom: BorderSide(color: Color(0xFF232323), width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('круг ${index + 1}',
              style: const TextStyle(color: _muted, fontSize: 13)),
          Text(
            option == null
                ? 'не отмечен'
                : '${option.emoji} ${option.label} · ${rpe == rpe!.roundToDouble() ? rpe.toInt() : rpe}',
            style: TextStyle(
                color: option == null ? _muted : Colors.white, fontSize: 13),
          ),
        ],
      ),
    );
  }
}