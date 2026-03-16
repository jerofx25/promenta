/// Modelos para documentos de la colección Firestore [workups].
/// Uso: WorkupDay.fromJson(doc.data()) para cada documento.

Unit? _unitFromJson(dynamic value) {
  if (value == null) return null;
  final s = value.toString();
  return unitValues.map.containsKey(s) ? unitValues.map[s]! : null;
}

BlockLetter? _blockLetterFromJson(dynamic value) {
  if (value == null) return null;
  final s = value.toString();
  return blockLetterValues.map.containsKey(s) ? blockLetterValues.map[s]! : null;
}

num _numFromJson(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value;
  if (value is int) return value;
  if (value is String) return num.tryParse(value) ?? 0;
  return 0;
}

class WorkupDay {
  final int dayNumber;
  final String title;
  final List<WarmUp>? warmUp;
  final List<Block> blocks;

  WorkupDay({
    required this.dayNumber,
    required this.title,
    this.warmUp,
    required this.blocks,
  });

  factory WorkupDay.fromJson(Map<String, dynamic> json) => WorkupDay(
        dayNumber: json["dayNumber"] as int? ?? 0,
        title: json["title"] as String? ?? "",
        warmUp: json["warmUp"] == null
            ? null
            : List<WarmUp>.from(
                (json["warmUp"] as List).map((x) => WarmUp.fromJson(x))),
        blocks: json["blocks"] == null
            ? []
            : List<Block>.from(
                (json["blocks"] as List).map((x) => Block.fromJson(x))),
      );
}

class Block {
  final BlockLetter? blockLetter;
  final String? format;
  final int? volume;
  final Unit? unit;
  final List<BlockExercise>? exercises;
  final dynamic progression;
  final List<Part>? parts;
  final int? intensity;
  final String? intensityUnit;
  final int? restBetweenRounds;
  final List<int>? repScheme;
  final List<String>? movements;
  final List<Ladder>? ladder;

  Block({
    this.blockLetter,
    this.format,
    this.volume,
    this.unit,
    this.exercises,
    this.progression,
    this.parts,
    this.intensity,
    this.intensityUnit,
    this.restBetweenRounds,
    this.repScheme,
    this.movements,
    this.ladder,
  });

  factory Block.fromJson(Map<String, dynamic> json) {
    dynamic prog = json["progression"];
    List<ProgressionElement>? progressionList;
    if (prog != null && prog is List) {
      progressionList = prog
          .map((x) => ProgressionElement.fromJson(
              Map<String, dynamic>.from(x as Map)))
          .toList();
    }

    return Block(
      blockLetter: _blockLetterFromJson(json["blockLetter"]),
      format: json["format"] as String?,
      volume: json["volume"] as int?,
      unit: _unitFromJson(json["unit"]),
      exercises: json["exercises"] == null
          ? null
          : List<BlockExercise>.from((json["exercises"] as List)
              .map((x) => BlockExercise.fromJson(x))),
      progression: progressionList ?? json["progression"],
      parts: json["parts"] == null
          ? null
          : List<Part>.from(
              (json["parts"] as List).map((x) => Part.fromJson(x))),
      intensity: json["intensity"] as int?,
      intensityUnit: json["intensityUnit"] as String?,
      restBetweenRounds: json["restBetweenRounds"] as int?,
      repScheme: json["repScheme"] == null
          ? null
          : List<int>.from((json["repScheme"] as List).map((x) => x as int)),
      movements: json["movements"] == null
          ? null
          : List<String>.from((json["movements"] as List).map((x) => x.toString())),
      ladder: json["ladder"] == null
          ? null
          : List<Ladder>.from(
              (json["ladder"] as List).map((x) => Ladder.fromJson(x))),
    );
  }
}

enum BlockLetter { A, B, C }

final blockLetterValues = EnumValues({
  "A": BlockLetter.A,
  "B": BlockLetter.B,
  "C": BlockLetter.C,
});

class BlockExercise {
  final String? movement;
  final String? interval;
  final dynamic volume;
  final Unit? unit;
  final int? sets;
  final String? notes;
  final String? type;
  final List<MovementElement>? movements;
  final dynamic intensity;
  final String? intensityUnit;
  final int? volumePerLeg;
  final int? weight;
  final String? weightUnit;

  BlockExercise({
    this.movement,
    this.interval,
    this.volume,
    this.unit,
    this.sets,
    this.notes,
    this.type,
    this.movements,
    this.intensity,
    this.intensityUnit,
    this.volumePerLeg,
    this.weight,
    this.weightUnit,
  });

  factory BlockExercise.fromJson(Map<String, dynamic> json) => BlockExercise(
        movement: json["movement"] as String?,
        interval: json["interval"] as String?,
        volume: json["volume"],
        unit: _unitFromJson(json["unit"]),
        sets: json["sets"] as int?,
        notes: json["notes"] as String?,
        type: json["type"] as String?,
        movements: json["movements"] == null
            ? null
            : List<MovementElement>.from((json["movements"] as List)
                .map((x) => MovementElement.fromJson(x))),
        intensity: json["intensity"],
        intensityUnit: json["intensityUnit"] as String?,
        volumePerLeg: json["volumePerLeg"] as int?,
        weight: json["weight"] as int?,
        weightUnit: json["weightUnit"] as String?,
      );
}

class MovementElement {
  final String movement;
  final int? volume;
  final Unit? unit;

