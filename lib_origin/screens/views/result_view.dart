import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/responsive/responsive_config.dart';
import '../../providers/patient_provider.dart';
import '../../models/working_mode.dart';
import '../../providers/auth_provider.dart';
import '../../providers/kiosk_state_provider.dart';
import '../../providers/patient_provider.dart';
import '../../providers/serial_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/vitals_provider.dart';
import '../../providers_server/serial_server.dart';
import '../../providers_server/sound_server.dart';
import '../../utils/BloodPressureUtils.dart';
import '../../utils/ScaleUtils.dart';
import 'widgets/kiosk_landscape_layout.dart';
import 'widgets/kiosk_portrait_layout.dart';
import 'widgets/kiosk_responsive_middle.dart';
import 'widgets/patient_right_section.dart';
import 'widgets/result_section.dart';
import 'widgets/right_section.dart';
import 'widgets/square_image.dart';

class ResultView extends StatefulWidget {
  const ResultView({super.key});

  @override
  State<ResultView> createState() => _ResultViewState();
}

class _ResultViewState extends State<ResultView> {
  final SerialServer _server = SerialServer();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final settings = context.read<SettingsProvider>();
      final serial = context.read<SerialProvider>();

      await context.read<SoundServer>().playAndWait('sounds/bell-98033.mp3');

      switch (settings.workingMode) {
        case WorkingMode.scaleOnly:
          await context.read<SoundServer>().playAndWait(
            'sounds/save_finished.wav',
          );
          break;

        case WorkingMode.bloodPressureOnly:
        case WorkingMode.combined:
          await context.read<SoundServer>().playAndWait(
            'sounds/bp_save_finished.wav',
          );
          break;
      }

      if (!mounted) return;

      _server.stop();
      serial.stop();
      context.read<KioskStageProvider>().reset(serial);
    });
  }

  @override
  void dispose() {
    context.read<SoundServer>().dispose();
    super.dispose();
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final patientProvider = context.watch<PatientProvider>();
    final raw = patientProvider.rawVitalsData;
    final patient = patientProvider.patient;

    final workingMode = context.select<SettingsProvider, WorkingMode>(
      (s) => s.workingMode,
    );

    // ---------- split raw ----------
    String scaleRaw = "";
    String bpRaw = "";

    // if (raw.contains("|")) {
    //   final parts = raw.split("|");
    //   scaleRaw = parts[0];
    //   bpRaw = parts[1];
    // } else {
    //   scaleRaw = raw;
    // }
    if (raw.contains("|")) {
      final parts = raw.split("|");
      scaleRaw = parts[0];
      bpRaw = parts[1];
    } else {
      if (workingMode == WorkingMode.bloodPressureOnly) {
        bpRaw = raw;
      } else {
        scaleRaw = raw;
      }
    }

    // ---------- parse ONLY needed ----------
    ScaleReading scale = ScaleReading(weight: 0, height: 0, bmi: 0);
    BloodReading bp = BloodReading(systolic: 0, diastolic: 0, pulse: 0);

    switch (workingMode) {
      case WorkingMode.scaleOnly:
        scale = ScaleUtils.parse(scaleRaw);
        break;

      case WorkingMode.bloodPressureOnly:
        bp = BloodPressureUtils.parse(bpRaw);
        break;

      case WorkingMode.combined:
        scale = ScaleUtils.parse(scaleRaw);
        bp = BloodPressureUtils.parse(bpRaw);
        break;
    }

    final bool isBpDone = bp.systolic > 0;
    final bool doneScale = scale.weight > 0;
    final bool doneBp = bp.systolic > 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final config = ResponsiveConfig(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
        );

        bool isMeasurementDone = workingMode == WorkingMode.scaleOnly
            ? doneScale
            : workingMode == WorkingMode.bloodPressureOnly
            ? doneBp
            : (doneScale && doneBp);

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          child: Stack(
            children: [
              Positioned.fill(
                child: KioskResponsiveMiddle(
                  config: config,
                  portrait: KioskPortraitLayout(
                    config: config,
                    top:
                        PatientRightSection(
                          config: config,
                          mode: workingMode,
                          isError: false,
                          isScaleDone: false,
                          patient: patient!,
                          image: "",
                        ).animate().slideY(
                          begin: -0.5,
                          end: 0,
                          duration: 500.ms,
                          curve: Curves.easeOut,
                        ),
                    // middle: Expanded(
                    //   child: buildResult(workingMode, scale, bp),
                    // ),
                    middle: buildResult(workingMode, scale, bp),
                    bottom: RightSection(
                      config: config,
                      mode: workingMode,
                      isError: false,
                      isScaleDone: false,
                      isBorder: false,
                      isColorError: isMeasurementDone
                          ? Colors.green.shade100
                          : Colors.red.shade100,
                      image: "",
                      title: buildInstruction(isMeasurementDone),
                      text: "",
                    ).animate().fade(duration: 500.ms, curve: Curves.easeIn),
                    bottomTop: null,
                  ),

                  landscape: KioskLandscapeLayout(
                    config: config,
                    // left: Expanded(child: buildResult(workingMode, scale, bp)),
                    left: buildResult(workingMode, scale, bp),
                    topRight:
                        PatientRightSection(
                          config: config,
                          mode: workingMode,
                          isError: false,
                          isScaleDone: false,
                          patient: patient!,
                          image: "",
                        ).animate().slideY(
                          begin: -0.5,
                          end: 0,
                          duration: 500.ms,
                          curve: Curves.easeOut,
                        ),
                    bottomRight:
                        RightSection(
                          config: config,
                          mode: workingMode,
                          isError: false,
                          isScaleDone: false,
                          isBorder: false,
                          isColorError: isMeasurementDone
                              ? Colors.green.shade100
                              : Colors.red.shade100,
                          image: "",
                          title: buildInstruction(isMeasurementDone),
                          text: "",
                        ).animate().slideY(
                          begin: 0.5,
                          end: 0,
                          duration: 500.ms,
                          curve: Curves.easeOut,
                        ),
                    bottomTop: null,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget buildInstruction(bool isMeasurementDone) {
    return Text.rich(
      TextSpan(
        style: GoogleFonts.kanit(),
        children: [
          TextSpan(
            text: "บันทึกผลการวัดสำเร็จ\n",
            style: TextStyle(
              color: Colors.green.shade800,
              fontWeight: FontWeight.bold,
            ),
          ),
          TextSpan(
            text: "ขอบคุณค่ะ",
            style: TextStyle(color: Colors.green.shade800),
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget buildResult(WorkingMode mode, ScaleReading scale, BloodReading bp) {
    return ResultSection(
      mode: mode,
      isError: false,
      isScaleDone: false,
      image: "",
      scale: scale,
      blood: bp,
      weight: "WEIGHT (น้ำหนัก)",
      height: "HEIGHT (ส่วนสูง)",
      bmi: "BMI (ค่าดัชนีมวลกาย)",
      unitweight: "kg",
      unitheight: "cm",
      unitbmi: "kg/m²",
      sys: "SYSTOLIC (ค่าความดันโลหิต)",
      dia: "DIASTOLIC (ค่าความดันตัวล่าง)",
      pulse: "PULSE (ชีพจร)",
      unitsys: "mmHg",
      unitdia: "mmHg",
      unitpulse: "bpm",
    );
  }
}
