import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Colores por capacidad para el radar (Fuerza, Resistencia, Velocidad, Movilidad, Cardio).
/// Fuerza usa el morado de la app (#7B61FF).
const List<Color> _radarCapacityColors = [
  Color(0xFF7B61FF), // Fuerza - morado app
  Color(0xFF22C55E), // Resistencia - verde
  Color(0xFF3B82F6), // Velocidad - azul
  Color(0xFF8B5CF6), // Movilidad - violeta
  Color(0xFFEF4444), // Cardio - rojo
];

class FitnessRadarChart extends StatelessWidget {
  final Map<String, double> fitnessAttributes;
  final double maxValue;

  const FitnessRadarChart({
    super.key,
    required this.fitnessAttributes,
    this.maxValue = 10.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titles = fitnessAttributes.keys.toList();
    final values = fitnessAttributes.values.toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AspectRatio(
          aspectRatio: 1.2,
          child: RadarChart(
            RadarChartData(
              dataSets: _buildRadarDataSetsByCapacity(values),
              radarBackgroundColor: Colors.transparent,
              borderData: FlBorderData(show: false),
              radarBorderData: const BorderSide(color: Colors.transparent),
              titlePositionPercentageOffset: 0.2,
              tickCount: 5,
              ticksTextStyle: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
              gridBorderData: BorderSide(
                color: theme.colorScheme.onSurface.withOpacity(0.2),
                width: 1,
              ),
              getTitle: (index, angle) {
                return RadarChartTitle(
                  text: titles[index],
                  angle: angle,
                  positionPercentageOffset: 0.15,
                );
              },
              titleTextStyle: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.9),
                fontWeight: FontWeight.bold,
              ),
            ),
            swapAnimationDuration: const Duration(milliseconds: 500),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Wrap(
            spacing: 12,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: List.generate(titles.length, (i) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _radarCapacityColors[i % _radarCapacityColors.length],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    titles[i],
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.8),
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Escala 0–10: nivel según tus últimos registros por capacidad (normalizado a tu mejor marca).',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  /// Un data set por capacidad para que cada segmento tenga su color.
  List<RadarDataSet> _buildRadarDataSetsByCapacity(List<double> values) {
    return List.generate(values.length, (i) {
      final entries = List.generate(values.length, (j) {
        return RadarEntry(value: i == j ? values[j] : 0.0);
      });
      final color = _radarCapacityColors[i % _radarCapacityColors.length];
      return RadarDataSet(
        fillColor: color.withOpacity(0.35),
        borderColor: color,
        entryRadius: 3,
        dataEntries: entries,
        borderWidth: 2,
      );
    });
  }
}

/// Datos de ejemplo para el radar. Misma estructura que [GetNormalizedRadarData]:
/// Fuerza, Resistencia, Velocidad, Movilidad, Cardio (0–maxValue).
class FitnessRadarData {
  static Map<String, double> getSampleFitnessData() {
    return {
      'Fuerza': 7.5,
      'Resistencia': 6.2,
      'Velocidad': 6.5,
      'Movilidad': 5.8,
      'Cardio': 6.0,
    };
  }
}