import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/responsive/responsive_config.dart';
import '../../core/theme/app_theme.dart';
import '../../models/working_mode.dart';
import '../../providers/kiosk_state_provider.dart';
import '../../providers/patient_provider.dart';
import '../../providers/serial_provider.dart';
import '../../providers/settings_provider.dart';
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

      final bool bpExceeded =
          _isBpExceeded(settings, context.read<PatientProvider>());

      if (bpExceeded) {
        // ⭐ ความดันเกินเกณฑ์ → error + เสียงเตือนให้นั่งพัก (แทนเสียงบันทึกสำเร็จปกติ)
        await context.read<SoundServer>().playAndWait('sounds/error-126627.mp3');
        if (!mounted) return;
        await context.read<SoundServer>().playAndWait(
          'sounds/bp_warnning_voice.wav',
        );
      } else {
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
      }

      if (!mounted) return;

      // ค้างจอต่ออีก 8 วิ หลังเสียงเล่นจบ (ให้ผู้ป่วยอ่านผลทัน)
      await Future.delayed(const Duration(seconds: 8));
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

  // แยกค่าความดันจาก raw ตามโหมด แล้ว parse ตามรุ่นเครื่อง
  BloodReading _parseBp(SettingsProvider settings, PatientProvider patient) {
    final raw = patient.rawVitalsData;
    String bpRaw = "";
    if (raw.contains("|")) {
      bpRaw = raw.split("|")[1];
    } else if (settings.workingMode == WorkingMode.bloodPressureOnly) {
      bpRaw = raw;
    }
    if (bpRaw.isEmpty) {
      return const BloodReading(systolic: 0, diastolic: 0, pulse: 0);
    }
    return BloodPressureUtils.parseByDevice(bpRaw, settings.bpDevice);
  }

  // เกินเกณฑ์เมื่อ SYS หรือ DIA ที่วัดได้ มากกว่าค่าอ้างอิงที่กำหนด (เฉพาะช่องที่ตั้งค่าไว้)
  bool _exceedsRef(BloodReading bp, SettingsProvider settings) {
    if (bp.systolic <= 0) return false;
    return (settings.bpRefSys > 0 && bp.systolic > settings.bpRefSys) ||
        (settings.bpRefDia > 0 && bp.diastolic > settings.bpRefDia);
  }

  bool _isBpExceeded(SettingsProvider settings, PatientProvider patient) =>
      _exceedsRef(_parseBp(settings, patient), settings);

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
    final settings = context.read<SettingsProvider>();
    final bpDevice = settings.bpDevice;
    ScaleReading scale = ScaleReading(weight: 0, height: 0, bmi: 0);
    BloodReading bp = BloodReading(systolic: 0, diastolic: 0, pulse: 0);

    switch (workingMode) {
      case WorkingMode.scaleOnly:
        scale = ScaleUtils.parse(scaleRaw);
        break;

      case WorkingMode.bloodPressureOnly:
        bp = BloodPressureUtils.parseByDevice(bpRaw, bpDevice);
        break;

      case WorkingMode.combined:
        scale = ScaleUtils.parse(scaleRaw);
        bp = BloodPressureUtils.parseByDevice(bpRaw, bpDevice);
        break;
    }

    final bool doneScale = scale.weight > 0;
    final bool doneBp = bp.systolic > 0;

    // ---------- เทียบกับค่าอ้างอิงความดัน (ถ้าตั้งไว้) ----------
    final bool bpExceeded = _exceedsRef(bp, settings);

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
                    combineTopBottom: true,
                    top:
                        PatientRightSection(
                          config: config,
                          mode: workingMode,
                          isError: false,
                          isScaleDone: false,
                          patient: patient!,
                          image: "",
                          showBorder: false,
                        ).animate().slideY(
                          begin: -0.5,
                          end: 0,
                          duration: 500.ms,
                          curve: Curves.easeOut,
                        ),
                    middle: buildResult(workingMode, scale, bp),
                    bottom: RightSection(
                      config: config,
                      mode: workingMode,
                      isError: false,
                      isScaleDone: false,
                      isBorder: false,
                      isColorError: isMeasurementDone
                          ? AppColors.lightGreen
                          : Colors.red.shade100,
                      image: "",
                      showBorder: false,
                      title: buildInstruction(isMeasurementDone, bpExceeded),
                      text: "",
                    ).animate().fade(duration: 500.ms, curve: Curves.easeIn),
                    bottomTop: null,
                  ),

                  landscape: KioskLandscapeLayout(
                    config: config,
                    combineRight: false,
                    left: buildResult(workingMode, scale, bp),
                    topRight:
                        PatientRightSection(
                          config: config,
                          mode: workingMode,
                          isError: false,
                          isScaleDone: false,
                          patient: patient!,
                          image: "",
                          showBorder: false,
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
                              ? AppColors.lightGreen
                              : Colors.red.shade100,
                          image: "",
                          showBorder: false,
                          title: buildInstruction(isMeasurementDone, bpExceeded),
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

  Widget buildInstruction(bool isMeasurementDone, [bool bpExceeded = false]) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ⭐ ความดันเกินเกณฑ์ที่ตั้งไว้ → เตือนให้นั่งพักแล้ววัดซ้ำ (บันทึกปกติ)
        if (bpExceeded) ...[
          Text.rich(
            const TextSpan(
              style: TextStyle(
                fontFamily: 'THSarabunNew',
                fontWeight: FontWeight.bold,
              ),
              children: [
                TextSpan(
                  text: "หากค่าความดันโลหิต\n",
                  style: TextStyle(
                    color: AppColors.primaryGreen,
                    fontSize: 26,
                  ),
                ),
                TextSpan(
                  text: "ตัวบน",
                  style: TextStyle(
                    color: AppColors.primaryGreen,
                    fontSize: 26,
                  ),
                ),
                TextSpan(
                  text: "มากกว่า 140 ",
                  style: TextStyle(color: Colors.red, fontSize: 32),
                ),
                TextSpan(
                  text: "mmHg",
                  style: TextStyle(
                    color: AppColors.primaryGreen,
                    fontSize: 18,
                  ),
                ),
                TextSpan(
                  text: " หรือ\n",
                  style: TextStyle(
                    color: AppColors.primaryGreen,
                    fontSize: 26,
                  ),
                ),
                TextSpan(
                  text: "ตัวล่าง",
                  style: TextStyle(
                    color: AppColors.primaryGreen,
                    fontSize: 26,
                  ),
                ),
                TextSpan(
                  text: "มากกว่า 90 ",
                  style: TextStyle(color: Colors.red, fontSize: 32),
                ),
                TextSpan(
                  text: "mmHg\n",
                  style: TextStyle(
                    color: AppColors.primaryGreen,
                    fontSize: 18,
                  ),
                ),
                TextSpan(
                  text: "ให้นั่งพัก 15 นาที ",
                  style: TextStyle(color: Colors.red, fontSize: 26),
                ),
                TextSpan(
                  text: "แล้ววัดซ้ำ",
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 26,
                    decoration: TextDecoration.underline,
                    decorationColor: Colors.red,
                    decorationThickness: 2,
                  ),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
        ],
        Image.asset(
          'assets/images/right.png',
          width: 80,
          height: 80,
        ),
        const SizedBox(height: 8),
        Text(
          "บันทึกผลการวัดสำเร็จ",
          style: TextStyle(fontFamily: 'THSarabunNew', 
            color: AppColors.darkGreen,
            fontWeight: FontWeight.bold,
            fontSize: 40,
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          "ขอบคุณค่ะ",
          style: TextStyle(fontFamily: 'THSarabunNew', 
            color: AppColors.darkGreen,
            fontSize: 30,
          ),
          textAlign: TextAlign.center,
        ),
      ],

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
      showCard: false,
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
