import 'package:flutter/material.dart';

class BackButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final Color color;

  const BackButton(
      {super.key,
      required this.onPressed,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(
        icon,
        color: color,
        size: 23,
      ),
      padding: const EdgeInsets.only(
        left: 7,
      ),
      style: IconButton.styleFrom(backgroundColor: Colors.black38),
    );
  }
}
