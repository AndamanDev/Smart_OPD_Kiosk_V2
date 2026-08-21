import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:smart_opd_kiosk_v2_vertical/SmartReader/CardReaderCameraPage.dart';
import 'SmartReader/CameraIDPage.dart';
import 'SmartReader/CardReaderPage.dart';
import 'vision_detector_views/id_card_yolo_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MainMenuPage(),
    );
  }
}

class MainMenuPage extends StatelessWidget {
  const MainMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Smart OPD Kiosk"),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            SizedBox(
              width: 260,
              height: 60,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.camera_alt),
                label: const Text(
                  "กล้องอ่านบัตรประชาชน",
                  style: TextStyle(fontSize: 18),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CardReaderCameraPage(),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: 260,
              height: 60,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.credit_card),
                label: const Text(
                  "เสียบบัตรประชาชน",
                  style: TextStyle(fontSize: 18),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CardReaderPage(),
                    ),
                  );
                },
              ),
            ),

          ],
        ),
      ),
    );
  }
}
