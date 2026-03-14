import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class WorkoutStackedColumnChart extends StatelessWidget {
  final List<StackedWorkoutData> workoutData;
  final Color cardioColor;
  final Color strengthColor;
  final Color flexibilityColor;

  const WorkoutStackedColumnChart({
    super.key,
    required this.workoutData,
    this.cardioColor = const Color(0xFFE91E63),
    this.strengthColor = const Color(0xFF9C27B0),
    this.flexibilityColor = const Color(0xFF00BCD4),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurface.withOpacity(0.6),
      fontWeight: FontWeight.normal,
    );

    return AspectRatio(
      aspectRatio: 2.50,
      child: Padding(
        padding: const EdgeInsets.only(top: 16),
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    if (value % 20 == 0 || value == meta.max) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Text(
                          value == value.roundToDouble()
                              ? '${value.toInt()}'
                              : value.toStringAsFixed(0),
                          style: titleStyle,
                        ),
                      );
                    }
                    return const SizedBox();
                  },
                  reservedSize: 36,
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    if (value.toInt() >= 0 &&
                        value.toInt() < workoutData.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          workoutData[value.toInt()].xLabel,
                          style: titleStyle,
                        ),
                      );
                    }
                    return const SizedBox();
                  },
                  reservedSize: 30,
                ),
              ),
              rightTitles: const AxisTitles(),
              topTitles: const AxisTitles(),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (value) => FlLine(
                color: theme.colorScheme.onSurface.withOpacity(0.1),
                strokeWidth: 1,
                dashArray: [5, 5],
              ),
            ),
            borderData: FlBorderData(show: false),
            barGroups: _buildBarGroups(),
            // Set max Y value as 110% of highest value for better visualization
            maxY: _calculateMaxY() * 1.1,
          ),
          swapAnimationDuration: const Duration(milliseconds: 700),
        ),
      ),
    );
  }

  double _calculateMaxY() {
    double maxSum = 0;
    for (var data in workoutData) {
      final sum = data.values.reduce((a, b) => a + b);
      if (sum > maxSum) maxSum = sum;
    }
    return maxSum;
  }

  List<BarChartGroupData> _buildBarGroups() {
    return workoutData.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;

      final cardioRod = BarChartRodData(
        toY: data.values[0],
        color: cardioColor,
        width: 12,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(4),
          topRight: Radius.circular(4),
        ),
      );

      final strengthRod = BarChartRodData(
        toY: data.values[1],
        color: strengthColor,
        width: 12,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(4),
          topRight: Radius.circular(4),
        ),
      );

      final flexibilityRod = BarChartRodData(
        toY: data.values[2],
        color: flexibilityColor,
        width: 12,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(4),
          topRight: Radius.circular(4),
        ),
      );

      return BarChartGroupData(
        x: index,
        groupVertically: true,
        barRods: [cardioRod, strengthRod, flexibilityRod],
        barsSpace: 4,
      );
    }).toList();
  }
}

class StackedWorkoutData {
  final String xLabel; // e.g. day of week, month, etc.
  final List<double> values; // [cardio, strength, flexibility]

  const StackedWorkoutData({
    required this.xLabel,
    required this.values,
  });
}

class SampleWorkoutData {
  static List<StackedWorkoutData> getWeeklyData() {
    return [
      const StackedWorkoutData(xLabel: 'L', values: [20, 15, 10]),
      const StackedWorkoutData(xLabel: 'M', values: [15, 25, 5]),
      const StackedWorkoutData(xLabel: 'X', values: [25, 10, 15]),
      const StackedWorkoutData(xLabel: 'J', values: [10, 20, 5]),
      const StackedWorkoutData(xLabel: 'V', values: [30, 10, 10]),
      const StackedWorkoutData(xLabel: 'S', values: [15, 15, 20]),
      const StackedWorkoutData(xLabel: 'D', values: [5, 5, 10]),
    ];
  }

  static List<StackedWorkoutData> getMonthlyData() {
    return [
      const StackedWorkoutData(xLabel: 'S1', values: [90, 70, 40]),
      const StackedWorkoutData(xLabel: 'S2', values: [75, 90, 30]),
      const StackedWorkoutData(xLabel: 'S3', values: [85, 60, 50]),
      const StackedWorkoutData(xLabel: 'S4', values: [70, 80, 45]),
    ];
  }
}
