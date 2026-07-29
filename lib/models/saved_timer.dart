class SavedTimer {
  final int? id;
  final String name;
  final int prepSeconds;
  final int workSeconds;
  final int restSeconds;
  final int numCircuits;
  final String descriptionWork;
  final String descriptionRest;

  const SavedTimer({
    this.id,
    required this.name,
    required this.prepSeconds,
    required this.workSeconds,
    required this.restSeconds,
    required this.numCircuits,
    this.descriptionWork = '',
    this.descriptionRest = '',
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'prep_seconds': prepSeconds,
      'work_seconds': workSeconds,
      'rest_seconds': restSeconds,
      'num_circuits': numCircuits,
      'description_work': descriptionWork,
      'description_rest': descriptionRest,
    };
  }

  factory SavedTimer.fromMap(Map<String, dynamic> map) {
    return SavedTimer(
      id: map['id'] as int?,
      name: map['name'] as String,
      prepSeconds: map['prep_seconds'] as int,
      workSeconds: map['work_seconds'] as int,
      restSeconds: map['rest_seconds'] as int,
      numCircuits: map['num_circuits'] as int,
      descriptionWork: map['description_work'] as String? ?? '',
      descriptionRest: map['description_rest'] as String? ?? '',
    );
  }
}