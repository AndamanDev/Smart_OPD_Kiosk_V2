import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/responsive/responsive_config.dart';
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
                    title: Text.rich(
                      TextSpan(
                        style: GoogleFonts.kanit(),
                        children: [
                          TextSpan(
                            text: "ไม่สามารถเชื่อมต่อ Port ได้\n",
                            style: TextStyle(color: Colors.red),
                          ),

                          TextSpan(
                            text: "กรุณาตรวจสอบการตั้งค่า",
                            style: TextStyle(color: Colors.black54),
                          ),
                        ],
                      ),
                    ),

                    text:
                        "ไม่สามารถเชื่อมต่อ Port ได้\nกรุณาตรวจสอบหน้าตั้งค่า",
                  ),
                  bottomTop: ImageRightSection(
                    config: config,
                    mode: workingMode,
                    isError: true,
                    isScaleDone: false,
                    isBorder: false,
                    isColorError: Colors.red.shade100,
                    image: 'assets/images/close_logo.png',
                    title: Text.rich(
                      TextSpan(
                        style: GoogleFonts.kanit(),
                        children: [
                          TextSpan(
                            text: "ไม่สามารถเชื่อมต่อ Port ได้\n",
                            style: TextStyle(color: Colors.red),
                          ),

                          TextSpan(
                            text: "กรุณาตรวจสอบการตั้งค่า",
                            style: TextStyle(color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                    text:
                        "ไม่สามารถเชื่อมต่อ Port ได้\nกรุณาตรวจสอบหน้าตั้งค่า",
                  ),
                ),

                // ---------------- LANDSCAPE ----------------
                landscape: KioskLandscapeLayout(
                  config: config,
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
                    title: Text.rich(
                      TextSpan(
                        style: GoogleFonts.kanit(),
                        children: [
                          TextSpan(
                            text: "ไม่สามารถเชื่อมต่อ Port ได้\n",
                            style: TextStyle(color: Colors.red),
                          ),

                          TextSpan(
                            text: "กรุณาตรวจสอบการตั้งค่า",
                            style: TextStyle(color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                    text:
                        "ไม่สามารถเชื่อมต่อ Port ได้\nกรุณาตรวจสอบหน้าตั้งค่า",
                  ),
                  bottomTop: ImageRightSection(
                    config: config,
                    mode: workingMode,
                    isError: true,
                    isScaleDone: false,
                    isBorder: false,
                    isColorError: Colors.red.shade100,
                    image: 'assets/images/close_logo.png',
                    title: Text.rich(
                      TextSpan(
                        style: GoogleFonts.kanit(),
                        children: [
                          TextSpan(
                            text: "ไม่สามารถเชื่อมต่อ Port ได้\n",
                            style: TextStyle(color: Colors.red),
                          ),

                          TextSpan(
                            text: "กรุณาตรวจสอบการตั้งค่า",
                            style: TextStyle(color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                    text:
                        "ไม่สามารถเชื่อมต่อ Port ได้\nกรุณาตรวจสอบหน้าตั้งค่า",
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Widget PatientRightSection(ResponsiveConfig config) {
  //   return KioskTextCard(
  //     text: "PORT ERROR",
  //     borderColor: Colors.red,
  //     config: config,
  //   );
  // }
}
