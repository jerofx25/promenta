/// Resultado de un porcentaje de RM (peso a usar para ese %).
class RMPercentageEntry {
  const RMPercentageEntry({
    required this.percent,
    required this.weight,
  });
  final int percent;
  final double weight;
}

/// Calcula la tabla de porcentajes de RM (10% a 100%) a partir del peso en kg.
class CalculateRmPercentages {
  /// [rmKg] debe ser el 1RM en kg. [step] es el incremento (ej. 5 para 10, 15, 20...).
  List<RMPercentageEntry> call({
    required double rmKg,
    int step = 5,
  }) {
    if (rmKg <= 0) return [];
    final entries = <RMPercentageEntry>[];
    for (int percent = 10; percent <= 100; percent += step) {
      final weight = rmKg * percent / 100;
      entries.add(RMPercentageEntry(percent: percent, weight: weight));
    }
    return entries;
  }
}
