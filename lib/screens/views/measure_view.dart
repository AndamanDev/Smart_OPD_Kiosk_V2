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
import 'widgets/kiosk_landscape_layout.dart';
import 'widgets/kiosk_portrait_layout.dart';
import 'widgets/kiosk_responsive_middle.dart';
import 'widgets/patient_right_section.dart';
import 'widgets/right_section.dart';
import 'widgets/square_image.dart';

class MeasureView extends StatefulWidget {
  const MeasureView({super.key});

  @override
  State<MeasureView> createState() => _MeasureViewState();
}

class _MeasureViewState extends State<MeasureView> {
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _controller = TextEditingController();
  final SerialServer _serialServer = SerialServer();
  String _scaleBuffer = "";
  bool _receivingScaleFrame = false;
  String _bpBuffer = "";
  String? _pendingScale;
  String? _pendingBp;
  Timer? _timeoutTimer;
  double? _currentWeight;
  double? _currentHeight;
  int? _currentSys;
  int? _currentDia;
  int _lastMeasureVersion = -1;
  Timer? _scanDebounce;

  @override
  void didUpdateWidget(covariant MeasureView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _ensureFocus();
    _controller.addListener(_onScanChanged);
  }

  void _onScanChanged() {
    _scanDebounce?.cancel();

    _scanDebounce = Timer(const Duration(milliseconds: 120), () {
      final value = _controller.text.trim();

      if (value.isNotEmpty) {
        _handleInput(value);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final kiosk = context.watch<KioskStageProvider>();

    if (kiosk.measureVersion != _lastMeasureVersion) {
      _lastMeasureVersion = kiosk.measureVersion;

      _restartSound();
    }
  }

  Future<void> _restartSound() async {
    final settings = context.read<SettingsProvider>();

    context.read<SoundServer>().stop();
    final mode = settings.workingMode;
    final deviceName = settings.scaleDevice.name;

    if (mode == WorkingMode.scaleOnly) {
      if (deviceName.contains("205")) {
        await context.read<SoundServer>().playAndWait(
          'sounds/start_BAM205.wav',
        );
      } else if (deviceName.contains("303")) {
        await context.read<SoundServer>().playAndWait(
          'sounds/start_BAM303.wav',
        );
      }
    } else if (mode == WorkingMode.bloodPressureOnly) {
      await context.read<SoundServer>().playAndWait(
        'sounds/bp_instruction_start.wav',
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _ensureFocus();
    _resetInternalState();
    _startTimeoutTimer();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      final settings = context.read<SettingsProvider>();
      final kiosk = context.read<KioskStageProvider>();
      final serial = context.read<SerialProvider>();

      serial.removeListener(_onDataReceived);
      serial.addListener(_onDataReceived);

      try {
        await context.read<SoundServer>().playAndWait('sounds/bell-98033.mp3');
      } catch (e) {
        debugPrint("Sound Error: $e");
      }

      if (!kiosk.isRetry) {
        _playInstructionSound(settings);
      }
    });
    _ensureFocus();
  }

  void _resetInternalState() {
    _scaleBuffer = "";
    _bpBuffer = "";
    _pendingScale = null;
    _pendingBp = null;
    _receivingScaleFrame = false;
    _currentWeight = null;
    _currentHeight = null;
    _currentSys = null;
    _currentDia = null;
  }

  Future<void> _playInstructionSound(SettingsProvider settings) async {
    if (!mounted) return;

    final mode = settings.workingMode;
    final deviceName = settings.scaleDevice.name;

    if (mode == WorkingMode.scaleOnly) {
      if (deviceName.contains("205")) {
        await context.read<SoundServer>().playAndWait(
          'sounds/start_BAM205.wav',
        );
      } else if (deviceName.contains("303")) {
        await context.read<SoundServer>().playAndWait(
          'sounds/start_BAM303.wav',
        );
      }
    } else if (mode == WorkingMode.bloodPressureOnly) {
      await context.read<SoundServer>().playAndWait(
        'sounds/bp_instruction_start.wav',
      );
    }
  }

  void _startTimeoutTimer() {
    final settings = context.read<SettingsProvider>();
    int delay = 200;

    if (settings.workingMode == WorkingMode.bloodPressureOnly) {
      delay = settings.delayBPSeconds;
    } else if (settings.workingMode == WorkingMode.scaleOnly) {
      delay = settings.delayScaleSeconds;
    } else if (settings.workingMode == WorkingMode.combined) {
      delay = 500;
    }

    _cancelTimeoutTimer();
    _timeoutTimer = Timer(Duration(seconds: delay), () {
      if (mounted) {
        debugPrint("Timeout: No data received. Resetting...");
        final serial = context.read<SerialProvider>();
        serial.stop();
        context.read<KioskStageProvider>().reset(serial);
      }
    });
  }

  void _cancelTimeoutTimer() {
    _timeoutTimer?.cancel();
  }

  void _onDataReceived() {
    if (!mounted) return;

    final serial = context.read<SerialProvider>();
    final settings = context.read<SettingsProvider>();
    final rawData = serial.lastData;

    if (rawData.isNotEmpty) {
      // ทำงานตาม Mode
      if (settings.workingMode == WorkingMode.scaleOnly) {
        _processScale(rawData);
      } else if (settings.workingMode == WorkingMode.bloodPressureOnly) {
        _processBp(rawData);
      } else if (settings.workingMode == WorkingMode.combined) {
        _processScale(rawData);
        _processBp(rawData);
      }
    }
  }

  void _processScale(String raw) {
    // ตรวจสอบ ASCII Control Characters
    for (var i = 0; i < raw.length; i++) {
      final code = raw.codeUnitAt(i);
      if (code == 0x02) {
        // STX
        _scaleBuffer = "";
        _receivingScaleFrame = true;
        continue;
      }
      if (code == 0x03 && _receivingScaleFrame) {
        // ETX
        _receivingScaleFrame = false;
        _handleScaleFrame(_scaleBuffer);
        _scaleBuffer = "";
        continue;
      }
      if (_receivingScaleFrame) {
        _scaleBuffer += String.fromCharCode(code);
      }
    }
  }

  void _handleScaleFrame(String frame) {
    try {
      if (frame.length < 41) return;

      final weightStr = frame.substring(1, 5);
      final heightStr = frame.substring(6, 11);
      final bmiStr = frame.substring(37, 41);

      final weight = (int.tryParse(weightStr) ?? 0) / 10;
      final height = (int.tryParse(heightStr) ?? 0) / 10;
      final bmi = (int.tryParse(bmiStr) ?? 0) / 10;

      if (weight <= 0) return;

      final raw = "SCALE,$weight,$height,$bmi";
      debugPrint("✅ SCALE PARSED: $raw");

      setState(() {
        _currentWeight = weight;
        _currentHeight = height;
      });

      _finalizeMeasurement(raw);

      final settings = context.read<SettingsProvider>();
      if (settings.workingMode == WorkingMode.combined) {
        context.read<SerialProvider>().switchPort(settings.bpPort);
        debugPrint("🔁 SWITCH → BP PORT");
        context.read<SoundServer>().playAndWait(
          'sounds/bp_instruction_start.wav',
        );
      }
    } catch (e) {
      debugPrint("Parsing Scale Error: $e");
    }
  }

  void _processBp(String raw) {
    _bpBuffer += raw;
    if (!_bpBuffer.contains('\n')) return;

    final lines = _bpBuffer.split('\n');
    _bpBuffer = lines.last;
    for (var i = 0; i < lines.length - 1; i++) {
      final packet = lines[i].trim();
      if (packet.isNotEmpty) {
        _handleBpPacket(packet);
      }
    }
  }

  void _handleBpPacket(String packet) {
    final parts = packet.split(',');

    debugPrint("✅ BP parts: $parts");

    // if (parts.length < 10) return;

    final sys = int.tryParse(parts[7].trim()) ?? 0;
    final dia = int.tryParse(parts[8].trim()) ?? 0;
    final pulse = int.tryParse(parts[9].trim()) ?? 0;

    // if (sys <= 0 || dia <= 0) return;

    if (sys == null || dia == null || sys <= 0 || dia <= 0) {
      debugPrint("❌ BP PARSE FAILED");

      context.read<KioskStageProvider>().setStage(KioskStage.measureError);

      return;
    }

    debugPrint("✅ BP PARSED: SYS:$sys DIA:$dia");

    setState(() {
      _currentSys = sys;
      _currentDia = dia;
    });

    _finalizeMeasurement(packet, isBp: true);
  }

  void _finalizeMeasurement(String rawData, {bool isBp = false}) {
    final settings = context.read<SettingsProvider>();

    if (settings.workingMode != WorkingMode.combined) {
      _commitAndFinish(rawData);
      return;
    }

    if (isBp) {
      _pendingBp = rawData;
    } else {
      _pendingScale = rawData;
    }

    if (_pendingScale != null || _pendingBp != null) {
      final merged = "${_pendingScale!}|${_pendingBp!}";
      _commitAndFinish(merged);
    }
  }

  void _commitAndFinish(String rawData) {
    context.read<SoundServer>().stop();
    final settings = context.read<SettingsProvider>();
    final patientProvider = context.read<PatientProvider>();
    final kiosk = context.read<KioskStageProvider>();
    final vitals = context.read<VitalsProvider>();

    patientProvider.setMeasurementError(false);
    patientProvider.setRawData(rawData);

    final patient = patientProvider.patient;
    final hn = patient?["HN"] ?? patient?["hn"];

    if (hn != null) {
      vitals.saveToVitals(
        hn: hn,
        rawVitals: rawData,
        settings: settings,
        auth: context.read<AuthProvider>(),
      );
    }

    if (settings.workingMode == WorkingMode.combined) {
      kiosk.setStage(KioskStage.resultCombined);
    } else {
      kiosk.setStage(KioskStage.result);
    }
  }

  void _ensureFocus() {
    if (!mounted) return;
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted && !_focusNode.hasFocus) {
        FocusScope.of(context).requestFocus(_focusNode);
        print("🎯 Focus requested after delay");
      }
    });
  }

