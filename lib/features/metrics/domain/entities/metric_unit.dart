/// Unidad de medida de una métrica.
/// En Firestore se guarda el nombre (name); fuerza se almacena siempre en kg.
enum MetricUnit {
  kg,
  lb,
  reps,
  seconds,
  minutes,
  hours,
  score;

  String get firestoreValue => name;

  static MetricUnit? fromFirestore(String? value) {
    if (value == null) return null;
    return MetricUnit.values.cast<MetricUnit?>().firstWhere(
          (e) => e!.name == value,
          orElse: () => null,
        );
  }

  bool get isWeight => this == MetricUnit.kg || this == MetricUnit.lb;
}