  MovementElement({
    required this.movement,
    this.volume,
    this.unit,
  });

  factory MovementElement.fromJson(Map<String, dynamic> json) =>
      MovementElement(
        movement: json["movement"] as String? ?? "",
        volume: json["volume"] as int?,
        unit: _unitFromJson(json["unit"]),
      );
}

enum Unit {
  CAL,
  LINES,
  M,
  MIN,
  REPS,
  RM,
  ROUNDS,
  SEC,
}

final unitValues = EnumValues({
  "cal": Unit.CAL,
  "lines": Unit.LINES,
  "m": Unit.M,
  "min": Unit.MIN,
  "reps": Unit.REPS,
  "RM": Unit.RM,
  "rounds": Unit.ROUNDS,
  "sec": Unit.SEC,
});

class Ladder {
  final int volume;
  final Unit? unit;
  final num weight;
  final String weightUnit;

  Ladder({
    required this.volume,
    this.unit,
    required this.weight,
    required this.weightUnit,
  });

  factory Ladder.fromJson(Map<String, dynamic> json) => Ladder(
        volume: json["volume"] as int? ?? 0,
        unit: _unitFromJson(json["unit"]),
        weight: _numFromJson(json["weight"]),
        weightUnit: json["weightUnit"] as String? ?? "",
      );
}

class Part {
  final String? format;
  final int? volume;
  final Unit? unit;
  final List<PartExercise>? exercises;
  final String? movement;
  final List<int>? repScheme;
  final int? intervalDuration;
  final Unit? intervalUnit;
  final int? totalRounds;
  final int? sets;
  final String? tempo;
  final dynamic intensity;
  final String? intensityUnit;

  Part({
    this.format,
    this.volume,
    this.unit,
    this.exercises,
    this.movement,
    this.repScheme,
    this.intervalDuration,
    this.intervalUnit,
    this.totalRounds,
    this.sets,
    this.tempo,
    this.intensity,
    this.intensityUnit,
  });

  factory Part.fromJson(Map<String, dynamic> json) => Part(
        format: json["format"] as String?,
        volume: json["volume"] as int?,
        unit: _unitFromJson(json["unit"]),
        exercises: json["exercises"] == null
            ? null
            : List<PartExercise>.from((json["exercises"] as List)
                .map((x) => PartExercise.fromJson(x))),
        movement: json["movement"] as String?,
        repScheme: json["repScheme"] == null
            ? null
            : List<int>.from((json["repScheme"] as List).map((x) => x as int)),
        intervalDuration: json["intervalDuration"] as int?,
        intervalUnit: _unitFromJson(json["intervalUnit"]),
        totalRounds: json["totalRounds"] as int?,
        sets: json["sets"] as int?,
        tempo: json["tempo"] as String?,
        intensity: json["intensity"],
        intensityUnit: json["intensityUnit"] as String?,
      );
}

class PartExercise {
  final String? movement;
  final int? volume;
  final String? unit;
  final int? distancePerLine;
  final int? intensity;
  final String? intensityUnit;
  final String? notes;
  final int? weight;
  final String? weightUnit;

  PartExercise({
    this.movement,
    this.volume,
    this.unit,
    this.distancePerLine,
    this.intensity,
    this.intensityUnit,
    this.notes,
    this.weight,
    this.weightUnit,
  });

  factory PartExercise.fromJson(Map<String, dynamic> json) => PartExercise(
        movement: json["movement"] as String?,
        volume: json["volume"] as int?,
        unit: json["unit"] as String?,
        distancePerLine: json["distancePerLine"] as int?,
        intensity: json["intensity"] as int?,
        intensityUnit: json["intensityUnit"] as String?,
        notes: json["notes"] as String?,
        weight: json["weight"] as int?,
        weightUnit: json["weightUnit"] as String?,
      );
}

class ProgressionElement {
  final String minutes;
  final int volume;
  final Unit? unit;
  final int intensity;
  final String intensityUnit;

  ProgressionElement({
    required this.minutes,
    required this.volume,
    this.unit,
    required this.intensity,
    required this.intensityUnit,
  });

  factory ProgressionElement.fromJson(Map<String, dynamic> json) =>
      ProgressionElement(
        minutes: json["minutes"] as String? ?? "",
        volume: json["volume"] as int? ?? 0,
        unit: _unitFromJson(json["unit"]),
        intensity: json["intensity"] as int? ?? 0,
        intensityUnit: json["intensityUnit"] as String? ?? "",
      );
}

class WarmUp {
  final String? movement;
  final int? volume;
  final Unit? unit;
  final String? format;
  final List<MovementElement>? exercises;
  final String? equipment;

  WarmUp({
    this.movement,
    this.volume,
    this.unit,
    this.format,
    this.exercises,
    this.equipment,
  });

  factory WarmUp.fromJson(Map<String, dynamic> json) {
    List<MovementElement>? exercisesList;
    if (json["exercises"] != null && json["exercises"] is List) {
      exercisesList = (json["exercises"] as List)
          .map((x) => MovementElement.fromJson(Map<String, dynamic>.from(x as Map)))
          .toList();
    }
    return WarmUp(
      movement: json["movement"] as String?,
      volume: json["volume"] as int?,
      unit: _unitFromJson(json["unit"]),
      format: json["format"] as String?,
      exercises: exercisesList,
      equipment: json["equipment"] as String?,
    );
  }
}

class EnumValues<T> {
  final Map<String, T> map;

  EnumValues(this.map);
}
