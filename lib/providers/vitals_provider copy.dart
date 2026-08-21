import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/working_mode.dart';
import '../providers_server/vitals_server.dart';
import '../utils/BloodPressureUtils.dart';
import '../utils/ScaleUtils.dart';
import 'auth_provider.dart';
import 'settings_provider.dart';

class VitalsProvider extends ChangeNotifier {
  bool isLoading = false;
  bool lastSuccess = false;
  String? errorMessage;

  Future<bool> saveToVitals({
    required String hn,
    required String rawVitals,
    required SettingsProvider settings,
    required AuthProvider auth,
  }) async {
    if (auth.token == null) {
      errorMessage = 'ยังไม่ได้ Login';
      notifyListeners();
      return false;
    }

    if (settings.serverIp.isEmpty) {
      errorMessage = 'ยังไม่ได้ตั้งค่า Server';
      notifyListeners();
      return false;
    }

    isLoading = true;
    lastSuccess = false;
    errorMessage = null;
    notifyListeners();

    try {
      final baseUrl = settings.serverIp.startsWith('http')
          ? settings.serverIp
          : 'http://${settings.serverIp}';

      // final savevitalpath = settings.savevitalpath.isEmpty
      //     ? '/${settings.savevitalpath}'
      //     : '/SaveVitalsign';

      final savevitalpath = settings.savevitalpath.isEmpty
          ? '/SaveVitalsign'
          : settings.savevitalpath.startsWith('/')
          ? settings.savevitalpath
          : '/${settings.savevitalpath}';

      // ใช้ hn จาก patient map (รองรับทั้ง HN และ hn)
      final patientHn = hn;

      // สร้าง visit_date เป็น ISO 8601 UTC
      final visitDate = DateTime.now().toUtc().toIso8601String();

      // เริ่มจาก payload ขั้นต่ำ
      Map<String, dynamic> payload = {
        "hn": patientHn,
        "visit_date": visitDate,
      };

      if (settings.workingMode == WorkingMode.scaleOnly) {
        final reading = ScaleUtils.parse(rawVitals);
        if (reading.weight > 0) payload["weight"] = reading.weight;
        if (reading.height > 0) payload["height"] = reading.height;
      } else if (settings.workingMode == WorkingMode.bloodPressureOnly) {
        final reading = BloodPressureUtils.parseByDevice(
          rawVitals,
          settings.bpDevice,
        );
        if (reading.systolic > 0) payload["systolic"] = reading.systolic;
        if (reading.diastolic > 0) payload["diastolic"] = reading.diastolic;
        if (reading.pulse > 0) payload["pulse"] = reading.pulse;
      } else if (settings.workingMode == WorkingMode.combined) {
        final parts = rawVitals.split('|');

        String? scalePart;
        String? bpPart;

        for (final p in parts) {
          if (p.startsWith('SCALE')) {
            scalePart = p;
          } else {
            bpPart = p;
          }
        }

        if (scalePart != null) {
          final readingS = ScaleUtils.parse(scalePart);
          if (readingS.weight > 0) payload["weight"] = readingS.weight;
          if (readingS.height > 0) payload["height"] = readingS.height;
        }

        if (bpPart != null) {
          final readingB = BloodPressureUtils.parse(bpPart);
          if (readingB.systolic > 0) payload["systolic"] = readingB.systolic;
          if (readingB.diastolic > 0) payload["diastolic"] = readingB.diastolic;
          if (readingB.pulse > 0) payload["pulse"] = readingB.pulse;
        }
      }

      // คำนวณ HMAC จาก JSON body จริง (ไม่ใช่ empty string)
      final bodyJson = jsonEncode(payload);

      await VitalsServer.sendVitals(
        baseUrl: baseUrl,
        savevitalpath: savevitalpath,
        headers: AuthProvider.buildHmacHeaders(
          accessKey: settings.accessKey,
          secretKey: settings.secretKey,
          method: 'POST',
          path: savevitalpath,
          body: bodyJson,
        ),
        payload: payload,
      );

      print("✅ ส่ง vitals สำเร็จ: $payload");

      lastSuccess = true;
      return true;
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      print("❌ ERROR: $e");
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void clear() {
    errorMessage = null;
    lastSuccess = false;
    notifyListeners();
  }
}
