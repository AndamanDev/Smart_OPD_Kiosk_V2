import 'package:flutter/material.dart';
import '../../../core/responsive/layout_ratio.dart';
import '../../../core/responsive/responsive_config.dart';
import '../../../core/theme/app_theme.dart';

class KioskLandscapeLayout extends StatelessWidget {
  final ResponsiveConfig config;
  final Widget? left;
  final Widget? topRight;
  final Widget? bottomTop;
  final Widget bottomRight;
  final bool combineRight;
  final Color combineColor;
  final Color combineBorderColor;

  const KioskLandscapeLayout({
    super.key,
    required this.config,
    required this.left,
    required this.topRight,
    required this.bottomTop,
    required this.bottomRight,
    this.combineRight = false,
    this.combineColor = Colors.white,
    this.combineBorderColor = const Color(0xFFBDBDBD),
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
            child: Container(
              decoration: AppCardDecoration.standard,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: left,
              ),
            ),
          ),
        ),
        Expanded(
          flex: LayoutRatio.right,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: combineRight
                ? Container(
                    decoration: AppCardDecoration.standard.copyWith(
                      color: combineColor,
                      border: Border.all(color: combineBorderColor, width: 2),
                    ),
                    child: Column(
                      children: [
                        if (topRight != null)
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 6,
                              ),
                              child: topRight!,
                            ),
                          ),
                        if (topRight != null)
                          Divider(height: 1, color: Colors.transparent),
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
                        if (bottomTop != null)
                          Divider(height: 1, color: Colors.transparent),
                        Expanded(
                          flex: 1,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 12,
                            ),
                            child: Align(
                              alignment: Alignment.center,
                              child: bottomRight,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      if (topRight != null)
                        Expanded(
                          child: Container(
                            decoration: AppCardDecoration.standard,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: topRight!,
                            ),
                          ),
                        ),

                      if (topRight != null) SizedBox(height: spacing),

                      if (bottomTop != null)
                        Expanded(
                          flex: 2,
                          child: Container(
                            decoration: AppCardDecoration.standard,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: bottomTop!,
                            ),
                          ),
                        ),

                      if (bottomTop != null) SizedBox(height: spacing),

                      Expanded(
                        flex: 1,
                        child: Container(
                          decoration: AppCardDecoration.standard.copyWith(
                            color: AppColors.lightGreen,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: bottomRight,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}
