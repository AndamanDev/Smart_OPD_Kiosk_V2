import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_opd_kiosk_v2_vertical/screens/views/combined_save_measure_error_view.dart';

import '../auth_guard.dart';
import '../core/responsive/responsive_config.dart';
import '../providers/kiosk_state_provider.dart';
import '../providers/serial_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';

import 'setting_screen.dart';
import 'views/combined_measure_error_view.dart';
import 'views/combined_measure_view.dart';
import 'views/loading_new_view.dart';
import 'views/login_error_view.dart';
import 'views/measure_error_view.dart';
import 'views/measure_view.dart';
import 'views/save_measure_error_view.dart';
import 'views/port_error_view.dart';
import 'views/result_combined_view.dart';
import 'views/result_view.dart';
import 'views/scan_error_view.dart';
import 'views/scan_view.dart';
import 'views/widgets/kiosk_bottom_bar.dart';
import 'views/widgets/kiosk_top_section.dart';

class HomeKioskScreen extends StatefulWidget {
  const HomeKioskScreen({super.key});

  @override
  State<HomeKioskScreen> createState() => _HomeKioskScreenState();
}

class _HomeKioskScreenState extends State<HomeKioskScreen> {
  bool _initializing = false;
  bool _recovering = false; // กัน loop เด้งรัวระหว่าง scan ↔ portError

  final FocusNode _scanFocusNode = FocusNode();
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  /// ===============================
  /// INITIALIZE APP
  /// ===============================
  Future<void> _initializeApp() async {
    if (_initializing) return;
    _initializing = true;

    if (!mounted) return;

    final settings = context.read<SettingsProvider>();
    final auth = context.read<AuthProvider>();
    final kiosk = context.read<KioskStageProvider>();

    kiosk.setStage(KioskStage.loading);

    try {
      await auth.logout();

      /// init serial
      context.read<SerialProvider>().init(settings, kiosk);

      /// login ครั้งแรก
      final success = await AuthGuard.ensureLogin(context);

      if (!mounted) return;

      if (success) {
        kiosk.setStage(KioskStage.scan);
      }
    } catch (e) {
      debugPrint("Init Error: $e");
      kiosk.setStage(KioskStage.loginError);
    }

    _initializing = false;
  }

  /// ===============================
  /// BUILD
  /// ===============================
  @override
  Widget build(BuildContext context) {
    final stage = context.watch<KioskStageProvider>().stage;
    final serial = context.watch<SerialProvider>();
    final auth = context.watch<AuthProvider>();
    final kiosk = context.watch<KioskStageProvider>();

    /// ✅ auto recover port error (debounce กัน loop เด้งรัวระหว่าง scan ↔ portError)
    ///    Android isConnected กระพริบได้ → หน่วงเวลาแล้วเช็คซ้ำก่อนเปลี่ยนหน้า
    if (stage == KioskStage.portError &&
        serial.isConnected &&
        auth.token != null &&
        !auth.isTokenExpired &&
        !_recovering) {
      _recovering = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await Future.delayed(const Duration(milliseconds: 800));
        // เปลี่ยนเป็น scan เฉพาะเมื่อ "ยัง portError และต่อ port ได้จริง" หลังหน่วงเวลา
        if (mounted &&
            kiosk.stage == KioskStage.portError &&
            serial.isConnected) {
          kiosk.setStage(KioskStage.scan);
        }
        _recovering = false;
      });
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final config = ResponsiveConfig(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
        );

        final showChrome = stage != KioskStage.settings;
        final settings = context.read<SettingsProvider>();


        // return Scaffold(
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            if (!_scanFocusNode.hasFocus) {
              _scanFocusNode.requestFocus();
            }
          },
          child: Scaffold(
            backgroundColor: Colors.white,
            resizeToAvoidBottomInset: false,
            body: MediaQuery.removePadding(
              context: context,
              removeTop: true,
              removeBottom: true,
              removeLeft: true,
              removeRight: true,
              child: Column(
                children: [
                  if (showChrome)
                    Expanded(
                      flex: 2,
                      child: KioskTopSection(
                        config: config,
                        // rightImage: 'assets/images/hospital_logo_new.png',
                        rightImage: settings.hospitalLogoPath.isNotEmpty
                            ? settings.hospitalLogoPath
                            : 'assets/images/hospital_logo_new.png',
                      ),
                    ),

                  Expanded(flex: 7, child: _buildByStage(stage)),

                  const SizedBox(height: 8),

                  if (showChrome)
                    Expanded(
                      flex: 1,
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: KioskBottomBar(config: config,),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// ===============================
  /// STAGE ROUTER
  /// ===============================
  Widget _buildByStage(KioskStage stage) {
    final serial = context.read<SerialProvider>();
    final settings = context.read<SettingsProvider>();
    final kiosk = context.read<KioskStageProvider>();

    switch (stage) {
      /// -------------------------
      case KioskStage.loading:
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _initializeApp();
        });
        return const Center(child: CircularProgressIndicator());

              case KioskStage.loadingNew:
        return const LoadingNewView();


      /// -------------------------
      case KioskStage.settings:
        return const SettingsScreen();

      /// -------------------------
      case KioskStage.loginError:
        return const LoginErrorView();

      /// -------------------------
      case KioskStage.portError:
        return const PortErrorView();

      /// -------------------------
      case KioskStage.scan:
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          final ok = await AuthGuard.ensureLogin(context);
          if (!ok) return;

          if (!serial.isConnected) {
            serial.init(settings, kiosk);
          }

          if (mounted) {
            _scanFocusNode.requestFocus();
          }
        });

        return ScanView(focusNode: _scanFocusNode);

      /// -------------------------
      case KioskStage.scanError:
        return const ScanErrorView();

      /// -------------------------
      case KioskStage.measure:
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          await AuthGuard.ensureLogin(context);
        });

        return MeasureView(key: ValueKey(kiosk.measureVersion) , focusNode: _scanFocusNode);

      /// -------------------------
      case KioskStage.measureCombined:
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          await AuthGuard.ensureLogin(context);
        });

        return CombinedMeasureView(focusNode: _scanFocusNode,);

      /// -------------------------
      case KioskStage.measureError:
        return const MeasureErrorView();

      case KioskStage.savemeasureError:
        return const SaveMeasureErrorView();

      case KioskStage.combinedsavemeasureError:
        return const CombinedSaveMeasureErrorView();

      /// -------------------------
      case KioskStage.measureCombinedError:
        return const MeasureCombinedErrorView();

      /// -------------------------
      case KioskStage.result:
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          await AuthGuard.ensureLogin(context);
        });

        return const ResultView();

      /// -------------------------
      case KioskStage.resultCombined:
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          await AuthGuard.ensureLogin(context);
        });

        return const ResultCombinedView();

      /// -------------------------
      default:
        return const SizedBox();
    }
  }

  @override
void dispose() {
  _scanFocusNode.dispose();
  super.dispose();
}
}

