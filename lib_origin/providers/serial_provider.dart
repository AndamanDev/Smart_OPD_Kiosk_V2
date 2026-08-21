import 'package:flutter/material.dart';

import '../models/working_mode.dart';
import '../providers_server/serial_server.dart';
import 'kiosk_state_provider.dart';
import 'settings_provider.dart';

  class SerialProvider extends ChangeNotifier {
  final SerialServer _server = SerialServer();

  KioskStageProvider? _kiosk;

  bool debugPause = false;

  bool _isConnected = false;
  String _currentData = "";
  String _currentPort = "";

  bool get isConnected => _isConnected;
  String get currentPort => _currentPort;
  String get lastData => _currentData;

  void init(SettingsProvider settings, KioskStageProvider kiosk) {
    if (debugPause) {
      _isConnected = false;
      notifyListeners();
      return;
    }

    _kiosk = kiosk; // ✅ สำคัญมาก

    late String targetPort;

    switch (settings.workingMode) {
      case WorkingMode.scaleOnly:
        targetPort = settings.scaleReadPort;
        break;
      case WorkingMode.bloodPressureOnly:
        targetPort = settings.bpPort;
        break;
      case WorkingMode.combined:
        targetPort = settings.scaleReadPort;
        break;
    }

    _currentPort = targetPort;

    _server.startReading(
      targetPort,
      (rawData) {
        _currentData = rawData;
        notifyListeners();
      },
      onStatusChanged: (status) {
        _isConnected = status;

        if (!status) {
          _kiosk?.setStage(KioskStage.portError);
        }

        notifyListeners();
      },
    );
  }

  void switchPort(String port) {
    _server.stop();

    _currentPort = port;

    _server.startReading(
      port,
      (raw) {
        _currentData = raw;
        notifyListeners();
      },
      onStatusChanged: (s) {
        _isConnected = s;

        if (!s) {
          _kiosk?.setStage(KioskStage.portError);
        }

        notifyListeners();
      },
    );
  }

  void stop() {
    _server.stop();
    _isConnected = false;
    notifyListeners();
  }
}