import 'package:flutter/material.dart';
import '../../../core/responsive/responsive_config.dart';

class KioskBox extends StatelessWidget {
  final String text;
  final Color color;
  final ResponsiveConfig config;

  const KioskBox({
    super.key,
    required this.text,
    required this.color,
    required this.config,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            fontSize: config.scale(18),
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
