import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/responsive/responsive_config.dart';
import '../../models/working_mode.dart';
import '../../providers/kiosk_state_provider.dart';
import '../../providers/serial_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers_server/sound_server.dart';
import 'widgets/kiosk_landscape_layout.dart';
import 'widgets/kiosk_portrait_layout.dart';
import 'widgets/kiosk_responsive_middle.dart';
import 'widgets/right_section.dart';
import 'widgets/square_image.dart';

class LoginErrorView extends StatefulWidget {
  const LoginErrorView({super.key});

  @override
  State<LoginErrorView> createState() => _LoginErrorViewState();
}

class _LoginErrorViewState extends State<LoginErrorView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<SoundServer>().playAndWait('sounds/error-126627.mp3');
      // await context.read<SoundServer>().playAndWait('sounds/notfound_hn.wav');
      _checkPortStatus();
    });
    context.read<SerialProvider>().addListener(_checkPortStatus);
  }

  void _checkPortStatus() {
    if (!mounted) return;
    final serial = context.read<SerialProvider>();
    final kiosk = context.read<KioskStageProvider>();

    if (serial.isConnected) {
      serial.removeListener(_checkPortStatus);
      kiosk.setStage(KioskStage.scan);
    }
  }

  @override
  void dispose() {
    context.read<SerialProvider>().removeListener(_checkPortStatus);
    context.read<SoundServer>().dispose();
    super.dispose();
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

                    // title:
                    //     "ไม่สามารถเชื่อมต่อ Server\nกรุณาตรวจสอบการตั้งค่า",
                    title: Text.rich(
                      TextSpan(
                        style: GoogleFonts.kanit(),
                        children: [
                          TextSpan(
                            text: "ไม่สามารถเชื่อมต่อ Server ได้\n",
                            style: TextStyle(color: Colors.red),
                          ),

                          TextSpan(
                            text: "กรุณาตรวจสอบการตั้งค่า",
                            style: TextStyle(color: Colors.black54),
                          ),
                        ],
                      ),
                    ),

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

                    title: Text.rich(
                      TextSpan(
                        style: GoogleFonts.kanit(),
                        children: [
                          TextSpan(
                            text: "ไม่สามารถเชื่อมต่อ Server ได้\n",
                            style: TextStyle(color: Colors.red),
                          ),

                          TextSpan(
                            text: "กรุณาตรวจสอบการตั้งค่า",
                            style: TextStyle(color: Colors.black54),
                          ),
                        ],
                      ),
                    ),

                    text: "",
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
                            text: "ไม่สามารถเชื่อมต่อ Server ได้\n",
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
                            text: "ไม่สามารถเชื่อมต่อ Server ได้\n",
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
}
