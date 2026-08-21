import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/responsive/responsive_config.dart';
import '../../core/theme/app_theme.dart';
import '../../models/working_mode.dart';
import '../../providers/settings_provider.dart';
import '../../providers_server/sound_server.dart';
import 'widgets/kiosk_landscape_layout.dart';
import 'widgets/kiosk_portrait_layout.dart';
import 'widgets/kiosk_responsive_middle.dart';
import 'widgets/right_section.dart';
import 'widgets/square_image.dart';

class PortErrorView extends StatefulWidget {
  const PortErrorView({super.key});

  @override
  State<PortErrorView> createState() => _PortErrorViewState();
}

class _PortErrorViewState extends State<PortErrorView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<SoundServer>().playAndWait('sounds/error-126627.mp3');
    });
  }

  Widget _errorTitle() => Text.rich(
        TextSpan(
          style: const TextStyle(fontFamily: 'THSarabunNew'),
          children: [
            const TextSpan(
              text: "ไม่สามารถเชื่อมต่อ Port ได้\n",
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 32,
              ),
            ),
            const TextSpan(
              text: "กรุณาตรวจสอบการตั้งค่า",
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

                // ---------------- PORTRAIT ----------------
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
                    text: "ไม่สามารถเชื่อมต่อ Port ได้\nกรุณาตรวจสอบหน้าตั้งค่า",
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
                    text: "ไม่สามารถเชื่อมต่อ Port ได้\nกรุณาตรวจสอบหน้าตั้งค่า",
                  ),
                ),

                // ---------------- LANDSCAPE ----------------
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
                    text: "ไม่สามารถเชื่อมต่อ Port ได้\nกรุณาตรวจสอบหน้าตั้งค่า",
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
                    text: "ไม่สามารถเชื่อมต่อ Port ได้\nกรุณาตรวจสอบหน้าตั้งค่า",
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
