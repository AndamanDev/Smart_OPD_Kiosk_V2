import 'package:flutter/material.dart';
import '../../../core/responsive/responsive_config.dart';

class KioskResponsiveMiddle extends StatelessWidget {
  final ResponsiveConfig config;
  final Widget portrait;
  final Widget landscape;

  const KioskResponsiveMiddle({
    super.key,
    required this.config,
    required this.portrait,
    required this.landscape,
  });

  @override
  Widget build(BuildContext context) {
    return config.isLandscape ? landscape : portrait;
  }
}
