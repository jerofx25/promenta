import 'dart:convert';
import 'dart:async';

import 'package:IAEntrenar/features/ai_coach/application/daily_coach_state.dart';
import 'package:IAEntrenar/features/ai_coach/domain/daily_coach_input.dart';
import 'package:IAEntrenar/features/ai_coach/domain/daily_coach_result.dart';
import 'package:IAEntrenar/features/ai_coach/infrastructure/local_llm_coach_service.dart';
import 'package:IAEntrenar/models/user_profile.dart';
import 'package:IAEntrenar/models/workup_day.dart';
import 'package:IAEntrenar/services/apple_health_service.dart';
import 'package:bloc/bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DailyCoachCubit extends Cubit<DailyCoachState> {
  DailyCoachCubit({
    required LocalLlmCoachService service,
  })  : _service = service,
        super(const DailyCoachState.initial());

  final LocalLlmCoachService _service;
  StreamSubscription? _downloadSub;

  static String _todayKey({
    required String userId,
    required int dayNumber,
    required DateTime now,
  }) {
    final d = DateTime(now.year, now.month, now.day);
    return 'daily_coach_v2:$userId:${d.toIso8601String()}:$dayNumber';
  }

  bool _isGeneratingForKey(String key) {
    return state.cacheKey == key &&
        (state.status == DailyCoachStatus.downloadingModel ||
            state.status == DailyCoachStatus.generating);
  }

  Future<void> loadCached({
    required UserProfile profile,
    required WorkupDay day,
    required DateTime now,
  }) async {
    final key =
        _todayKey(userId: profile.id, dayNumber: day.dayNumber, now: now);
    if (isClosed) return;

    // If this day is already loaded or in progress, keep the visible state.
    if ((state.cacheKey == key && state.status == DailyCoachStatus.ready) ||
        _isGeneratingForKey(key)) {
      return;
    }

    emit(state.copyWith(cacheKey: key, error: null));

    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(key);
    if (cached == null || cached.isEmpty) {
      if (isClosed) return;
      // Keep it idle; user can generate manually.
      emit(state.copyWith(status: DailyCoachStatus.idle, clearResult: true));
      return;
    }

    try {
      final decoded = jsonDecode(cached) as Map<String, dynamic>;
      final result = DailyCoachResult(
        headline: (decoded['headline'] ?? '').toString(),
        tips: (decoded['tips'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList(),
        caution: (decoded['caution'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList(),
        rawText: (decoded['rawText'] ?? '').toString(),
      );
      if (isClosed) return;
      emit(state.copyWith(status: DailyCoachStatus.ready, result: result));
    } catch (_) {
      if (!isClosed) {
        emit(state.copyWith(status: DailyCoachStatus.idle, clearResult: true));
      }
    }
  }

  Future<void> loadOrGenerate({
    required UserProfile profile,
    required WorkupDay day,
    required DateTime now,
    bool forceRefresh = false,
  }) async {
    final key =
        _todayKey(userId: profile.id, dayNumber: day.dayNumber, now: now);
    if (isClosed) return;
    if (_isGeneratingForKey(key)) return;

    emit(state.copyWith(cacheKey: key, error: null));

    final prefs = await SharedPreferences.getInstance();
    if (!forceRefresh) {
      final cached = prefs.getString(key);
      if (cached != null && cached.isNotEmpty) {
        try {
          final decoded = jsonDecode(cached) as Map<String, dynamic>;
          final result = DailyCoachResult(
            headline: (decoded['headline'] ?? '').toString(),
            tips: (decoded['tips'] as List<dynamic>? ?? [])
                .map((e) => e.toString())
                .toList(),
            caution: (decoded['caution'] as List<dynamic>? ?? [])
                .map((e) => e.toString())
                .toList(),
            rawText: (decoded['rawText'] ?? '').toString(),
          );
          if (isClosed) return;
          emit(state.copyWith(status: DailyCoachStatus.ready, result: result));
          return;
        } catch (_) {
          // If cache is corrupted, ignore and regenerate.
        }
      }
    }

    await _ensureModelDownloaded();
    if (isClosed) return;

    emit(state.copyWith(
        status: DailyCoachStatus.generating, downloadProgress: null));
    try {
      double? sleepHours;
      try {
        final health = AppleHealthService();
        if (await health.requestPermissions()) {
          sleepHours = await health.getSleepLastNightHours();
        }
      } catch (_) {}

      final input = DailyCoachInput.from(
          now: now, profile: profile, day: day, sleepHours: sleepHours);
      final result = await _service.generateDailyCoach(input);

      await prefs.setString(
          key,
          jsonEncode({
            'headline': result.headline,
            'tips': result.tips,
            'caution': result.caution,
            'rawText': result.rawText,
          }));

      if (isClosed) return;
      if (state.cacheKey != key) return;
      emit(state.copyWith(status: DailyCoachStatus.ready, result: result));
    } catch (e) {
      if (isClosed) return;
      if (state.cacheKey != key) return;
      emit(state.copyWith(status: DailyCoachStatus.error, error: e.toString()));
    }
  }

  Future<void> _ensureModelDownloaded() async {
    await _downloadSub?.cancel();
    _downloadSub = null;

    if (isClosed) return;
    emit(state.copyWith(
        status: DailyCoachStatus.downloadingModel, downloadProgress: 0.0));

    try {
      final completer = Completer<void>();
      _downloadSub = _service.downloadModelInBackground().listen(
        (p) {
          if (isClosed) return;
          final percent = p.percent;
          if (percent == null) return;
          emit(state.copyWith(
            status: DailyCoachStatus.downloadingModel,
            downloadProgress: percent,
          ));
        },
        onError: (e) {
          if (!completer.isCompleted) completer.completeError(e);
        },
        onDone: () {
          if (!completer.isCompleted) completer.complete();
        },
        cancelOnError: true,
      );
      await completer.future;
    } catch (e) {
      if (!isClosed) {
        emit(state.copyWith(
            status: DailyCoachStatus.error, error: e.toString()));
      }
      rethrow;
    }
  }

  @override
  Future<void> close() async {
    await _downloadSub?.cancel();
    _downloadSub = null;
    await _service.dispose();
    return super.close();
  }
}
