import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/responsive/responsive_config.dart';
import '../../../models/working_mode.dart';

class RightSection extends StatelessWidget {
  final WorkingMode mode;
  final double? height;
  final bool isError;
  final bool isScaleDone;
  final Widget title;
  final String text;
  final String image;
  final bool isBorder;
  final Color isColorError;
  final ResponsiveConfig config;

  const RightSection({
    super.key,
    required this.mode,
    this.height,
    this.isError = false,
    required this.isScaleDone,
    required this.title,
    required this.text,
    required this.image,
    required this.isBorder,
    required this.isColorError,
    required this.config,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
          width: double.infinity,
      decoration: BoxDecoration(
        color: isColorError,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isError
              ? Colors.red
              : isBorder
              ? Colors.grey.shade400
              : Colors.transparent,
          width: 2,
        ),
      ),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: DefaultTextStyle(
            style: const TextStyle(
              fontSize: 28,
              color: Colors.black,
              height: 1.25,
            ),
            textAlign: TextAlign.center,
            child: title,
          ),
        ),
      ),
    );
  }
}

class ImageRightSection extends StatelessWidget {
  final WorkingMode mode;
  final double? height;
  final bool isError;
  final bool isScaleDone;
  final Widget title;
  final String text;
  final String image;
  final bool isBorder;
  final Color isColorError;
  final ResponsiveConfig config;

  const ImageRightSection({
    super.key,
    required this.mode,
    this.height,
    this.isError = false,
    required this.isScaleDone,
    required this.title,
    required this.text,
    required this.image,
    required this.isBorder,
    required this.isColorError,
    required this.config,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
          child: Center(
            child: Image.asset(
              image,
              key: ValueKey(image),
              fit: BoxFit.contain,
            ),
          ),
        )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scaleXY(
          begin: 1.0,
          end: 1.25,
          duration: 1000.ms,
          curve: Curves.easeInOut,
        );
  }
}
