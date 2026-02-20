import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final settingsProvider = SettingsProvider();
  await settingsProvider.loadFromStorage();

  if (!kIsWeb) {
    await windowManager.ensureInitialized();
    WindowOptions windowOptions = const WindowOptions(
      size: Size(1280, 800),
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  if (!kIsWeb) {
    await windowManager.ensureInitialized();

    WindowOptions windowOptions = const WindowOptions(
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
    );

    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.maximize();
      await windowManager.focus();
    });
  }

  // runApp(
  //     DevicePreview(
  //       enabled: !kReleaseMode,
  //       builder: (context) => MultiProvider(
  //         providers: [
  //           ChangeNotifierProvider(create: (_) => SerialProvider()),
  //           ChangeNotifierProvider(create: (_) => PatientProvider()),
  //           ChangeNotifierProvider(create: (_) => KioskStageProvider()),
  //           ChangeNotifierProvider.value(value: settingsProvider),
  //           ChangeNotifierProvider(create: (_) => VitalsProvider()),
  //           ChangeNotifierProvider(create: (_) => AuthProvider()),
  //         ],
  //         child: const SmartOpdApp(),
  //       ),
  //     ),
  //   );

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

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      useInheritedMediaQuery: true,
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: GoogleFonts.kanitTextTheme(),
      ),
      home: const HomeKioskScreen(),
    );
  }
}
