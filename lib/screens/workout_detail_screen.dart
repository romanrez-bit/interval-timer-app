import 'package:flutter/material.dart';
import '../models/workout.dart';
import '../services/database_service.dart';
import '../widgets/rpe_dialog.dart';

class WorkoutDetailScreen extends StatefulWidget {
  final Workout workout;

  const WorkoutDetailScreen({super.key, required this.workout});

  @override
  State<WorkoutDetailScreen> createState() => _WorkoutDetailScreenState();
}

class _WorkoutDetailScreenState extends State<WorkoutDetailScreen> {
  static const _colorWork = Color(0xFFE3620F);
  static const _colorExtraPause = Color(0xFF7A93A6);
  static const _cardBg = Color(0xFF161616);
  static const _muted = Color(0xFF8A8A86);

  static const _months = [
    'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
    'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря'
  ];

  List<CircuitLog> _logs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    final logs =
    await DatabaseService.instance.getCircuitLogs(widget.workout.id!);
    if (!mounted) return;
    setState(() {
      _logs = logs;
      _loading = false;
    });
  }

  String get _dateText {
    final d = DateTime.tryParse(widget.workout.date);
    if (d == null) return '';
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    return '${d.day} ${_months[d.month - 1]} ${d.year}, $hh:$mm';
  }

  String _formatDuration(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  RpeOption? _optionForValue(double value) {
    for (final option in rpeOptions) {
      if (option.value == value) return option;
    }
    return null;
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cardBg,
        title: const Text('Удалить тренировку?',
            style: TextStyle(color: Colors.white)),
        content: const Text('Запись будет удалена из истории безвозвратно.',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await DatabaseService.instance.deleteWorkout(widget.workout.id!);
      if (mounted) Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.workout;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon:
                    const Icon(Icons.arrow_back, color: _muted, size: 22),
                    padding: EdgeInsets.zero,
                    constraints:
                    const BoxConstraints(minWidth: 36, minHeight: 36),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: _confirmDelete,
                    icon: const Icon(Icons.delete_outline,
                        color: _muted, size: 22),
                    padding: EdgeInsets.zero,
                    constraints:
                    const BoxConstraints(minWidth: 36, minHeight: 36),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                w.name.isEmpty ? 'Тренировка' : w.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: _colorWork,
                    fontSize: 22,
                    fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 5),
              Text(_dateText,
                  style: const TextStyle(color: _muted, fontSize: 13)),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(
                    child: _statTile('длительность',
                        _formatDuration(w.totalDuration), Colors.white)),
                const SizedBox(width: 10),
                Expanded(
                    child: _statTile('кругов',
                        '${w.completedCircuits} / ${w.numCircuits}',
                        Colors.white)),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                    child: _statTile(
                        'средний RPE',
                        w.avgRpe == 0 ? '—' : w.avgRpe.toStringAsFixed(1),
                        _colorWork)),
                const SizedBox(width: 10),
                Expanded(
                    child: _statTile(
                        'доп. паузы',
                        _formatDuration(w.totalExtraPauseSeconds),
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
                  child: _loading
                      ? const Center(
                      child: CircularProgressIndicator(color: _muted))
                      : _logs.isEmpty
                      ? const Center(
                    child: Text('нет данных',
                        style: TextStyle(
                            color: _muted, fontSize: 13)),
                  )
                      : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    itemCount: _logs.length,
                    itemBuilder: (context, index) =>
                        _circuitRow(index, _logs[index]),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'параметры: ${w.workSeconds}/${w.restSeconds} · подготовка ${w.prepSeconds} сек',
                style: const TextStyle(color: _muted, fontSize: 12),
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

  Widget _circuitRow(int index, CircuitLog log) {
    final option = log.rpe == null ? null : _optionForValue(log.rpe!);
    final isLast = index == _logs.length - 1;
    final rpe = log.rpe;
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
          Text('круг ${log.circuitNumber}',
              style: const TextStyle(color: _muted, fontSize: 13)),
          Text(
            option == null || rpe == null
                ? 'не отмечен'
                : '${option.emoji} ${option.label} · ${rpe == rpe.roundToDouble() ? rpe.toInt() : rpe}',
            style: TextStyle(
                color: option == null ? _muted : Colors.white, fontSize: 13),
          ),
        ],
      ),
    );
  }
}