import 'package:flutter/material.dart';
import 'package:mrx_charts/mrx_charts.dart';
import '../utils/theme.dart';

class ProgressPieChart extends StatelessWidget {
  final double progress;
  final double total;
  final Color color;
  final Widget? centerWidget;
  final String? title;
  final double size;
  
  const ProgressPieChart({
    Key? key,
    required this.progress,
    required this.total,
    required this.color,
    this.centerWidget,
    this.title,
    this.size = 120,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percentage = (progress / total).clamp(0.0, 1.0);
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (title != null) ...[  // Fixed bracket syntax
          Text(
            title!,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onBackground.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 8),
        ],
        SizedBox(
          width: size,
          height: size,
          child: Stack(
            children: [
              // Custom painted pie chart since MRX Charts isn't working as expected
              CustomPaint(
                size: Size(size, size),
                painter: CircularProgressPainter(
                  backgroundColor: theme.colorScheme.onBackground.withOpacity(0.1),
                  valueColor: color,
                  value: percentage,
                  strokeWidth: 16,
                ),
              ),
              
              // Center Content Widget
              if (centerWidget != null)
                Center(child: centerWidget!),
            ],
          ),
        ),
      ],
    );
  }
}

class RecoveryScoreWidget extends StatelessWidget {
  final double score;
  final double maxScore;
  final double size;
  
  const RecoveryScoreWidget({
    Key? key,
    required this.score,
    this.maxScore = 100.0,
    this.size = 120.0,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percentage = score / maxScore;
    
    // Determine color based on score
    final Color progressColor;
    if (percentage >= 0.7) {
      progressColor = AppTheme.exerciseRingColor;
    } else if (percentage >= 0.5) {
      progressColor = Colors.orange;
    } else {
      progressColor = AppTheme.moveRingColor;
    }
    
    return ProgressPieChart(
      progress: score,
      total: maxScore,
      color: progressColor,
      size: size,
      title: 'Recuperaciόn',
      centerWidget: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            score.toInt().toString(),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onBackground,
            ),
          ),
          Text(
            '/100',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onBackground.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class ActivityRingPieChart extends StatelessWidget {
  final String title;
  final double current;
  final double target;
  final Color color;
  final String unit;
  final double size;
  
  const ActivityRingPieChart({
    Key? key,
    required this.title,
    required this.current,
    required this.target,
    required this.color,
    required this.unit,
    this.size = 100.0,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = current / target;
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _getIconForTitle(title),
                size: 18,
                color: color,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ProgressPieChart(
            progress: current,
            total: target,
            color: color,
            size: size,
            centerWidget: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  current.toInt().toString(),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onBackground,
                  ),
                ),
                Text(
                  unit,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onBackground.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(progress * 100).toInt()}% completado',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onBackground.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
  
  IconData _getIconForTitle(String title) {
    switch (title.toLowerCase()) {
      case 'movimiento':
        return Icons.whatshot;
      case 'calorías':
        return Icons.local_fire_department;
      case 'pasos':
        return Icons.directions_walk;
      case 'ejercicio':
        return Icons.timer;
      case 'de pie':
        return Icons.accessibility_new;
      default:
        return Icons.fitness_center;
    }
  }
}

class CircularProgressPainter extends CustomPainter {
  final Color backgroundColor;
  final Color valueColor;
  final double value;
  final double strokeWidth;

  CircularProgressPainter({
    required this.backgroundColor,
    required this.valueColor,
    required this.value,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Paint for the background circle
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Paint for the progress arc
    final progressPaint = Paint()
      ..color = valueColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Draw background circle
    canvas.drawCircle(center, radius, backgroundPaint);

    // Draw progress arc
    final progressAngle = 2 * 3.14159 * value;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.14159 / 2, // Start from the top
      progressAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}