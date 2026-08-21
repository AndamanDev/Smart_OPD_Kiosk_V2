import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/responsive/responsive_config.dart';
import '../../core/theme/app_theme.dart';
import '../../models/working_mode.dart';
import '../../providers/kiosk_state_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers_server/sound_server.dart';
import 'widgets/kiosk_landscape_layout.dart';
import 'widgets/kiosk_portrait_layout.dart';
import 'widgets/kiosk_responsive_middle.dart';
import 'widgets/right_section.dart';
import 'widgets/square_image.dart';

class SaveMeasureErrorView extends StatefulWidget {
  const SaveMeasureErrorView({super.key});

  @override
  State<SaveMeasureErrorView> createState() => SaveMeasureErrorViewState();
}

class SaveMeasureErrorViewState extends State<SaveMeasureErrorView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<SoundServer>().playAndWait('sounds/error-126627.mp3');
      if (mounted) {
        context.read<KioskStageProvider>().setStage(
          KioskStage.measure,
          isRetry: true,
        );
      }
    });
  }

  @override
  void dispose() {
    context.read<SoundServer>().dispose();
    super.dispose();
  }

  Widget _errorTitle() => Text.rich(
        const TextSpan(
          style: TextStyle(fontFamily: 'THSarabunNew'),
          children: [
            TextSpan(
              text: "\u0e1a\u0e31\u0e19\u0e17\u0e36\u0e01\u0e02\u0e49\u0e2d\u0e21\u0e39\u0e25\u0e44\u0e21\u0e48\u0e2a\u0e33\u0e40\u0e23\u0e47\u0e08\n",
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 32,
              ),
            ),
            TextSpan(
              text: "\u0e01\u0e23\u0e38\u0e13\u0e32\u0e17\u0e33\u0e23\u0e32\u0e22\u0e01\u0e32\u0e23\u0e2d\u0e35\u0e01\u0e04\u0e23\u0e31\u0e49\u0e07",
              style: TextStyle(color: AppColors.darkGray, fontSize: 26),
            ),
          ],
        ),
        textAlign: TextAlign.center,
      );

  @override
  Widget build(BuildContext context) {
    final workingMode = context.select<SettingsProvider, WorkingMode>(
      (s) => s.workingMode,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final config = ResponsiveConfig(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
        );

        return Stack(
          children: [
            Positioned.fill(
              child: KioskResponsiveMiddle(
                config: config,
                portrait: KioskPortraitLayout(
                  config: config,
                  combineTopBottom: true,
                  combineColor: Colors.red.shade100,
                  combineBorderColor: Colors.red.shade300,
                  top: null,
                  middle: ModeSquareImage(
                    mode: workingMode,
                    isError: true,
                    isScaleDone: false,
                  ),
                  bottom: RightSection(
                    config: config,
                    mode: workingMode,
                    isError: true,
                    isScaleDone: false,
                    isBorder: false,
                    isColorError: Colors.red.shade100,
                    image: 'assets/images/close_logo.png',
                    showBorder: false,
                    title: _errorTitle(),
                    text: "",
                  ),
                  bottomTop: ImageRightSection(
                    config: config,
                    mode: workingMode,
                    isError: true,
                    isScaleDone: false,
                    isBorder: false,
                    isColorError: Colors.red.shade100,
                    image: 'assets/images/close_logo.png',
                    title: _errorTitle(),
                    text: "",
                  ),
                ),
                landscape: KioskLandscapeLayout(
                  config: config,
                  combineRight: true,
                  combineColor: Colors.red.shade100,
                  combineBorderColor: Colors.red.shade300,
                  left: ModeSquareImage(
                    mode: workingMode,
                    isError: true,
                    isScaleDone: false,
                  ),
                  topRight: null,
                  bottomRight: RightSection(
                    config: config,
                    mode: workingMode,
                    isError: true,
                    isScaleDone: false,
                    isBorder: false,
                    isColorError: Colors.red.shade100,
                    image: 'assets/images/close_logo.png',
                    showBorder: false,
                    title: _errorTitle(),
                    text: "",
                  ),
                  bottomTop: ImageRightSection(
                    config: config,
                    mode: workingMode,
                    isError: true,
                    isScaleDone: false,
                    isBorder: false,
                    isColorError: Colors.red.shade100,
                    image: 'assets/images/close_logo.png',
                    title: _errorTitle(),
                    text: "",
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}