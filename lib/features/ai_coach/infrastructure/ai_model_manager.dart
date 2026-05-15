import 'dart:async';
import 'dart:io';

import 'package:IAEntrenar/features/ai_coach/infrastructure/model_downloader.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AiModelDownloadStatus {
  unknown,
  notDownloaded,
  downloading,
  downloaded,
  error,
}

class AiModelDownloadState {
  const AiModelDownloadState({
    required this.status,
    this.progress,
    this.modelPath,
    this.error,
  });

  final AiModelDownloadStatus status;
  final double? progress;
  final String? modelPath;
  final String? error;

  bool get isDownloading => status == AiModelDownloadStatus.downloading;
  bool get isDownloaded => status == AiModelDownloadStatus.downloaded;

  AiModelDownloadState copyWith({
    AiModelDownloadStatus? status,
    double? progress,
    String? modelPath,
    String? error,
  }) {
    return AiModelDownloadState(
      status: status ?? this.status,
      progress: progress ?? this.progress,
      modelPath: modelPath ?? this.modelPath,
      error: error,
    );
  }
}

/// Singleton que mantiene una sola descarga "en vuelo" por ejecución de la app.
/// Así, si el usuario sale/entra de la pantalla, no se reinicia la descarga.
class AiModelManager {
  AiModelManager._();

  static final AiModelManager instance = AiModelManager._();

  static const _prefsModelPathKey = 'ai_coach_model_path_v2';
  static const _prefsModelUrlKey = 'ai_coach_model_url_v2';

  // Modelo más liviano que Q4_K_M para bajar más rápido.
  // Qwen2.5 0.5B Instruct GGUF - Q3_K_M.
  static final Uri modelUrl = Uri.parse(
    'https://huggingface.co/Qwen/Qwen2.5-0.5B-Instruct-GGUF/resolve/main/qwen2.5-0.5b-instruct-q3_k_m.gguf',
  );

  static const String modelFileName = 'qwen2.5-0.5b-instruct-q3_k_m.gguf';

  final ModelDownloader _downloader = ModelDownloader();
  final StreamController<AiModelDownloadState> _stateController =
      StreamController<AiModelDownloadState>.broadcast();

  AiModelDownloadState _state = const AiModelDownloadState(
    status: AiModelDownloadStatus.unknown,
  );

  Stream<AiModelDownloadState> get stateStream => _stateController.stream;

  AiModelDownloadState get currentState => _state;

  void _emitState(AiModelDownloadState state) {
    _state = state;
    if (!_stateController.isClosed) {
      _stateController.add(state);
    }
  }

  Future<String?> getExistingModelPath() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsModelPathKey);
    if (saved == null || saved.isEmpty) return null;
    if (!await File(saved).exists()) return null;
    return saved;
  }

  Future<File> _targetFile() async {
    final dir = await getApplicationDocumentsDirectory();
    final modelsDir = Directory('${dir.path}/models');
    return File('${modelsDir.path}/$modelFileName');
  }

  StreamController<DownloadProgress>? _downloadController;
  Future<void>? _downloadFuture;

  Future<AiModelDownloadState> refreshState() async {
    final existing = await getExistingModelPath();
    if (existing != null) {
      final state = AiModelDownloadState(
        status: AiModelDownloadStatus.downloaded,
        progress: 1.0,
        modelPath: existing,
      );
      _emitState(state);
      return state;
    }

    if (_downloadFuture != null) {
      final state = _state.status == AiModelDownloadStatus.downloading
          ? _state
          : const AiModelDownloadState(
              status: AiModelDownloadStatus.downloading,
              progress: 0.0,
            );
      _emitState(state);
      return state;
    }

    const state = AiModelDownloadState(
      status: AiModelDownloadStatus.notDownloaded,
    );
    _emitState(state);
    return state;
  }

  /// Asegura que el modelo esté descargado. Devuelve un stream de progreso
  /// (broadcast) para suscribirse desde UI.
  Stream<DownloadProgress> ensureDownloaded() {
    final existingController = _downloadController;
    if (existingController != null && !existingController.isClosed) {
      return existingController.stream;
    }

    final controller = StreamController<DownloadProgress>.broadcast();
    _downloadController = controller;
    _emitState(const AiModelDownloadState(
      status: AiModelDownloadStatus.downloading,
      progress: 0.0,
    ));

    _downloadFuture = () async {
      try {
        final alreadyPath = await getExistingModelPath();
        if (alreadyPath != null) {
          _emitState(AiModelDownloadState(
            status: AiModelDownloadStatus.downloaded,
            progress: 1.0,
            modelPath: alreadyPath,
          ));
          await controller.close();
          return;
        }

        final outputFile = await _targetFile();
        if (await outputFile.exists()) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_prefsModelPathKey, outputFile.path);
          await prefs.setString(_prefsModelUrlKey, modelUrl.toString());
          _emitState(AiModelDownloadState(
            status: AiModelDownloadStatus.downloaded,
            progress: 1.0,
            modelPath: outputFile.path,
          ));
          await controller.close();
          return;
        }

        await _downloader.downloadToFile(
          url: modelUrl,
          outputFile: outputFile,
          onProgress: (progress) {
            controller.add(progress);
            _emitState(AiModelDownloadState(
              status: AiModelDownloadStatus.downloading,
              progress: progress.percent,
            ));
          },
        );

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_prefsModelPathKey, outputFile.path);
        await prefs.setString(_prefsModelUrlKey, modelUrl.toString());
        _emitState(AiModelDownloadState(
          status: AiModelDownloadStatus.downloaded,
          progress: 1.0,
          modelPath: outputFile.path,
        ));
        await controller.close();
      } catch (e) {
        _emitState(AiModelDownloadState(
          status: AiModelDownloadStatus.error,
          error: e.toString(),
        ));
        if (!controller.isClosed) {
          controller.addError(e);
          await controller.close();
        }
      } finally {
        _downloadController = null;
        _downloadFuture = null;
      }
    }();

    return controller.stream;
  }

  /// Espera a que la descarga termine (si hay una en curso) y retorna la ruta.
  Future<String> getOrDownloadModelPath() async {
    final existing = await getExistingModelPath();
    if (existing != null) return existing;

    // Inicia o reutiliza descarga actual.
    ensureDownloaded();
    await (_downloadFuture ?? Future.value());

    final path = await getExistingModelPath();
    if (path == null) {
      throw StateError('No se pudo obtener el modelo local.');
    }
    return path;
  }
}
