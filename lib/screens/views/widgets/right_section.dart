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

  final bool showBorder;
  final AlignmentGeometry contentAlignment;

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
    this.showBorder = true,
    this.contentAlignment = Alignment.center,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: showBorder
          ? BoxDecoration(
              color: isColorError,
              borderRadius: BorderRadius.circular(50),
              border: Border.all(
                color: isError
                    ? Colors.red
                    : isBorder
                    ? Colors.grey.shade400
                    : Colors.transparent,
                width: 2,
              ),
            )
          : const BoxDecoration(color: Colors.transparent),
      child: showBorder
          ? Align(
              alignment: Alignment.center,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: DefaultTextStyle(
                  style: const TextStyle(
                    fontSize: 30,
                    color: Colors.black,
                    height: 1.25,
                  ),
                  textAlign: TextAlign.center,
                  child: title,
                ),
              ),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                return Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: constraints.maxWidth,
                        maxHeight: constraints.maxHeight,
                      ),
                      child: DefaultTextStyle(
                        style: const TextStyle(
                          fontSize: 30,
                          color: Colors.black,
                          height: 1.25,
                        ),
                        textAlign: TextAlign.center,
                        child: title,
                      ),
                    ),
                  ),
                );
              },
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
    return Center(
          child: FractionallySizedBox(
            heightFactor: 0.75,
            widthFactor: 0.75,
            child: Image.asset(
              image,
              key: ValueKey(image),
              fit: BoxFit.contain,
            ),
          ),
        )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scaleXY(
          begin: 1.00,
          end: 1.08,
          duration: 1000.ms,
          curve: Curves.easeInOut,
        );
  }
}
