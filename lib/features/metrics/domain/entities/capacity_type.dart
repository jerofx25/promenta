/// Tipo de capacidad física para clasificar métricas.
/// Usado en Firestore como string (name).
enum CapacityType {
  strength,
  endurance,
  speed,
  mobility,
  cardio;

  String get firestoreValue => name;

  static CapacityType? fromFirestore(String? value) {
    if (value == null) return null;
    return CapacityType.values.cast<CapacityType?>().firstWhere(
          (e) => e!.name == value,
          orElse: () => null,
        );
  }

  /// Etiqueta para UI (radar, listas).
  String get displayName {
    switch (this) {
      case CapacityType.strength:
        return 'Fuerza';
      case CapacityType.endurance:
        return 'Resistencia';
      case CapacityType.speed:
        return 'Velocidad';
      case CapacityType.mobility:
        return 'Movilidad';
      case CapacityType.cardio:
        return 'Cardio';
    }
  }
}
