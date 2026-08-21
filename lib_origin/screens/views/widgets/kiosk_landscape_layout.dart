import 'package:flutter/material.dart';
import '../../../core/responsive/layout_ratio.dart';
import '../../../core/responsive/responsive_config.dart';

class KioskLandscapeLayout extends StatelessWidget {
  final ResponsiveConfig config;
  final Widget? left;
  final Widget? topRight;
  final Widget? bottomTop;
  final Widget bottomRight;

  const KioskLandscapeLayout({
    super.key,
    required this.config,
    required this.left,
    required this.topRight,
    required this.bottomTop,
    required this.bottomRight,
  });

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = config.scale(40);
    final spacing = config.scale(12);

    return Row(
      children: [
        Expanded(
          flex: LayoutRatio.left,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: left,
          ),
        ),
        Expanded(
          flex: LayoutRatio.right,
          child: Column(
            children: [
              if (topRight != null)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                    ),
                    child: topRight!,
                  ),
                ),

              if (topRight != null) SizedBox(height: spacing),

              if (bottomTop != null)
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                    ),
                    child: bottomTop!,
                  ),
                ),

              if (bottomTop != null) SizedBox(height: spacing),

              Expanded(
                flex: 1,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: bottomRight,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
