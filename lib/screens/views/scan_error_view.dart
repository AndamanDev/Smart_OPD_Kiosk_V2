import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/responsive/responsive_config.dart';
import '../../models/working_mode.dart';
import '../../providers/kiosk_state_provider.dart';
import '../../providers/serial_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers_server/serial_server.dart';
import '../../providers_server/sound_server.dart';
import 'widgets/kiosk_landscape_layout.dart';
import 'widgets/kiosk_portrait_layout.dart';
import 'widgets/kiosk_responsive_middle.dart';
import 'widgets/right_section.dart';
import 'widgets/square_image.dart';


class ScanErrorView extends StatefulWidget {
  const ScanErrorView({super.key});

  @override
  State<ScanErrorView> createState() => _ScanErrorViewState();
}

class _ScanErrorViewState extends State<ScanErrorView> {
  final SerialServer _server = SerialServer();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<SoundServer>().playAndWait('sounds/error-126627.mp3');
      await context.read<SoundServer>().playAndWait('sounds/notfound_hn.wav');
      if (mounted) {
        _server.stop();
        final serial = context.read<SerialProvider>();
        context.read<KioskStageProvider>().reset(serial);
      }
    });
  }

  @override
  void dispose() {
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
                    title: Text.rich(
                      TextSpan(
                        style: GoogleFonts.kanit(),
                        children: [
                          TextSpan(
                            text: "ไม่พบข้อมูล\n",
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextSpan(
                            text: "กรุณาสแกน QR Code อีกครั้ง",
                            style: TextStyle(color: Colors.black54),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    // title: "ไม่พบข้อมูล\nกรุณาสแกน QR Code อีกครั้ง",
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
                            text: "ไม่พบข้อมูล\n",
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextSpan(
                            text: "กรุณาสแกน QR Code อีกครั้ง",
                            style: TextStyle(color: Colors.black54),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    // title: "ไม่พบข้อมูล\nกรุณาสแกน QR Code อีกครั้ง",
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
                            text: "ไม่พบข้อมูล\n",
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextSpan(
                            text: "กรุณาสแกน QR Code อีกครั้ง",
                            style: TextStyle(color: Colors.black54),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    // title: "ไม่พบข้อมูล\nกรุณาสแกน QR Code อีกครั้ง",
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
                            text: "ไม่พบข้อมูล\n",
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextSpan(
                            text: "กรุณาสแกน QR Code อีกครั้ง",
                            style: TextStyle(color: Colors.black54),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    // title: "ไม่พบข้อมูล\nกรุณาสแกน QR Code อีกครั้ง",
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

  // Widget PatientRightSection(ResponsiveConfig config) {
  //   return KioskTextCard(
  //     text: "PORT ERROR",
  //     borderColor: Colors.red,
  //     config: config,
  //   );
  // }
}
