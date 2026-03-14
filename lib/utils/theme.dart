import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Paleta de colores
class AppColors {
  /// Fondo principal (oscuro)
  static const Color background = Color.fromARGB(255, 24, 26, 32); // #181A20

  /// Fondo para tarjetas o secciones
  static const Color cardBackground =
      Color.fromARGB(255, 31, 33, 40); // #1F2128

  /// Texto principal (blanco)
  static const Color primaryText =
      Color.fromARGB(255, 255, 255, 255); // #FFFFFF

  /// Texto secundario (gris claro)
  static const Color secondaryText =
      Color.fromARGB(255, 156, 163, 175); // #9CA3AF

  /// Acento morado (por ejemplo, para botones o indicadores de movimiento)
  static const Color accentPurple =
      Color.fromARGB(255, 123, 97, 255); // #7B61FF

  /// Acento rosa (para destacar información secundaria)
  static const Color accentPink = Color.fromARGB(255, 225, 78, 202); // #E14ECA

  /// Acento naranja (ideal para alertas o indicadores de calorías)
  static const Color accentOrange =
      Color.fromARGB(255, 245, 158, 11); // #F59E0B

  /// Acento azul (para secciones de "stand" o indicadores de actividad)
  static const Color accentBlue = Color.fromARGB(255, 66, 165, 245); // #42A5F5

  /// Acento verde/teal (ideal para datos de ejercicio, por ejemplo)
  static const Color accentTeal = Color.fromARGB(255, 35, 213, 171); // #23D5AB
}

/// Tema de la aplicación
class AppTheme {
  // Asignamos los colores de anillos según nuestra paleta:
  // - Movimiento: morado
  // - Ejercicio: verde/teal
  // - De pie: azul
  static const Color moveRingColor = AppColors.accentPurple;
  static const Color exerciseRingColor = AppColors.accentTeal;
  static const Color standRingColor = AppColors.accentBlue;

