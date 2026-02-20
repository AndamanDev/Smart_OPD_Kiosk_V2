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

      Map<String, dynamic> payload = {
        "HN": hn,
        "WEIGHT": null,
        "HEIGHT": null,
        "BMI": null,
        "TEMP": null,
        "SYSTOLIC": null,
        "DIASTOLIC": null,
        "PULSE": null,
        "SPO2": null,
        "HEARTRATE": null,
        "RR": null,
        "WAIST": null,
        "PAINSCORE": null,
      };

      if (settings.workingMode == WorkingMode.scaleOnly) {
        final reading = ScaleUtils.parse(rawVitals);
        payload["WEIGHT"] = reading.weight;
        payload["HEIGHT"] = reading.height;
        payload["BMI"] = reading.bmi;
      } else if (settings.workingMode == WorkingMode.bloodPressureOnly) {
        final reading = BloodPressureUtils.parse(rawVitals);
        payload["SYSTOLIC"] = reading.systolic;
        payload["DIASTOLIC"] = reading.diastolic;
        payload["PULSE"] = reading.pulse;
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
          payload["WEIGHT"] = readingS.weight;
          payload["HEIGHT"] = readingS.height;
          payload["BMI"] = readingS.bmi;
        }

        if (bpPart != null) {
          final readingB = BloodPressureUtils.parse(bpPart);
          payload["SYSTOLIC"] = readingB.systolic;
          payload["DIASTOLIC"] = readingB.diastolic;
          payload["PULSE"] = readingB.pulse;
        }
      }

      await VitalsServer.sendVitals(
        baseUrl: baseUrl,
        accessToken: auth.token!,
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
