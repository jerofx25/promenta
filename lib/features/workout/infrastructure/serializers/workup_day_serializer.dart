import 'package:IAEntrenar/models/workup_day.dart';

Map<String, dynamic> workupDayToJson(WorkupDay day) {
  return {
    'dayNumber': day.dayNumber,
    'title': day.title,
    'type': day.type.name,
    'description': day.description,
    'difficulty': day.difficulty.name,
    'warmUp': day.warmUp?.map(_warmUpToJson).toList(),
    'blocks': day.blocks.map(_blockToJson).toList(),
  };
}

Map<String, dynamic> _warmUpToJson(WarmUp w) {
  return {
    if (w.movement != null) 'movement': w.movement,
    if (w.volume != null) 'volume': w.volume,
    if (w.unit != null) 'unit': w.unit!.name.toLowerCase(),
    if (w.format != null) 'format': w.format,
    if (w.equipment != null) 'equipment': w.equipment,
    if (w.exercises != null)
      'exercises': w.exercises!.map(_movementElementToJson).toList(),
  };
}

Map<String, dynamic> _movementElementToJson(MovementElement e) {
  return {
    'movement': e.movement,
    if (e.volume != null) 'volume': e.volume,
    if (e.unit != null) 'unit': e.unit!.name.toLowerCase(),
  };
}

Map<String, dynamic> _blockToJson(Block b) {
  final progressionJson = _progressionToJson(b.progression);
  return {
    if (b.blockLetter != null) 'blockLetter': b.blockLetter!.name,
    if (b.format != null) 'format': b.format,
    if (b.volume != null) 'volume': b.volume,
    if (b.unit != null) 'unit': b.unit!.name.toLowerCase(),
    if (b.intensity != null) 'intensity': b.intensity,
    if (b.intensityUnit != null) 'intensityUnit': b.intensityUnit,
    if (b.restBetweenRounds != null) 'restBetweenRounds': b.restBetweenRounds,
    if (b.repScheme != null) 'repScheme': b.repScheme,
    if (b.movements != null) 'movements': b.movements,
    if (b.ladder != null) 'ladder': b.ladder!.map(_ladderToJson).toList(),
    if (b.exercises != null)
      'exercises': b.exercises!.map(_blockExerciseToJson).toList(),
    if (b.parts != null) 'parts': b.parts!.map(_partToJson).toList(),
    if (progressionJson != null) 'progression': progressionJson,
  };
}

dynamic _progressionToJson(dynamic progression) {
  if (progression == null) return null;

  // Some workouts store progression as a human-readable string.
  if (progression is String || progression is num || progression is bool) {
    return progression;
  }

  // Some workouts store progression as a list of ProgressionElement.
  if (progression is List<ProgressionElement>) {
    return progression.map(_progressionElementToJson).toList();
  }

  // Sometimes it can already be decoded JSON (List<Map>).
  if (progression is List) {
    return progression.map((e) {
      if (e is ProgressionElement) return _progressionElementToJson(e);
      if (e is Map<String, dynamic>) return e;
      if (e is Map) return Map<String, dynamic>.from(e);
      return e;
    }).toList();
  }

  // Fallback: stringify unknown structures.
  return progression.toString();
}

Map<String, dynamic> _progressionElementToJson(ProgressionElement p) {
  return {
    'minutes': p.minutes,
    'volume': p.volume,
    if (p.unit != null) 'unit': p.unit!.name.toLowerCase(),
    'intensity': p.intensity,
    'intensityUnit': p.intensityUnit,
  };
}

Map<String, dynamic> _ladderToJson(Ladder l) {
  return {
    'volume': l.volume,
    if (l.unit != null) 'unit': l.unit!.name.toLowerCase(),
    'weight': l.weight,
    'weightUnit': l.weightUnit,
  };
}

Map<String, dynamic> _blockExerciseToJson(BlockExercise e) {
  return {
    if (e.type != null) 'type': e.type,
    if (e.movement != null) 'movement': e.movement,
    if (e.interval != null) 'interval': e.interval,
    if (e.volume != null) 'volume': e.volume,
    if (e.unit != null) 'unit': e.unit!.name.toLowerCase(),
    if (e.sets != null) 'sets': e.sets,
    if (e.notes != null) 'notes': e.notes,
    if (e.intensity != null) 'intensity': e.intensity,
    if (e.intensityUnit != null) 'intensityUnit': e.intensityUnit,
    if (e.volumePerLeg != null) 'volumePerLeg': e.volumePerLeg,
    if (e.weight != null) 'weight': e.weight,
    if (e.weightUnit != null) 'weightUnit': e.weightUnit,
    if (e.movements != null)
      'movements': e.movements!.map(_movementElementToJson).toList(),
  };
}

Map<String, dynamic> _partToJson(Part p) {
  return {
    if (p.format != null) 'format': p.format,
    if (p.volume != null) 'volume': p.volume,
    if (p.unit != null) 'unit': p.unit!.name.toLowerCase(),
    if (p.movement != null) 'movement': p.movement,
    if (p.repScheme != null) 'repScheme': p.repScheme,
    if (p.intervalDuration != null) 'intervalDuration': p.intervalDuration,
    if (p.intervalUnit != null) 'intervalUnit': p.intervalUnit!.name.toLowerCase(),
    if (p.totalRounds != null) 'totalRounds': p.totalRounds,
    if (p.sets != null) 'sets': p.sets,
    if (p.tempo != null) 'tempo': p.tempo,
    if (p.intensity != null) 'intensity': p.intensity,
    if (p.intensityUnit != null) 'intensityUnit': p.intensityUnit,
    if (p.exercises != null)
      'exercises': p.exercises!.map(_partExerciseToJson).toList(),
  };
}

Map<String, dynamic> _partExerciseToJson(PartExercise pe) {
  return {
    if (pe.movement != null) 'movement': pe.movement,
    if (pe.volume != null) 'volume': pe.volume,
    if (pe.unit != null) 'unit': pe.unit,
    if (pe.distancePerLine != null) 'distancePerLine': pe.distancePerLine,
    if (pe.intensity != null) 'intensity': pe.intensity,
    if (pe.intensityUnit != null) 'intensityUnit': pe.intensityUnit,
    if (pe.notes != null) 'notes': pe.notes,
    if (pe.weight != null) 'weight': pe.weight,
    if (pe.weightUnit != null) 'weightUnit': pe.weightUnit,
  };
}

