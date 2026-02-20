import 'package:flutter/material.dart';
import '../providers_server/patient_server.dart';
import 'auth_provider.dart';
import 'settings_provider.dart';

class PatientProvider extends ChangeNotifier {
  Map<String, dynamic>? patient;
  bool isLoading = false;
  String? errorMessage;

  Future<bool> fetchByHn({
    required String hn,
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
    errorMessage = null;
    notifyListeners();



    try {
      final baseUrl = settings.serverIp.startsWith('http')
          ? settings.serverIp
          : 'http://${settings.serverIp}';

      patient = await PatientServer.getPatientByHn(
        baseUrl: baseUrl,
        hn: hn,
        accessToken: auth.token!,
      );


      return true;
    } catch (e) {
      print(e);
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      patient = null;
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void clear() {
    patient = null;
    errorMessage = null;
    notifyListeners();
  }

  String rawVitalsData = "";

  void setRawData(String data) {
    rawVitalsData = data;
    notifyListeners();
  }

  bool _measurementError = false;
  bool get measurementError => _measurementError;

  void setMeasurementError(bool value) {
    _measurementError = value;
    notifyListeners();
  }
}
