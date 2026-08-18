import 'package:flutter/material.dart';
import '../models/workout.dart';
import '../services/database_service.dart';
import 'workout_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  static const _colorWork = Color(0xFFE3620F);
  static const _cardBg = Color(0xFF161616);
  static const _muted = Color(0xFF8A8A86);

  static const _months = [
    'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
    'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря'
  ];

  List<Workout> _workouts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadWorkouts();
  }

  Future<void> _loadWorkouts() async {
    final workouts = await DatabaseService.instance.getWorkouts();
    if (!mounted) return;
    setState(() {
      _workouts = workouts;
      _loading = false;
    });
  }

  String _formatDate(String isoDate) {
    final d = DateTime.tryParse(isoDate);
    if (d == null) return '';
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    return '${d.day} ${_months[d.month - 1]}, $hh:$mm';
  }

  String _formatDuration(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String _circuitsText(Workout w) {
    if (w.completedCircuits < w.numCircuits) {
      return '${w.completedCircuits} / ${w.numCircuits} кругов';
    }
    return '${w.completedCircuits} кругов';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back,
                        color: _muted, size: 22),
                    padding: EdgeInsets.zero,
                    constraints:
                    const BoxConstraints(minWidth: 36, minHeight: 36),
                  ),
                  const SizedBox(width: 8),
                  const Text('История тренировок',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: _loading
                    ? const Center(
                  child: CircularProgressIndicator(color: _muted),
                )
                    : _workouts.isEmpty
                    ? const Center(
                  child: Text('пока нет сохранённых тренировок',
                      style: TextStyle(
                          color: _muted, fontSize: 14)),
                )
                    : ListView.builder(
                  itemCount: _workouts.length,
                  itemBuilder: (context, index) =>
                      _workoutCard(_workouts[index]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openDetail(Workout w) async {
    final deleted = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => WorkoutDetailScreen(workout: w)),
    );
    if (deleted == true) {
      _loadWorkouts();
    }
  }

  Widget _workoutCard(Workout w) {
    return GestureDetector(
        onTap: () => _openDetail(w),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: _cardBg, borderRadius: BorderRadius.circular(12)),
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  w.name.isEmpty ? 'Тренировка' : w.name,
                  style: const TextStyle(
                      color: _colorWork,
                      fontSize: 15,
                      fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(width: 8),
              Text(_formatDate(w.date),
                  style: const TextStyle(color: _muted, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.schedule, color: _muted, size: 14),
              const SizedBox(width: 4),
              Text(_formatDuration(w.totalDuration),
                  style: const TextStyle(color: _muted, fontSize: 13)),
              const SizedBox(width: 16),
              const Icon(Icons.repeat, color: _muted, size: 14),
              const SizedBox(width: 4),
              Text(_circuitsText(w),
                  style: const TextStyle(color: _muted, fontSize: 13)),
              const SizedBox(width: 16),
              Text(
                  w.avgRpe == 0
                      ? 'RPE —'
                      : 'RPE ${w.avgRpe.toStringAsFixed(1)}',
                  style: const TextStyle(color: _muted, fontSize: 13)),
            ],
          ),
        ],
          ),
        ),
    );
  }
}