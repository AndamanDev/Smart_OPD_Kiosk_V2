import 'package:flutter/material.dart';
import '../../../core/responsive/responsive_config.dart';

class KioskPortraitLayout extends StatelessWidget {
  final ResponsiveConfig config;
  final Widget? top;
  final Widget? middle;
  final Widget? bottomTop;
  final Widget? bottom;

  const KioskPortraitLayout({
    super.key,
    required this.config,
    this.top,
    this.middle,
    this.bottomTop,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = config.scale(40);
    final spacing = config.scale(12);

    return Column(
      children: [
        if (top != null)
          Expanded(
            flex: 2,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: top!,
            ),
          ),

        if (top != null && middle != null)
          SizedBox(height: spacing),

        if (middle != null)
          Expanded(
            flex: 5,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: middle!,
            ),
          ),

        if (middle != null && bottomTop != null)
          SizedBox(height: spacing),

        if (bottomTop != null)
          Expanded(
            flex: 2,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: bottomTop!,
            ),
          ),

        if ((middle != null || bottomTop != null) && bottom != null)
          SizedBox(height: spacing),

        if (bottom != null)
          Expanded(
            flex: 2,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: bottom!,
            ),
          ),
      ],
    );
  }
}
