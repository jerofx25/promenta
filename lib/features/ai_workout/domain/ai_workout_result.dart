import 'dart:convert';

import 'package:IAEntrenar/models/workup_day.dart';

class AiWorkoutResult {
  const AiWorkoutResult({
    required this.day,
    required this.rawText,
  });

  final WorkupDay day;
  final String rawText;

  static Map<String, dynamic>? tryParseJsonMap(String text) {
    final jsonStr = _extractJsonObject(text);
    if (jsonStr == null) return null;
    try {
      final decoded = jsonDecode(jsonStr);
      if (decoded is! Map<String, dynamic>) return null;
      return decoded;
    } catch (_) {
      return null;
    }
  }

  static WorkupDay? tryParseWorkupDay(String text) {
    try {
      final decoded = tryParseJsonMap(text);
      if (decoded == null) return null;
      return WorkupDay.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  static String? _extractJsonObject(String text) {
    final s = text.trim();
    final fence =
        RegExp(r'```(?:json)?\s*([\s\S]*?)\s*```', caseSensitive: false);
    final fenceMatch = fence.firstMatch(s);
    final candidate = fenceMatch != null ? (fenceMatch.group(1) ?? '') : s;
    final start = candidate.indexOf('{');
    if (start < 0) return null;
    final end = candidate.lastIndexOf('}');
    if (end <= start) return null;
    return candidate.substring(start, end + 1);
  }
}

