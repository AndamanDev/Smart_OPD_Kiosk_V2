import 'package:flutter/material.dart';
import '../../../core/responsive/responsive_config.dart';
import '../../../core/theme/app_theme.dart';

class KioskPortraitLayout extends StatelessWidget {
  final ResponsiveConfig config;
  final Widget? top;
  final Widget? middle;
  final Widget? bottomTop;
  final Widget? bottom;
  final bool combineTopBottom;
  final Color combineColor;
  final Color combineBorderColor;

  const KioskPortraitLayout({
    super.key,
    required this.config,
    this.top,
    this.middle,
    this.bottomTop,
    this.bottom,
    this.combineTopBottom = false,
    this.combineColor = Colors.white,
    this.combineBorderColor = const Color(0xFFBDBDBD), // Colors.grey.shade400
  });

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = config.scale(40);
    final spacing = config.scale(12);

    // Combined top+bottom into one card
    if (combineTopBottom && (top != null || bottom != null)) {
      return Column(
        children: [
          Expanded(
            flex: 4,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Container(
                decoration: AppCardDecoration.standard.copyWith(
                  color: combineColor,
                  border: Border.all(color: combineBorderColor, width: 2),
                ),
                child: Column(
                  children: [
                    if (top != null)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          child: top!,
                        ),
                      ),
                    if (top != null && bottom != null)
                      Divider(height: 1, color: Colors.grey.shade300),
                    if (bottomTop != null)
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          child: bottomTop!,
                        ),
                      ),
                    if (bottomTop != null && bottom != null)
                      Divider(height: 1, color: Colors.grey.shade300),
                    if (bottom != null)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 12,
                          ),
                          child: Align(
                            alignment: Alignment.center,
                            child: bottom!,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          SizedBox(height: spacing),

          if (middle != null)
            Expanded(
              flex: 5,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: middle!,
              ),
            ),
        ],
      );
    }

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
