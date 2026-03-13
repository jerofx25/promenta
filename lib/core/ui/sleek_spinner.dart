import 'package:flutter/material.dart';
import 'package:sleek_circular_slider/sleek_circular_slider.dart';

/// Spinner de carga usando [sleek_circular_slider] en modo spinner.
class SleekSpinner extends StatelessWidget {
  const SleekSpinner({
    super.key,
    this.size = 48,
    this.color,
  });

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spinnerColor = color ?? theme.colorScheme.primary;

    return SizedBox(
      width: size,
      height: size,
      child: SleekCircularSlider(
        initialValue: 50,
        min: 0,
        max: 100,
        appearance: CircularSliderAppearance(
          size: size,
          spinnerMode: true,
          spinnerDuration: 1500,
          animationEnabled: true,
          customWidths: CustomSliderWidths(
            trackWidth: size * 0.08,
            progressBarWidth: size * 0.12,
            handlerSize: 0,
          ),
          customColors: CustomSliderColors(
            trackColor: spinnerColor.withOpacity(0.2),
            progressBarColors: [spinnerColor, spinnerColor],
            hideShadow: true,
          ),
          infoProperties: InfoProperties(modifier: (_) => ''),
        ),
        innerWidget: (_) => const SizedBox.shrink(),
      ),
    );
  }
}