  Future<void> _handleInput(String value) async {
    context.read<SoundServer>().stop();

    final hn = value.trim();
    if (hn.isEmpty) {
      _focusNode.requestFocus();
      return;
    }
    _controller.clear();
    _focusNode.requestFocus();

    final success = await context.read<PatientProvider>().fetchByHn(
      hn: hn,
      settings: context.read<SettingsProvider>(),
      auth: context.read<AuthProvider>(),
    );

    if (!mounted) return;
    if (success) {
      final serial = context.read<SerialProvider>();
      context.read<KioskStageProvider>().resetHn(serial, null);
    } else {
      context.read<KioskStageProvider>().setStage(KioskStage.scanError);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onScanChanged);
    context.read<SerialProvider>().removeListener(_onDataReceived);
    _cancelTimeoutTimer();
    _focusNode.dispose();
    _controller.dispose();
    context.read<SoundServer>().dispose();
    _serialServer.stop();
    super.dispose();
  }

  void _sendMockResult() {
    final settings = context.read<SettingsProvider>();
    final patientProvider = context.read<PatientProvider>();
    final kiosk = context.read<KioskStageProvider>();
    final vitals = context.read<VitalsProvider>();

    const mockScale = "SCALE,65.5,170.2,22.6";
    const mockBp = "BP,0,0,0,0,0,0,120,80,72";

    String mockRaw;

    if (settings.workingMode == WorkingMode.scaleOnly) {
      mockRaw = mockScale;
    } else if (settings.workingMode == WorkingMode.bloodPressureOnly) {
      mockRaw = mockBp;
    } else {
      mockRaw = "$mockScale|$mockBp";
    }

    patientProvider.setMeasurementError(false);
    patientProvider.setRawData(mockRaw);

    final patient = patientProvider.patient;
    final hn = patient?["HN"] ?? patient?["hn"];

    if (hn != null) {
      vitals.saveToVitals(
        hn: hn,
        rawVitals: mockRaw,
        settings: settings,
        auth: context.read<AuthProvider>(),
      );
    }

    if (settings.workingMode == WorkingMode.combined) {
      kiosk.setStage(KioskStage.resultCombined);
    } else {
      kiosk.setStage(KioskStage.result);
    }

    debugPrint("🚀 MOCK RESULT SENT ($mockRaw)");
  }

