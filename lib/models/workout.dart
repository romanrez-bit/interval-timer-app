class Workout {
  final int? id;
  final String name;
  final String date;
  final int totalDuration;
  final double avgRpe;
  final int prepSeconds;
  final int workSeconds;
  final int restSeconds;
  final int numCircuits;
  final int completedCircuits;
  final int totalExtraPauseSeconds;

  const Workout({
    this.id,
    required this.name,
    required this.date,
    required this.totalDuration,
    required this.avgRpe,
    required this.prepSeconds,
    required this.workSeconds,
    required this.restSeconds,
    required this.numCircuits,
    required this.completedCircuits,
    required this.totalExtraPauseSeconds,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'date': date,
      'total_duration': totalDuration,
      'avg_rpe': avgRpe,
      'prep_seconds': prepSeconds,
      'work_seconds': workSeconds,
      'rest_seconds': restSeconds,
      'num_circuits': numCircuits,
      'completed_circuits': completedCircuits,
      'total_extra_pause_seconds': totalExtraPauseSeconds,
    };
  }

  factory Workout.fromMap(Map<String, dynamic> map) {
    return Workout(
      id: map['id'] as int?,
      name: map['name'] as String? ?? '',
      date: map['date'] as String,
      totalDuration: map['total_duration'] as int,
      avgRpe: (map['avg_rpe'] as num?)?.toDouble() ?? 0,
      prepSeconds: map['prep_seconds'] as int,
      workSeconds: map['work_seconds'] as int,
      restSeconds: map['rest_seconds'] as int,
      numCircuits: map['num_circuits'] as int,
      completedCircuits: map['completed_circuits'] as int? ?? 0,
      totalExtraPauseSeconds: map['total_extra_pause_seconds'] as int? ?? 0,
    );
  }
}

class CircuitLog {
  final int? id;
  final int workoutId;
  final int circuitNumber;
  final double? rpe;
  final int extraPauseSeconds;

  const CircuitLog({
    this.id,
    required this.workoutId,
    required this.circuitNumber,
    this.rpe,
    this.extraPauseSeconds = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'workout_id': workoutId,
      'circuit_number': circuitNumber,
      'rpe': rpe,
      'extra_pause_seconds': extraPauseSeconds,
    };
  }

  factory CircuitLog.fromMap(Map<String, dynamic> map) {
    return CircuitLog(
      id: map['id'] as int?,
      workoutId: map['workout_id'] as int,
      circuitNumber: map['circuit_number'] as int,
      rpe: (map['rpe'] as num?)?.toDouble(),
      extraPauseSeconds: map['extra_pause_seconds'] as int? ?? 0,
    );
  }
}