import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/responsive/responsive_config.dart';
import '../../providers/patient_provider.dart';
import '../../models/working_mode.dart';
import '../../providers/auth_provider.dart';
import '../../providers/kiosk_state_provider.dart';
import '../../providers/patient_provider.dart';
import '../../providers/settings_provider.dart';
import 'widgets/kiosk_landscape_layout.dart';
import 'widgets/kiosk_portrait_layout.dart';
import 'widgets/kiosk_responsive_middle.dart';
import 'widgets/right_section.dart';
import 'widgets/square_image.dart';

class ScanView extends StatefulWidget {
  const ScanView({super.key});

  @override
  State<ScanView> createState() => _ScanViewState();
}

class _ScanViewState extends State<ScanView> {
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _controller = TextEditingController();
  Timer? _scanDebounce;

  @override
  void initState() {
    super.initState();
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
  void dispose() {
    _controller.removeListener(_onScanChanged);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _ensureFocus() {
    if (!mounted) return;
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted && !_focusNode.hasFocus) {
        FocusScope.of(context).requestFocus(_focusNode);
      }
    });
  }

  Future<void> _handleInput(String value) async {
    final hn = value.trim();
    if (hn.isEmpty) return;

    _controller.clear();
    _focusNode.requestFocus();

    final success = await context.read<PatientProvider>().fetchByHn(
      hn: hn,
      settings: context.read<SettingsProvider>(),
      auth: context.read<AuthProvider>(),
    );

    if (!mounted) return;

    final kiosk = context.read<KioskStageProvider>();
    final settings = context.read<SettingsProvider>();

    kiosk.setStage(
      success
          ? (settings.workingMode == WorkingMode.combined
                ? KioskStage.measureCombined
                : KioskStage.measure)
          : KioskStage.scanError,
    );
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

        return GestureDetector(
          onTap: _ensureFocus,
          behavior: HitTestBehavior.opaque,
          child: Stack(
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
                      image: 'assets/images/qr_scan_illustration.png',
                      title: Text.rich(
                        TextSpan(
                          style: GoogleFonts.kanit(),
                          children: [
                            TextSpan(
                              text: "กรุณาสแกน QR Code\n",
                              style: TextStyle(color: Colors.black87),
                            ),
                            TextSpan(
                              text: "เพื่อเริ่มการวัด",
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      text: "",
                    ),
                    bottomTop: ImageRightSection(
                      config: config,
                      mode: workingMode,
                      isError: false,
                      isScaleDone: false,
                      isBorder: false,
                      isColorError: Colors.transparent,
                      image: 'assets/images/qr_scan_illustration.png',
                      title: Text.rich(
                        TextSpan(
                          style: GoogleFonts.kanit(),
                          children: [
                            TextSpan(
                              text: "กรุณาสแกน QR Code\n",
                              style: TextStyle(color: Colors.black87),
                            ),
                            TextSpan(
                              text: "เพื่อเริ่มการวัด",
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      text: "",
                    ),
                  ),

                  // ---------------- LANDSCAPE ----------------
                  landscape: KioskLandscapeLayout(
                    config: config,
                    left: ModeSquareImage(
                      mode: workingMode,
                      isError: false,
                      isScaleDone: false,
                    ),
                    topRight: null,
                    bottomRight: RightSection(
                      config: config,
                      mode: workingMode,
                      isError: false,
                      isScaleDone: false,
                      isBorder: false,
                      isColorError: Colors.transparent,
                      image: 'assets/images/qr_scan_illustration.png',
                      title: Text.rich(
                        TextSpan(
                          style: GoogleFonts.kanit(),
                          children: [
                            TextSpan(
                              text: "กรุณาสแกน QR Code\n",
                              style: TextStyle(color: Colors.black87),
                            ),
                            TextSpan(
                              text: "เพื่อเริ่มการวัด",
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      text: "",
                    ),
                    bottomTop: ImageRightSection(
                      config: config,
                      mode: workingMode,
                      isError: false,
                      isScaleDone: false,
                      isBorder: false,
                      isColorError: Colors.transparent,
                      image: 'assets/images/qr_scan_illustration.png',
                      title: Text.rich(
                        TextSpan(
                          style: GoogleFonts.kanit(),
                          children: [
                            TextSpan(
                              text: "กรุณาสแกน QR Code\n",
                              style: TextStyle(color: Colors.black87),
                            ),
                            TextSpan(
                              text: "เพื่อเริ่มการวัด",
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      text: "",
                    ),
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
