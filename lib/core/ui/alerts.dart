import 'package:flutter/material.dart';
import 'package:alert_info/alert_info.dart';

class AppAlerts {
  static const Color _darkBackground = Color(0xFF1A1A1A); // Color de fondo oscuro de la imagen
  static const Color _lightText = Colors.white;

  /// Muestra una alerta de éxito (Success)
  static void showSuccess(BuildContext context, String message) {
    AlertInfo.show(
      context: context,
      text: message,
      typeInfo: TypeInfo.success,
      backgroundColor: _darkBackground,
      textColor: _lightText,
    );
  }

  /// Muestra una alerta de éxito abajo con duración en segundos (p. ej. perfil completado).
  static void showSuccessAtBottom(
    BuildContext context,
    String message, {
    int durationSeconds = 4,
  }) {
    AlertInfo.show(
      context: context,
      text: message,
      typeInfo: TypeInfo.success,
      position: MessagePosition.bottom,
      duration: durationSeconds,
      backgroundColor: _darkBackground,
      textColor: _lightText,
    );
  }

  /// Muestra una alerta de error (Error)
  static void showError(BuildContext context, String message) {
    AlertInfo.show(
      context: context,
      text: message,
      typeInfo: TypeInfo.error,
      backgroundColor: _darkBackground,
      textColor: _lightText,
    );
  }

  /// Muestra una alerta de error abajo (mismo estilo que éxito).
  static void showErrorAtBottom(
    BuildContext context,
    String message, {
    int durationSeconds = 4,
  }) {
    AlertInfo.show(
      context: context,
      text: message,
      typeInfo: TypeInfo.error,
      position: MessagePosition.bottom,
      duration: durationSeconds,
      backgroundColor: _darkBackground,
      textColor: _lightText,
    );
  }

  /// Muestra una alerta de advertencia (Warning)
  static void showWarning(BuildContext context, String message) {
    AlertInfo.show(
      context: context,
      text: message,
      typeInfo: TypeInfo.warning,
      backgroundColor: _darkBackground,
      textColor: _lightText,
    );
  }

  /// Muestra una alerta de información (Info)
  static void showInfo(BuildContext context, String message) {
    AlertInfo.show(
      context: context,
      text: message,
      typeInfo: TypeInfo.info,
      backgroundColor: _darkBackground,
      textColor: _lightText,
    );
  }
}
