import '../entities/metric_unit.dart';

/// Convierte entre kg y lb (lógica pura, sin persistencia).
class ConvertWeightUnit {
  static const double _lbToKg = 0.453592;

  double call({
    required double value,
    required MetricUnit fromUnit,
    required MetricUnit toUnit,
  }) {
    if (!fromUnit.isWeight || !toUnit.isWeight) {
      throw ArgumentError('Solo se puede convertir entre kg y lb');
    }
    if (fromUnit == toUnit) return value;
    if (fromUnit == MetricUnit.lb && toUnit == MetricUnit.kg) {
      return value * _lbToKg;
    }
    return value / _lbToKg;
  }
}