  @override
  Widget build(BuildContext context) {
    _ensureFocus();
    final workingMode = context.select<SettingsProvider, WorkingMode>(
      (s) => s.workingMode,
    );

    final settings = context.read<SettingsProvider>();
    final mode = settings.workingMode;
    final patient = context.watch<PatientProvider>().patient;
    final isShowBtn = settings.scaleDevice.name.contains("303");
    final isScale = mode == WorkingMode.scaleOnly;
    final isBp = mode == WorkingMode.bloodPressureOnly;
    final isCombined = mode == WorkingMode.combined;
    final isShow = settings.scaleDevice.name.contains("303");

    return LayoutBuilder(
      builder: (context, constraints) {
        final config = ResponsiveConfig(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
        );

        return GestureDetector(
          onTap: _ensureFocus,
          // onDoubleTap: _sendMockResult,
          behavior: HitTestBehavior.opaque,
          child: Stack(
            children: [
              Positioned.fill(
                child: KioskResponsiveMiddle(
                  config: config,

                  // ---------------- PORTRAIT ----------------
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
                    middle: ModeSquareImage(
                      mode: workingMode,
                      isError: false,
                      isScaleDone: false,
                    ),
                    bottom: RightSection(
                      config: config,
                      mode: workingMode,
                      isError: false,
                      isScaleDone: false,
                      isBorder: false,
                      isColorError: Colors.transparent,
                      image: "",
                      title: Text.rich(
                        TextSpan(
                          style: GoogleFonts.kanit(),
                          children: [
                            TextSpan(
                              text: isScale
                                  ? "กรุณาขึ้นเครื่องชั่งน้ำหนักและวัดส่วนสูง\n"
                                  : isBp
                                  ? "กรุณานั่งและสอดแขนตามตำแหน่ง\n"
                                  : isCombined
                                  ? "กรุณาขึ้นเครื่องชั่งน้ำหนักและวัดส่วนสูง\n"
                                  : "กรุณานั่งและสอดแขนตามตำแหน่ง\n",
                              style: TextStyle(color: Colors.black),
                            ),

                            TextSpan(
                              text: isScale
                                  ? "เพื่อเริ่มทำการวัด"
                                  : isBp
                                  ? "แล้วกดปุ่มเริ่มที่ตัวเครื่อง"
                                  : isCombined
                                  ? "เพื่อเริ่มทำการวัด"
                                  : "แล้วกดปุ่มเริ่มที่ตัวเครื่อง",
                              style: TextStyle(color: Colors.black),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      text: "",
                    ),
                    bottomTop: null,
                  ),

                  // ---------------- LANDSCAPE ----------------
                  landscape: KioskLandscapeLayout(
                    config: config,
                    left: ModeSquareImage(
                      mode: workingMode,
                      isError: false,
                      isScaleDone: false,
                    ),
                    topRight:
                        PatientRightSection(
                          config: config,
                          mode: workingMode,
                          isError: false,
                          isScaleDone: false,
                          patient: patient!,
                          image: "",
                        ).animate().slideY(
                          begin: -0.5, // มาจากด้านบน
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
                          isColorError: Colors.transparent,
                          image: "",
                          title: Text.rich(
                            TextSpan(
                              style: GoogleFonts.kanit(),
                              children: [
                                TextSpan(
                                  text: isScale
                                      ? "กรุณาขึ้นเครื่องชั่งน้ำหนักและวัดส่วนสูง\n"
                                      : isBp
                                      ? "กรุณานั่งและสอดแขนตามตำแหน่ง\n"
                                      : isCombined
                                      ? "กรุณาขึ้นเครื่องชั่งน้ำหนักและวัดส่วนสูง\n"
                                      : "กรุณานั่งและสอดแขนตามตำแหน่ง\n",
                                  style: TextStyle(color: Colors.black),
                                ),

                                TextSpan(
                                  text: isScale
                                      ? "เพื่อเริ่มทำการวัด"
                                      : isBp
                                      ? "แล้วกดปุ่มเริ่มที่ตัวเครื่อง"
                                      : isCombined
                                      ? "เพื่อเริ่มทำการวัด"
                                      : "แล้วกดปุ่มเริ่มที่ตัวเครื่อง",
                                  style: TextStyle(color: Colors.black),
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
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
              Positioned(
                top: 20,
                left: 20,
                right: 20,
                child: Opacity(
                  opacity: 0,
                  child: Material(
                    elevation: 8,
                    borderRadius: BorderRadius.circular(12),
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      decoration: InputDecoration(
                        hintText: "Scan",
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onSubmitted: _handleInput,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
