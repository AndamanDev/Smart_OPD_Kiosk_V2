import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/responsive/responsive_config.dart';
import '../../models/working_mode.dart';
import '../../providers/kiosk_state_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers_server/sound_server.dart';
import 'widgets/kiosk_landscape_layout.dart';
import 'widgets/kiosk_portrait_layout.dart';
import 'widgets/kiosk_responsive_middle.dart';
import 'widgets/right_section.dart';
import 'widgets/square_image.dart';

class MeasureErrorView extends StatefulWidget {
  const MeasureErrorView({super.key});

  @override
  State<MeasureErrorView> createState() => MeasureErrorViewState();
}

class MeasureErrorViewState extends State<MeasureErrorView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final settings = context.read<SettingsProvider>();
      await context.read<SoundServer>().playAndWait('sounds/error-126627.mp3');
      if (settings.workingMode == WorkingMode.scaleOnly &&
          settings.scaleDevice.name.contains("205")) {
        await context.read<SoundServer>().playAndWait(
          'sounds/re-start_bam205.wav',
        );
      } else if (settings.workingMode == WorkingMode.scaleOnly &&
          settings.scaleDevice.name.contains("303")) {
        await context.read<SoundServer>().playAndWait(
          'sounds/re-start_BAM303.wav',
        );
      } else if (settings.workingMode == WorkingMode.bloodPressureOnly) {
        await context.read<SoundServer>().playAndWait(
          'sounds/bp_measurment_error.wav',
        );
      }
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

  @override
  Widget build(BuildContext context) {
    final workingMode = context.select<SettingsProvider, WorkingMode>(
      (s) => s.workingMode,
    );
    final settings = context.read<SettingsProvider>();
    final isScale = settings.workingMode == WorkingMode.scaleOnly;
    final isBp = settings.workingMode == WorkingMode.bloodPressureOnly;
    final isShow = settings.scaleDevice.name.contains("303");
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
                            text: (isScale && isShow)
                                ? "อ่านค่าการวัดไม่สำเร็จ\n"
                                : (isScale && !isShow)
                                ? "อ่านค่าการวัดไม่สำเร็จ\n"
                                : (isBp)
                                ? "อ่านค่าการวัดไม่สำเร็จ\n"
                                : "อ่านค่าการวัดไม่สำเร็จ\n",
                            style: TextStyle(color: Colors.red),
                          ),

                          TextSpan(
                            text: (isScale && isShow)
                                ? "กดปุ่มเริ่ม เพื่อทำรายการวัดอีกครั้ง"
                                : (isScale && !isShow)
                                ? "กรุณาลงและขึ้นเครื่องใหม่อีกครั้ง\nเพื่อทำการวัดซ้ำ"
                                : (isBp)
                                ? "กรุณาทำการวัดใหม่อีกครั้ง"
                                : "กรุณาทำการวัดใหม่อีกครั้ง",
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
                            text: (isScale && isShow)
                                ? "อ่านค่าการวัดไม่สำเร็จ\n"
                                : (isScale && !isShow)
                                ? "อ่านค่าการวัดไม่สำเร็จ\n"
                                : (isBp)
                                ? "อ่านค่าการวัดไม่สำเร็จ\n"
                                : "อ่านค่าการวัดไม่สำเร็จ\n",
                            style: TextStyle(color: Colors.red),
                          ),

                          TextSpan(
                            text: (isScale && isShow)
                                ? "กดปุ่มเริ่ม เพื่อทำรายการวัดอีกครั้ง"
                                : (isScale && !isShow)
                                ? "กรุณาลงและขึ้นเครื่องใหม่อีกครั้ง\nเพื่อทำการวัดซ้ำ"
                                : (isBp)
                                ? "กรุณาทำการวัดใหม่อีกครั้ง"
                                : "กรุณาทำการวัดใหม่อีกครั้ง",
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
                            text: (isScale && isShow)
                                ? "อ่านค่าการวัดไม่สำเร็จ\n"
                                : (isScale && !isShow)
                                ? "อ่านค่าการวัดไม่สำเร็จ\n"
                                : (isBp)
                                ? "อ่านค่าการวัดไม่สำเร็จ\n"
                                : "อ่านค่าการวัดไม่สำเร็จ\n",
                            style: TextStyle(color: Colors.red),
                          ),

                          TextSpan(
                            text: (isScale && isShow)
                                ? "กดปุ่มเริ่ม เพื่อทำรายการวัดอีกครั้ง"
                                : (isScale && !isShow)
                                ? "กรุณาลงและขึ้นเครื่องใหม่อีกครั้ง\nเพื่อทำการวัดซ้ำ"
                                : (isBp)
                                ? "กรุณาทำการวัดใหม่อีกครั้ง"
                                : "กรุณาทำการวัดใหม่อีกครั้ง",
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
                            text: (isScale && isShow)
                                ? "อ่านค่าการวัดไม่สำเร็จ\n"
                                : (isScale && !isShow)
                                ? "อ่านค่าการวัดไม่สำเร็จ\n"
                                : (isBp)
                                ? "อ่านค่าการวัดไม่สำเร็จ\n"
                                : "อ่านค่าการวัดไม่สำเร็จ\n",
                            style: TextStyle(color: Colors.red),
                          ),

                          TextSpan(
                            text: (isScale && isShow)
                                ? "กดปุ่มเริ่ม เพื่อทำรายการวัดอีกครั้ง"
                                : (isScale && !isShow)
                                ? "กรุณาลงและขึ้นเครื่องใหม่อีกครั้ง\nเพื่อทำการวัดซ้ำ"
                                : (isBp)
                                ? "กรุณาทำการวัดใหม่อีกครั้ง"
                                : "กรุณาทำการวัดใหม่อีกครั้ง",
                            style: TextStyle(color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
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
