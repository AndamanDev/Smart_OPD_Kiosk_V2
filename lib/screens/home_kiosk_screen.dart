import 'package:flutter/material.dart';
import '../core/responsive/responsive_config.dart';
import '../core/responsive/layout_ratio.dart';
import 'setting_screen.dart';
import 'views/combined_measure_error_view.dart';
import 'views/combined_measure_view.dart';
import 'views/login_error_view.dart';
import 'views/measure_error_view.dart';
import 'views/measure_view.dart';
import 'views/port_error_view.dart';
import 'views/result_combined_view.dart';
import 'views/result_view.dart';
import 'views/scan_error_view.dart';
import 'views/widgets/kiosk_bottom_bar.dart';
import 'views/widgets/kiosk_responsive_middle.dart';
import 'views/widgets/kiosk_top_section.dart';
import 'package:provider/provider.dart';
import '../providers/kiosk_state_provider.dart';
import '../providers/serial_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import 'views/scan_view.dart';

class HomeKioskScreen extends StatefulWidget {
  const HomeKioskScreen({super.key});

  @override
  State<HomeKioskScreen> createState() => _HomeKioskScreenState();
}

class _HomeKioskScreenState extends State<HomeKioskScreen> {
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _initializeApp();
    }
  }

  Future<void> _initializeApp() async {
    Future.microtask(() async {
      if (!mounted) return;

      final settings = context.read<SettingsProvider>();
      final auth = context.read<AuthProvider>();
      final kiosk = context.read<KioskStageProvider>();

      context.read<SerialProvider>().init(settings, kiosk);
      kiosk.setStage(KioskStage.loading);

      try {
        final success = await auth
            .autoLogin(settings)
            .timeout(const Duration(seconds: 10), onTimeout: () => false);

        if (!mounted) return;

        if (success) {
          kiosk.setStage(KioskStage.scan);
        } else {
          kiosk.setStage(KioskStage.loginError);
        }
      } catch (e) {
        debugPrint("Init Error: $e");
        if (mounted) kiosk.setStage(KioskStage.loginError);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final stage = context.watch<KioskStageProvider>().stage;
    final showChrome = stage != KioskStage.settings;
    final auth = context.watch<AuthProvider>();

    // if ((stage != KioskStage.settings &&
    //         stage != KioskStage.loginError &&
    //         stage != KioskStage.loading) &&
    //     (!auth.isLoggedIn || auth.isTokenExpired)) {
    //   WidgetsBinding.instance.addPostFrameCallback((_) {
    //     context.read<KioskStageProvider>().setStage(KioskStage.loginError);
    //   });
    // }

    final kioskProvider = context.watch<KioskStageProvider>();
    final serialProvider = context.watch<SerialProvider>();

    if (stage == KioskStage.portError && serialProvider.isConnected) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        kioskProvider.setStage(KioskStage.scan);
      });
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final config = ResponsiveConfig(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
        );

        final showChrome = stage != KioskStage.settings;

        return Scaffold(
          backgroundColor: Colors.white,
          body: Column(
            children: [
              if (showChrome)
                Expanded(
                  flex: 2,
                  child: KioskTopSection(
                    config: config,
                    rightImage: 'assets/images/hospital_logo_new.png',
                  ),
                ),
              Expanded(flex: 7, child: _buildByStage(stage)),
              const SizedBox(height: 8),
              if (showChrome) KioskBottomBar(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildByStage(KioskStage stage) {
    final serial = context.read<SerialProvider>();
    final settings = context.read<SettingsProvider>();
    final kiosk = context.read<KioskStageProvider>();
    final auth = context.read<AuthProvider>();
    final ok = auth.token != null && !auth.isTokenExpired;

    switch (stage) {
      case KioskStage.loading:
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          final success = await auth
              .autoLogin(settings)
              .timeout(const Duration(seconds: 10), onTimeout: () => false);

          if (!mounted) return;

          if (success) {
            kiosk.setStage(KioskStage.scan);
          } else {
            kiosk.setStage(KioskStage.loginError);
          }
        });

        return const Center(child: CircularProgressIndicator());

      case KioskStage.portError:
        return const PortErrorView();
      // return const ScanView();

      case KioskStage.settings:
        return const SettingsScreen();

      case KioskStage.loginError:
        return const LoginErrorView();

      case KioskStage.scan:
        if (!serial.isConnected) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!serial.isConnected) {
              serial.init(settings, kiosk);
            }
          });
        }

        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!ok) {
            final success = await auth
                .autoLogin(settings)
                .timeout(const Duration(seconds: 10), onTimeout: () => false);

            if (!success) {
              kiosk.setStage(KioskStage.loginError);
            }

            // if (!success) {
            //   LoginErrorView();
            // }
          }
        });

        return const ScanView();

      case KioskStage.scanError:
        return const ScanErrorView();

      case KioskStage.measure:
        return MeasureView(key: ValueKey(kiosk.measureVersion));

      case KioskStage.measureCombined:
        return CombinedMeasureView();

      case KioskStage.measureError:
        return const MeasureErrorView();

      case KioskStage.measureCombinedError:
        return const MeasureCombinedErrorView();

      case KioskStage.result:
        return const ResultView();

      case KioskStage.resultCombined:
        return const ResultCombinedView();

      default:
        return const SizedBox();
    }
  }
}
