import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/responsive/responsive_config.dart';
import '../../core/theme/app_theme.dart';
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

class ResultCombinedView extends StatefulWidget {
  const ResultCombinedView({super.key});

  @override
  State<ResultCombinedView> createState() => _ResultCombinedViewState();
}

class _ResultCombinedViewState extends State<ResultCombinedView> {
  final SerialServer _server = SerialServer();

  String _bpBuffer = "";
  bool _listeningBp = false;

  bool _flowFinished = false;

  Timer? _timeoutTimer;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final kiosk = context.read<KioskStageProvider>();
      final patientProvider = context.read<PatientProvider>();
      final serial = context.read<SerialProvider>();
      final settings = context.read<SettingsProvider>();

      final raw = patientProvider.rawVitalsData;

      String bpRaw = "";
      if (raw.contains("|")) {
        bpRaw = raw.split("|")[1];
      }

      final bp = BloodPressureUtils.parseByDevice(bpRaw, settings.bpDevice);
      final bool isBpDone = bp.systolic > 0;

      if (!kiosk.isRetry) {
        if (!isBpDone) {
          await context.read<SoundServer>().playAndWait(
            'sounds/wt_finish_next_bp.wav',
          );
        }
      }

      if (!isBpDone) {
        serial.switchPort(settings.bpPort);

        serial.removeListener(_onSerial);
        serial.addListener(_onSerial);

        _listeningBp = true;
      } else {
        // await _finishFlow();
      }

