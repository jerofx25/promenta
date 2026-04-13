import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:insta_assets_picker/insta_assets_picker.dart';

/// Texto del selector de fotos en español (mismo que en onboarding).
class SpanishAssetPickerTextDelegate extends EnglishAssetPickerTextDelegate {
  const SpanishAssetPickerTextDelegate();

  @override
  String get confirm => 'Confirmar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get goToSystemSettings => 'Ir a configuración';

  @override
  String get accessLimitedAssets => 'Continuar con acceso limitado';

  @override
  String get unableToAccessAll =>
      'No se puede acceder a todos los archivos. Ve a configuración del sistema.';
}

/// Abre el mismo selector de imagen que en onboarding.
/// Devuelve el archivo recortado o [null] si se cancela o hay error.
Future<File?> pickProfilePhoto(BuildContext context) async {
  final completer = Completer<File?>();
  try {
    await InstaAssetPicker.pickAssets(
      context,
      maxAssets: 1,
      pickerConfig: InstaAssetPickerConfig(
        textDelegate: const SpanishAssetPickerTextDelegate(),
        closeOnComplete: true,
      ),
      onCompleted: (Stream<InstaAssetsExportDetails> exportDetails) {
        exportDetails.listen(
          (details) {
            if (details.data.isNotEmpty &&
                details.data.first.croppedFile != null) {
              final file = details.data.first.croppedFile!;
              if (!completer.isCompleted) {
                // Diferir para que el picker termine de cerrar antes de resolver.
                scheduleMicrotask(() {
                  if (!completer.isCompleted) {
                    completer.complete(file);
                  }
                });
              }
            }
          },
          onDone: () {
            if (!completer.isCompleted) {
              scheduleMicrotask(() {
                if (!completer.isCompleted) completer.complete(null);
              });
            }
          },
          onError: (Object e, StackTrace st) {
            debugPrint('Photo picker stream error: $e $st');
            if (!completer.isCompleted) completer.completeError(e, st);
          },
        );
      },
    );
    // No completar aquí con null: el stream puede emitir después de que
    // se cierre el picker (recorte asíncrono). Si el usuario canceló,
    // onCompleted no se llama y el timeout devolverá null.
    return completer.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        if (!completer.isCompleted) completer.complete(null);
        return null;
      },
    );
  } catch (e) {
    debugPrint('Photo picker error: $e');
    rethrow;
  }
}
