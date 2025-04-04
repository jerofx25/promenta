import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import '../utils/theme.dart';

class FitnessRadarChart extends StatelessWidget {
  final Map<String, double> fitnessAttributes;
  final double maxValue;

  const FitnessRadarChart({
    Key? key,
    required this.fitnessAttributes,
    this.maxValue = 10.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Extract values and titles
    final titles = fitnessAttributes.keys.toList();
    final values = fitnessAttributes.values.toList();
    
    return AspectRatio(
      aspectRatio: 1.2,
      child: RadarChart(
        RadarChartData(
          dataSets: _buildRadarDataSets(values),
          radarBackgroundColor: Colors.transparent,
          borderData: FlBorderData(show: false),
          radarBorderData: const BorderSide(color: Colors.transparent),
          titlePositionPercentageOffset: 0.2,
          tickCount: 5,
          ticksTextStyle: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onBackground.withOpacity(0.5),
          ),
          gridBorderData: BorderSide(
            color: theme.colorScheme.onBackground.withOpacity(0.2),
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
            color: theme.colorScheme.onBackground.withOpacity(0.9),
            fontWeight: FontWeight.bold,
          ),
        ),
        swapAnimationDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  List<RadarDataSet> _buildRadarDataSets(List<double> values) {
    return [
      RadarDataSet(
        fillColor: AppTheme.moveRingColor.withOpacity(0.25),
        borderColor: AppTheme.moveRingColor,
        entryRadius: 3,
        dataEntries: _convertToEntries(values),
        borderWidth: 2.5,
      ),
    ];
  }

  List<RadarEntry> _convertToEntries(List<double> values) {
    return values.map((value) => RadarEntry(value: value)).toList();
  }
}

class FitnessRadarData {
  static Map<String, double> getSampleFitnessData() {
    return {
      'Fuerza': 7.5,
      'Resistencia': 6.2,
      'Movilidad': 5.8,
      'Velocidad': 6.5,
      'Equilibrio': 6.0,
    };
  }
}