      _startTimeout();
    });
  }

  void _startTimeout() {
    final settings = context.read<SettingsProvider>();
    int delay = 200;

    if (settings.workingMode == WorkingMode.bloodPressureOnly) {
      delay = settings.delayBPSeconds;
    } else if (settings.workingMode == WorkingMode.scaleOnly) {
      delay = settings.delayScaleSeconds;
    } else if (settings.workingMode == WorkingMode.combined) {
      // delay = settings.delayBPSeconds + settings.delayScaleSeconds;
      delay = settings.delayBPSeconds;
    }

    _cancelTimeoutTimer();
    _timeoutTimer = Timer(Duration(seconds: delay), () {
      if (!mounted) return;
      final serial = context.read<SerialProvider>();
      serial.stop();
      context.read<KioskStageProvider>().reset(serial);
    });
  }

  void _cancelTimeoutTimer() {
    _timeoutTimer?.cancel();
  }

  void _onSerial() {
    if (!_listeningBp) return;

    final raw = context.read<SerialProvider>().lastData;
    if (raw.isEmpty) return;

    _bpBuffer += raw;

    if (!_bpBuffer.contains('\n')) return;

    final lines = _bpBuffer.split('\n');
    _bpBuffer = lines.last;

    for (int i = 0; i < lines.length - 1; i++) {
      _handleBp(lines[i].trim());
    }
  }

  void _goError() {
    if (_flowFinished) return;
    _flowFinished = true;

    if (!mounted) return;

    final serial = context.read<SerialProvider>();

    serial.removeListener(_onSerial);
    serial.stop();

    context.read<KioskStageProvider>().setStage(
      KioskStage.measureCombinedError,
    );
  }

  void _handleBp(String packet) async {

    final kiosk = context.read<KioskStageProvider>();
    final settings = context.read<SettingsProvider>();


    if (_flowFinished) return;

    // ⭐ parse ตามรุ่นเครื่อง (รองรับ Terumo ที่อ่านคนละตำแหน่งกับ AND/Omron)
    final reading = BloodPressureUtils.parseByDevice(packet, settings.bpDevice);
    final sys = reading.systolic;
    final dia = reading.diastolic;
    final pulse = reading.pulse;

    if (sys <= 0 || dia <= 0 || pulse <= 0) {
      _goError();
      return;
    }

    final patientProvider = context.read<PatientProvider>();

    String scalePart = patientProvider.rawVitalsData;
    if (scalePart.contains("|")) {
      scalePart = scalePart.split("|")[0];
    }
    final merged = "$scalePart|$packet";

    patientProvider.setRawData(merged);

    final hn = patientProvider.patient?["HN"] ?? patientProvider.patient?["hn"];

    final vitals = context.read<VitalsProvider>();
    final auth = context.read<AuthProvider>();
    if (hn != null) {
    final success =   await vitals.saveToVitals(
        hn: hn,
        rawVitals: merged,
        settings: settings,
        auth: auth,
      );

print("Save Vitals Success: $success");

       if (!success) {
        kiosk.setStage(KioskStage.combinedsavemeasureError);
        return;
      }
    }

    _listeningBp = false;
    _flowFinished = true;

    context.read<SerialProvider>().removeListener(_onSerial);
    await _finishFlow();
  }

  // แยกค่าความดันจาก raw (โหมดรวม raw = "scale|bp") แล้ว parse ตามรุ่นเครื่อง
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
  bool _isBpExceeded(SettingsProvider settings, PatientProvider patient) {
    final bp = _parseBp(settings, patient);
    if (bp.systolic <= 0) return false;
    return (settings.bpRefSys > 0 && bp.systolic > settings.bpRefSys) ||
        (settings.bpRefDia > 0 && bp.diastolic > settings.bpRefDia);
  }

  Future<void> _finishFlow() async {
    final bool bpExceeded = _isBpExceeded(
      context.read<SettingsProvider>(),
      context.read<PatientProvider>(),
    );

    if (bpExceeded) {
      // ⭐ ความดันเกินเกณฑ์ → error + เสียงเตือนให้นั่งพัก (แทนเสียงบันทึกสำเร็จปกติ)
      await context.read<SoundServer>().playAndWait('sounds/error-126627.mp3');
      if (!mounted) return;
      await context.read<SoundServer>().playAndWait(
        'sounds/bp_warnning_voice.wav',
      );
    } else {
      await context.read<SoundServer>().playAndWait('sounds/bell-98033.mp3');
      await context.read<SoundServer>().playAndWait('sounds/save_finished.wav');
    }

    if (!mounted) return;

    // ค้างจอต่ออีก 8 วิ หลังเสียงเล่นจบ (ให้ผู้ป่วยอ่านผลทัน)
    await Future.delayed(const Duration(seconds: 8));

    if (!mounted) return;

    final serial = context.read<SerialProvider>();
    serial.stop();

    context.read<KioskStageProvider>().clearRetry();
    context.read<KioskStageProvider>().reset(serial);
    context.read<PatientProvider>().setRawData("");
  }

  @override
  void dispose() {
    context.read<SerialProvider>().removeListener(_onSerial);
    context.read<SoundServer>().stop();
    context.read<SoundServer>().dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final workingMode = context.select<SettingsProvider, WorkingMode>(
      (s) => s.workingMode,
    );
    final patientProvider = context.watch<PatientProvider>();
    final raw = patientProvider.rawVitalsData;
    final patient = patientProvider.patient;
    final settings = context.watch<SettingsProvider>();

    String scaleRaw = "";
    String bpRaw = "";

    if (raw.contains("|")) {
      final parts = raw.split("|");
      scaleRaw = parts[0];
      bpRaw = parts[1];
    } else {
      scaleRaw = raw;
    }

    final scale = ScaleUtils.parse(scaleRaw);
    // ⭐ ใช้ parser ตามรุ่นเครื่องที่ตั้งไว้ (เช่น Terumo อ่านคนละตำแหน่งกับ default)
    final bp = BloodPressureUtils.parseByDevice(bpRaw, settings.bpDevice);

    final bool isBpDone = bp.systolic > 0;
    final bool doneScale = scale.weight > 0;
    final bool doneBp = bp.systolic > 0;

    // ---------- เทียบกับค่าอ้างอิงความดัน (ถ้าตั้งไว้) ----------
    // เกินเกณฑ์เมื่อ SYS หรือ DIA ที่วัดได้ มากกว่าค่าอ้างอิงที่กำหนด
    final bool bpExceeded = doneBp &&
        ((settings.bpRefSys > 0 && bp.systolic > settings.bpRefSys) ||
            (settings.bpRefDia > 0 && bp.diastolic > settings.bpRefDia));

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      child: LayoutBuilder(
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
                        isError: !isBpDone ? true : false,
                        isScaleDone: false,
                        isBorder: !isBpDone ? true : false,
                        isColorError: isMeasurementDone
                            ? AppColors.lightGreen
                            : Colors.red.shade100,
                        image: "",
                        showBorder: false,
                        title: isBpDone
                            ? Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // ⭐ ความดันเกินเกณฑ์ → เตือนให้นั่งพักแล้ววัดซ้ำ (บันทึกปกติ)
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
                                            style: TextStyle(color: AppColors.primaryGreen, fontSize: 20),
                                          ),
                                          TextSpan(
                                            text: "ตัวบน",
                                            style: TextStyle(color: AppColors.primaryGreen, fontSize: 20),
                                          ),
                                          TextSpan(
                                            text: "มากกว่า 140 ",
                                            style: TextStyle(color: Colors.red, fontSize: 24),
                                          ),
                                          TextSpan(
                                            text: "mmHg",
                                            style: TextStyle(color: AppColors.primaryGreen, fontSize: 15),
                                          ),
                                          TextSpan(
                                            text: " หรือ\n",
                                            style: TextStyle(color: AppColors.primaryGreen, fontSize: 20),
                                          ),
                                          TextSpan(
                                            text: "ตัวล่าง",
                                            style: TextStyle(color: AppColors.primaryGreen, fontSize: 20),
                                          ),
                                          TextSpan(
                                            text: "มากกว่า 90 ",
                                            style: TextStyle(color: Colors.red, fontSize: 24),
                                          ),
                                          TextSpan(
                                            text: "mmHg\n",
                                            style: TextStyle(color: AppColors.primaryGreen, fontSize: 15),
                                          ),
                                          TextSpan(
                                            text: "ให้นั่งพัก 15 นาที ",
                                            style: TextStyle(color: Colors.red, fontSize: 20),
                                          ),
                                          TextSpan(
                                            text: "แล้ววัดซ้ำ",
                                            style: TextStyle(
                                              color: Colors.red,
                                              fontSize: 20,
                                              decoration: TextDecoration.underline,
                                              decorationColor: Colors.red,
                                              decorationThickness: 2,
                                            ),
                                          ),
                                        ],
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 10),
                                  ],
                                  Icon(Icons.check_circle_rounded, color: AppColors.primaryGreen, size: 48),
                                  const SizedBox(height: 8),
                                  Text("บันทึกผลการวัดสำเร็จ",
                                    style: TextStyle(fontFamily: 'THSarabunNew', color: AppColors.primaryGreen, fontWeight: FontWeight.bold, fontSize: 28),
                                    textAlign: TextAlign.center,
                                  ),
                                  Text("ขอบคุณค่ะ",
                                    style: TextStyle(fontFamily: 'THSarabunNew', color: AppColors.primaryGreen, fontSize: 24),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              )
                            : Text.rich(
                                TextSpan(
                                  style: const TextStyle(fontFamily: 'THSarabunNew'),
                                  children: [
                                    TextSpan(text: "กรุณาวัดความดัน\n", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                                    TextSpan(text: "นั่งสอดแขนวางแขนให้ได้ตำแหน่ง\n", style: TextStyle(color: Colors.grey[800])),
                                    TextSpan(text: "แล้วกดปุ่มเริ่มที่ตัวเครื่อง", style: TextStyle(color: Colors.grey[800])),
                                  ],
                                ),
                                textAlign: TextAlign.center,
                              ),
                        text: "",
                      ).animate().fade(duration: 500.ms, curve: Curves.easeIn),
                      bottomTop: null,
                    ),

                    landscape: KioskLandscapeLayout(
                      config: config,
                      combineRight: true,
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
                      bottomRight: RightSection(
                        config: config,
                        mode: workingMode,
                        isError: !isBpDone ? true : false,
                        isScaleDone: false,
                        isBorder: !isBpDone ? true : false,
                        isColorError: isMeasurementDone
                            ? AppColors.lightGreen
                            : Colors.red.shade100,
                        image: "",
                        showBorder: false,
                        title: isBpDone
                            ? Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // ⭐ ความดันเกินเกณฑ์ → เตือนให้นั่งพักแล้ววัดซ้ำ (บันทึกปกติ)
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
                                            style: TextStyle(color: AppColors.primaryGreen, fontSize: 20),
                                          ),
                                          TextSpan(
                                            text: "ตัวบน",
                                            style: TextStyle(color: AppColors.primaryGreen, fontSize: 20),
                                          ),
                                          TextSpan(
                                            text: "มากกว่า 140 ",
                                            style: TextStyle(color: Colors.red, fontSize: 24),
                                          ),
                                          TextSpan(
                                            text: "mmHg",
                                            style: TextStyle(color: AppColors.primaryGreen, fontSize: 15),
                                          ),
                                          TextSpan(
                                            text: " หรือ\n",
                                            style: TextStyle(color: AppColors.primaryGreen, fontSize: 20),
                                          ),
                                          TextSpan(
                                            text: "ตัวล่าง",
                                            style: TextStyle(color: AppColors.primaryGreen, fontSize: 20),
                                          ),
                                          TextSpan(
                                            text: "มากกว่า 90 ",
                                            style: TextStyle(color: Colors.red, fontSize: 24),
                                          ),
                                          TextSpan(
                                            text: "mmHg\n",
                                            style: TextStyle(color: AppColors.primaryGreen, fontSize: 15),
                                          ),
                                          TextSpan(
                                            text: "ให้นั่งพัก 15 นาที ",
                                            style: TextStyle(color: Colors.red, fontSize: 20),
                                          ),
                                          TextSpan(
                                            text: "แล้ววัดซ้ำ",
                                            style: TextStyle(
                                              color: Colors.red,
                                              fontSize: 20,
                                              decoration: TextDecoration.underline,
                                              decorationColor: Colors.red,
                                              decorationThickness: 2,
                                            ),
                                          ),
                                        ],
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 10),
                                  ],
                                  Icon(Icons.check_circle_rounded, color: AppColors.primaryGreen, size: 48),
                                  const SizedBox(height: 8),
                                  Text("บันทึกผลการวัดสำเร็จ",
                                    style: TextStyle(fontFamily: 'THSarabunNew', color: AppColors.primaryGreen, fontWeight: FontWeight.bold, fontSize: 28),
                                    textAlign: TextAlign.center,
                                  ),
                                  Text("ขอบคุณค่ะ",
                                    style: TextStyle(fontFamily: 'THSarabunNew', color: AppColors.primaryGreen, fontSize: 24),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              )
                            : Text.rich(
                                TextSpan(
                                  style: const TextStyle(fontFamily: 'THSarabunNew'),
                                  children: [
                                    TextSpan(text: "กรุณาวัดความดัน\n", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                                    TextSpan(text: "นั่งสอดแขนวางแขนให้ได้ตำแหน่ง\n", style: TextStyle(color: Colors.grey[800])),
                                    TextSpan(text: "แล้วกดปุ่มเริ่มที่ตัวเครื่อง", style: TextStyle(color: Colors.grey[800])),
                                  ],
                                ),
                                textAlign: TextAlign.center,
                              ),
                        text: "",
                      ).animate().fade(duration: 500.ms, curve: Curves.easeIn),
                      bottomTop: null,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
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

  Widget buildInstruction(bool isMeasurementDone) {
    return Text.rich(
      TextSpan(
        style: const TextStyle(fontFamily: 'THSarabunNew'),
        children: [
          TextSpan(
            text: "บันทึกผลการวัดสำเร็จ\n",
            style: TextStyle(
              color: AppColors.darkGreen,
              fontWeight: FontWeight.bold,
            ),
          ),
          TextSpan(
            text: "ขอบคุณค่ะ",
            style: TextStyle(color: AppColors.darkGreen),
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