  static ThemeData lightTheme() {
    const ColorScheme colorScheme = ColorScheme.light(
      primary: AppColors.accentPurple,
      onPrimary: AppColors.primaryText,
      secondary: AppColors.accentPink,
      onSecondary: AppColors.primaryText,
      tertiary: AppColors.accentOrange,
      onTertiary: AppColors.primaryText,
      surface: AppColors.cardBackground,
      onSurface: AppColors.primaryText,
      error: Color(0xFFFF2D55), // Rojo de error
      onError: AppColors.primaryText,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: colorScheme.primary),
        titleTextStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          fontSize: 18,
          color: colorScheme.onSurface,
        ),
      ),
      textTheme: GoogleFonts.poppinsTextTheme().copyWith(
        displayLarge: GoogleFonts.poppins(
          fontWeight: FontWeight.bold,
          fontSize: 32,
          color: colorScheme.onSurface,
        ),
        displayMedium: GoogleFonts.poppins(
          fontWeight: FontWeight.bold,
          fontSize: 28,
          color: colorScheme.onSurface,
        ),
        displaySmall: GoogleFonts.poppins(
          fontWeight: FontWeight.bold,
          fontSize: 24,
          color: colorScheme.onSurface,
        ),
        headlineMedium: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          fontSize: 22,
          color: colorScheme.onSurface,
        ),
        titleLarge: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          fontSize: 20,
          color: colorScheme.onSurface,
        ),
        titleMedium: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          fontSize: 16,
          color: colorScheme.onSurface,
        ),
        bodyLarge: GoogleFonts.poppins(
          fontSize: 16,
          color: colorScheme.onSurface,
        ),
        bodyMedium: GoogleFonts.poppins(
          fontSize: 14,
          color: colorScheme.onSurface,
        ),
        bodySmall: GoogleFonts.poppins(
          fontSize: 12,
          color: colorScheme.onSurface.withOpacity(0.7),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: colorScheme.surface,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          textStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          textStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
          side: BorderSide(color: colorScheme.primary, width: 1.5),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          textStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: colorScheme.onSurface.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.error, width: 1.5),
        ),
        contentPadding: const EdgeInsets.all(16),
        hintStyle: GoogleFonts.poppins(
          fontSize: 14,
          color: colorScheme.onSurface.withOpacity(0.5),
        ),
        labelStyle: GoogleFonts.poppins(
          fontSize: 14,
          color: colorScheme.onSurface.withOpacity(0.7),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        circularTrackColor: colorScheme.primary.withOpacity(0.1),
        linearTrackColor: colorScheme.primary.withOpacity(0.1),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.primary.withOpacity(0.1),
        labelStyle: GoogleFonts.poppins(
          fontSize: 14,
          color: colorScheme.primary,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      iconTheme: IconThemeData(
        color: colorScheme.onSurface,
        size: 24,
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.onSurface.withOpacity(0.1),
        thickness: 1,
        space: 24,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: colorScheme.primary,
        unselectedLabelColor: colorScheme.onSurface.withOpacity(0.6),
        labelStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        indicator: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: colorScheme.primary, width: 2),
          ),
        ),
      ),
    );
  }

  static ThemeData darkTheme() {
    const ColorScheme colorScheme = ColorScheme.dark(
      primary: AppColors.accentPurple,
      onPrimary: AppColors.primaryText,
      secondary: AppColors.accentPink,
      onSecondary: AppColors.primaryText,
      tertiary: AppColors.accentOrange,
      onTertiary: AppColors.primaryText,
      surface: AppColors.cardBackground,
      onSurface: AppColors.primaryText,
      error: Color(0xFFFF2D55),
      onError: AppColors.primaryText,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: colorScheme.primary),
        titleTextStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          fontSize: 18,
          color: colorScheme.onSurface,
        ),
      ),
      textTheme: GoogleFonts.poppinsTextTheme().copyWith(
        displayLarge: GoogleFonts.poppins(
          fontWeight: FontWeight.bold,
          fontSize: 32,
          color: colorScheme.onSurface,
        ),
        displayMedium: GoogleFonts.poppins(
          fontWeight: FontWeight.bold,
          fontSize: 28,
          color: colorScheme.onSurface,
        ),
        displaySmall: GoogleFonts.poppins(
          fontWeight: FontWeight.bold,
          fontSize: 24,
          color: colorScheme.onSurface,
        ),
        headlineMedium: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          fontSize: 22,
          color: colorScheme.onSurface,
        ),
        titleLarge: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          fontSize: 20,
          color: colorScheme.onSurface,
        ),
        titleMedium: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          fontSize: 16,
          color: colorScheme.onSurface,
        ),
        bodyLarge: GoogleFonts.poppins(
          fontSize: 16,
          color: colorScheme.onSurface,
        ),
        bodyMedium: GoogleFonts.poppins(
          fontSize: 14,
          color: colorScheme.onSurface,
        ),
        bodySmall: GoogleFonts.poppins(
          fontSize: 12,
          color: colorScheme.onSurface.withOpacity(0.7),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: colorScheme.surface,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          textStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          textStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
          side: BorderSide(color: colorScheme.primary, width: 1.5),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          textStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: colorScheme.onSurface.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.error, width: 1.5),
        ),
        contentPadding: const EdgeInsets.all(16),
        hintStyle: GoogleFonts.poppins(
          fontSize: 14,
          color: colorScheme.onSurface.withOpacity(0.5),
        ),
        labelStyle: GoogleFonts.poppins(
          fontSize: 14,
          color: colorScheme.onSurface.withOpacity(0.7),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        circularTrackColor: colorScheme.primary.withOpacity(0.1),
        linearTrackColor: colorScheme.primary.withOpacity(0.1),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.primary.withOpacity(0.1),
        labelStyle: GoogleFonts.poppins(
          fontSize: 14,
          color: colorScheme.primary,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      iconTheme: IconThemeData(
        color: colorScheme.onSurface,
        size: 24,
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.onSurface.withOpacity(0.1),
        thickness: 1,
        space: 24,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: colorScheme.primary,
        unselectedLabelColor: colorScheme.onSurface.withOpacity(0.6),
        labelStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        indicator: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: colorScheme.primary, width: 2),
          ),
        ),
      ),
    );
  }
}
