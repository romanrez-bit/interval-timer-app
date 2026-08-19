import 'dart:convert';
import 'package:flutter/services.dart';
import 'database_service.dart';

class RestRecommendationService {
  RestRecommendationService._internal();
  static final RestRecommendationService instance =
  RestRecommendationService._internal();

  Map<String, dynamic>? _model;
  bool _loaded = false;

  Future<void> init() async {
    if (_loaded) return;
    try {
      final jsonString =
      await rootBundle.loadString('assets/model_coefficients.json');
      _model = json.decode(jsonString) as Map<String, dynamic>;
    } catch (_) {
      _model = null;
    }
    _loaded = true;
  }

  int get _minWorkoutsForMl {
    final rule = _model?['cold_start_rule'] as Map<String, dynamic>?;
    return (rule?['min_workouts_for_ml'] as num?)?.toInt() ?? 10;
  }

  /// Рекомендованное время отдыха в секундах.
  /// Возвращает null, если рекомендации нет (нет RPE, модель не загрузилась,
  /// или рекомендация совпадает с заданным временем).
  Future<int?> recommendRest({
    required double? rpe,
    required int workSeconds,
    required int restSeconds,
    required int circuitNumber,
  }) async {
    if (rpe == null) return null;
    await init();

    final workoutCount = (await DatabaseService.instance.getWorkouts()).length;

    int recommended;
    if (workoutCount < _minWorkoutsForMl) {
      recommended = _coldStartRest(rpe, restSeconds);
    } else {
      recommended = _modelRest(
        rpe: rpe,
        workSeconds: workSeconds,
        restSeconds: restSeconds,
        circuitNumber: circuitNumber,
      );
    }

    // Не показываем рекомендацию, если она не даёт заметной разницы
    if (recommended <= restSeconds + 1) return null;
    return recommended;
  }

  /// Простое правило по ТЗ 4.5, пока тренировок мало.
  int _coldStartRest(double rpe, int restSeconds) {
    final rule = _model?['cold_start_rule'] as Map<String, dynamic>?;
    final gte = (rule?['if_previous_rpe_gte'] as num?)?.toDouble() ?? 8;
    final multiplier =
        (rule?['rest_multiplier'] as num?)?.toDouble() ?? 1.3;
    if (rpe >= gte) {
      return (restSeconds * multiplier).round();
    }
    return restSeconds;
  }

  /// Формула обученной модели (линейная регрессия).
  int _modelRest({
    required double rpe,
    required int workSeconds,
    required int restSeconds,
    required int circuitNumber,
  }) {
    final coefficients = _model?['coefficients'] as Map<String, dynamic>?;
    final intercept = (_model?['intercept'] as num?)?.toDouble() ?? 0;
    if (coefficients == null) return restSeconds;

    double c(String key) =>
        (coefficients[key] as num?)?.toDouble() ?? 0;

    final value = c('work_duration') * workSeconds +
        c('rest_duration') * restSeconds +
        c('rpe') * rpe +
        c('circuit_number') * circuitNumber +
        intercept;

    final rounded = value.round();
    // страховка от бессмысленных значений
    if (rounded < restSeconds) return restSeconds;
    if (rounded > restSeconds * 3) return restSeconds * 3;
    return rounded;
  }
}
