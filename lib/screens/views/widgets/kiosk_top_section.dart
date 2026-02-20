import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/responsive/responsive_config.dart';
import '../../../models/working_mode.dart';
import '../../../providers/settings_provider.dart';

class KioskTopSection extends StatelessWidget {
  final ResponsiveConfig config;

  final String leftTitle;
  final String leftSubtitle;
  final String rightImage;

  final Color leftColor;
  final bool isError;

  const KioskTopSection({
    super.key,
    required this.config,
    required this.rightImage,
    this.leftTitle = "Digital Smart Healthcare",
    this.leftSubtitle = "",
    this.leftColor = Colors.white,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    final settings = context.read<SettingsProvider>();
    final workingMode = context.select<SettingsProvider, WorkingMode>(
      (s) => s.workingMode,
    );

    final horizontalPadding = config.scale(40);
    final spacing = config.scale(12);

    return Row(
      children: [
        /// ================= LEFT (TEXT CARD) =================
        Expanded(
          flex: 1,
          child: KioskCardBox(
            isError: isError,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start, // ✅ ชิดซ้าย
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      leftTitle,
                      style: TextStyle(
                        // fontSize: config.scale(24),
                        fontSize: 56,
                        fontWeight: FontWeight.bold,
                          color: Colors.blue[600],
                      ),
                    ),
                  ),
                  SizedBox(height: config.scale(8)),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      settings.workingMode == WorkingMode.scaleOnly
                          ? "Smart Scale Monitor"
                          : settings.workingMode ==
                                WorkingMode.bloodPressureOnly
                          ? "Smart Blood Pressure Monitor"
                          : settings.workingMode == WorkingMode.combined
                          ? "Vital Sign Convergence System"
                          : "",
                      textAlign: TextAlign.left, // ✅ เปลี่ยนเป็น left
                      style: TextStyle(
                        // fontSize: config.scale(18),
                        fontSize: 36,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        /// ================= RIGHT (IMAGE CARD) =================
        Expanded(
          flex: 1,
          child: KioskCardBox(
            child: Image.asset(rightImage, fit: BoxFit.contain),
          ),
        ),
      ],
    );
  }
}

class KioskCardBox extends StatelessWidget {
  final Widget child;
  final bool isError;
  final Color backgroundColor;

  const KioskCardBox({
    super.key,
    required this.child,
    this.isError = false,
    this.backgroundColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(0),
      decoration: BoxDecoration(color: backgroundColor),
      child: child,
    );
  }
}
