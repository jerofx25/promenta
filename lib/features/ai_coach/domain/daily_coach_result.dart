import 'dart:convert';

class DailyCoachResult {
  const DailyCoachResult({
    required this.headline,
    required this.tips,
    required this.caution,
    required this.rawText,
  });

  final String headline;
  final List<String> tips;
  final List<String> caution;
  final String rawText;

  static DailyCoachResult fallback({required String rawText}) {
    return DailyCoachResult(
      headline: 'Consejo rápido para hoy',
      tips: const [
        'Empieza con un calentamiento corto y enfocado.',
        'Mantén la técnica limpia antes de subir intensidad.',
        'Hidrátate y descansa lo suficiente entre series.',
      ],
      caution: const [],
      rawText: rawText,
    );
  }

  static DailyCoachResult fromModelText(String text) {
    // We expect JSON, but we must be tolerant:
    // - model may wrap JSON in markdown fences
    // - model may include extra text before/after
    final cleaned = _extractJsonObject(text) ?? text.trim();
    try {
      final decoded = jsonDecode(cleaned);
      if (decoded is! Map<String, dynamic>) {
        return fallback(rawText: text);
      }
      final headline = (decoded['headline'] ?? '').toString().trim();
      final tips = _stringList(decoded['tips']);
      final caution = _stringList(decoded['caution']);

      if (headline.isEmpty || tips.isEmpty) {
        return fallback(rawText: text);
      }
      return DailyCoachResult(
        headline: headline,
        tips: tips,
        caution: caution,
        rawText: text,
      );
    } catch (_) {
      return fallback(rawText: text);
    }
  }

  static List<String> _stringList(dynamic v) {
    if (v is List) {
      return v.map((e) => e.toString().trim()).where((s) => s.isNotEmpty).toList();
    }
    return const [];
  }

  static String? _extractJsonObject(String text) {
    final s = text.trim();
    // Strip markdown fences if present
    final fence = RegExp(r'```(?:json)?\s*([\s\S]*?)\s*```', caseSensitive: false);
    final fenceMatch = fence.firstMatch(s);
    final candidate = fenceMatch != null ? fenceMatch.group(1) ?? '' : s;

    final start = candidate.indexOf('{');
    if (start < 0) return null;
    final end = candidate.lastIndexOf('}');
    if (end <= start) return null;
    return candidate.substring(start, end + 1);
  }
}

