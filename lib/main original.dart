import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:smart_opd_kiosk_v2_vertical/core/theme/app_theme.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'providers/serial_provider.dart';
import 'package:window_manager/window_manager.dart';
import 'providers/auth_provider.dart';
import 'providers/kiosk_state_provider.dart';
import 'providers/patient_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/vitals_provider.dart';
import 'providers_server/sound_server.dart';
import 'screens/home_kiosk_screen.dart';
import 'package:device_preview/device_preview.dart';
import 'dart:io' show Platform;
import 'package:flutter/services.dart';

Future<void> requestAllPermissions() async {
  if (kIsWeb) return;

  if (Platform.isAndroid || Platform.isIOS) {
    await [
      Permission.camera,
      Permission.microphone,
      Permission.storage,
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
    ].request();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final settingsProvider = SettingsProvider();
  await settingsProvider.loadFromStorage();

  if (!kIsWeb && Platform.isAndroid) {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    await windowManager.ensureInitialized();

    const windowOptions = WindowOptions(
      titleBarStyle: TitleBarStyle.hidden,
      skipTaskbar: false,
      center: true,
      backgroundColor: Colors.black,
    );

    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await Future.delayed(const Duration(milliseconds: 300000));
        await windowManager.setFullScreen(true);
      });
    });
  }

  runApp(
    MultiProvider(
      providers: [
        Provider<SoundServer>(
          create: (_) => SoundServer(),
          dispose: (_, s) => s.dispose(),
        ),
        ChangeNotifierProvider(create: (_) => SerialProvider()),
        ChangeNotifierProvider(create: (_) => PatientProvider()),
        ChangeNotifierProvider(create: (_) => KioskStageProvider()),
        ChangeNotifierProvider.value(value: settingsProvider),
        ChangeNotifierProvider(create: (_) => VitalsProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: const SmartOpdApp(),
    ),
  );
}

class SmartOpdApp extends StatefulWidget {
  const SmartOpdApp({super.key});

  @override
  State<SmartOpdApp> createState() => _SmartOpdAppState();
}

class _SmartOpdAppState extends State<SmartOpdApp> {
  Future<void> _enableAndroidKiosk() async {
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
      overlays: [],
    );
  }

  Future<void> _init() async {
    await requestAllPermissions();
  }

  @override
  void initState() {
    super.initState();

     _init();



    if (!kIsWeb && Platform.isAndroid) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _enableAndroidKiosk();
      });
    }

    if (Platform.isAndroid) {
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarDividerColor: Colors.transparent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      useInheritedMediaQuery: true,
      locale: kDebugMode ? DevicePreview.locale(context) : null,
      builder: kDebugMode ? DevicePreview.appBuilder : null,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const HomeKioskScreen(),
    );
  }
}
