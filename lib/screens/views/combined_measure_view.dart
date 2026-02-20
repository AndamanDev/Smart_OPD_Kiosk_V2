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

class CombinedMeasureView extends StatefulWidget {
  const CombinedMeasureView({super.key});

  @override
  State<CombinedMeasureView> createState() => _CombinedMeasureViewState();
}

class _CombinedMeasureViewState extends State<CombinedMeasureView> {
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _controller = TextEditingController();
  String _scaleBuffer = "";
  bool _receivingScaleFrame = false;
  bool _isScaleDone = false;
  double? _weight;
  double? _height;
  Timer? _timeoutTimer;
  int _lastMeasureVersion = -1;
  Timer? _scanDebounce;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final kiosk = context.watch<KioskStageProvider>();

    if (kiosk.measureVersion != _lastMeasureVersion) {
      _lastMeasureVersion = kiosk.measureVersion;

      _restartSound();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onScanChanged);
    context.read<SerialProvider>().removeListener(_onData);
    _focusNode.dispose();
    _controller.dispose();
    _timeoutTimer?.cancel();
    context.read<SoundServer>().stop();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant CombinedMeasureView oldWidget) {
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

  Future<void> _restartSound() async {
    context.read<SoundServer>().stop();
    await context.read<SoundServer>().playAndWait('sounds/start_BAM205.wav');
  }

  void _ensureFocus() {
    if (!mounted) return;

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted && !_focusNode.hasFocus) {
        FocusScope.of(context).requestFocus(_focusNode);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _ensureFocus();
    _controller.addListener(_onScanChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final serial = context.read<SerialProvider>();
      serial.removeListener(_onData);
      serial.addListener(_onData);
      await context.read<SoundServer>().playAndWait('sounds/start_BAM205.wav');
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
      delay = settings.delayScaleSeconds;
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

  void _onData() {
    if (!mounted) return;
    final raw = context.read<SerialProvider>().lastData;
    if (raw.isEmpty) return;

    if (!_isScaleDone) {
      _processScale(raw);
    }
  }

  void _processScale(String raw) {
    for (var i = 0; i < raw.length; i++) {
      final code = raw.codeUnitAt(i);

      if (code == 0x02) {
        _scaleBuffer = "";
        _receivingScaleFrame = true;
        continue;
      }

      if (code == 0x03 && _receivingScaleFrame) {
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

  Future<void> _handleInput(String value) async {
    context.read<SoundServer>().stop();

    final settings = context.read<SettingsProvider>();

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
      context.read<KioskStageProvider>().resetHn(
        serial,
        settings.workingMode == WorkingMode.combined,
      );
    } else {
      context.read<KioskStageProvider>().setStage(KioskStage.scanError);
    }
  }

  void _handleScaleFrame(String frame) {
    context.read<SoundServer>().stop();
    print("RAW FRAME => $frame");
    if (frame.length < 41) return;
    final w = (int.tryParse(frame.substring(1, 5)) ?? 0) / 10;
    final h = (int.tryParse(frame.substring(6, 11)) ?? 0) / 10;
    final bmi = (int.tryParse(frame.substring(37, 41)) ?? 0) / 10;
    if (w <= 0) return;
    final scaleString = "SCALE,$w,$h,$bmi";
    context.read<PatientProvider>().setRawData(scaleString);

    setState(() {
      _weight = w;
      _height = h;
      _isScaleDone = true;
    });
    context.read<KioskStageProvider>().setStage(KioskStage.resultCombined);
  }


void _sendMockCombined() {
  context.read<SoundServer>().stop();

  // mock ค่า
  const double mockWeight = 65.5;
  const double mockHeight = 170.2;
  const double mockBmi = 22.6;

  final scaleString = "SCALE,$mockWeight,$mockHeight,$mockBmi";

  context.read<PatientProvider>().setRawData(scaleString);

  setState(() {
    _weight = mockWeight;
    _height = mockHeight;
    _isScaleDone = true;
  });

  context.read<KioskStageProvider>().setStage(KioskStage.resultCombined);

  debugPrint("🚀 MOCK COMBINED SENT => $scaleString");
}

  @override
  Widget build(BuildContext context) {
    _ensureFocus();
    final workingMode = context.select<SettingsProvider, WorkingMode>(
      (s) => s.workingMode,
    );
    final settings = context.read<SettingsProvider>();
    final patient = context.watch<PatientProvider>().patient;
    final isShowBtn = settings.scaleDevice.name.contains("303");

    return LayoutBuilder(
      builder: (context, constraints) {
        final config = ResponsiveConfig(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
        );

        return GestureDetector(
          onTap: _ensureFocus,
          // onDoubleTap: _sendMockCombined,
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
                          begin: -0.5, // มาจากด้านบน
                          end: 0,
                          duration: 500.ms,
                          curve: Curves.easeOut,
                        ),
                    middle: ModeSquareImage(
                      mode: workingMode,
                      isError: false,
                      isScaleDone: false,
                    ),
                    bottom:
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
                                  text:
                                      "กรุณาขึ้นเครื่องชั่งน้ำหนักและวัดส่วนสูง\n",
                                  style: TextStyle(color: Colors.black),
                                ),

                                TextSpan(
                                  text:
                                      "แล้วกดปุ่มเริ่มบนหน้าจอ เพื่อเริ่มทำการวัด",
                                  style: TextStyle(color: Colors.black),
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          text: "",
                        ).animate().slideY(
                          begin: 0.5, // มาจากด้านบน
                          end: 0,
                          duration: 500.ms,
                          curve: Curves.easeOut,
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
                                  text:
                                      "กรุณาขึ้นเครื่องชั่งน้ำหนักและวัดส่วนสูง\n",
                                  style: TextStyle(color: Colors.black),
                                ),

                                TextSpan(
                                  text:
                                      "แล้วกดปุ่มเริ่มบนหน้าจอ เพื่อเริ่มทำการวัด",
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
