import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:IAEntrenar/core/ui/sleek_spinner.dart';

class SocialButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final IconData icon;
  final Color backgroundColor;
  final Color textColor;
  final bool isLoading;

  const SocialButton({
    super.key,
    required this.text,
    required this.onPressed,
    required this.icon,
    required this.backgroundColor,
    required this.textColor,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (isLoading)
            SleekSpinner(size: 24, color: textColor),
          if (!isLoading)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 20),
                const SizedBox(width: 12),
                Text(
                  text,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                ),
              ],
            ),
        ],
      ),
    )
    .animate()
    .fadeIn(duration: const Duration(milliseconds: 300))
    .slideY(begin: 0.2, end: 0);
  }
}