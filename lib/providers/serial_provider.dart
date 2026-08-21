import 'dart:io';
import 'package:flutter/material.dart';

import '../models/device_models.dart';
import '../models/working_mode.dart';
import '../providers_server/serial_server.dart';
import '../providers_server/serial_server_android.dart';
import 'kiosk_state_provider.dart';
import 'settings_provider.dart';

class SerialProvider extends ChangeNotifier {
  final SerialServer _server = SerialServer();
  final SerialServerAndroid _serverAndroid = SerialServerAndroid();

  // Helper: เลือก server ที่ถูกต้องตาม platform
  void _startReading(
    String portName,
    Function(String) onData, {
    Function(bool)? onStatusChanged,
    KioskStageProvider? kioskProvider,
    int baudRate = 9600,
  }) {
    if (Platform.isAndroid) {
      _serverAndroid.startReading(
        portName,
        onData,
        onStatusChanged: onStatusChanged,
        kioskProvider: kioskProvider,
        baudRate: baudRate,
      );
    } else {
      _server.startReading(
        portName,
        onData,
        onStatusChanged: onStatusChanged,
        kioskProvider: kioskProvider,
        baudRate: baudRate,
      );
    }
  }

  void _stopAll() {
    _server.stop();
    _serverAndroid.stop();
  }

  bool get isConnected =>
      Platform.isAndroid ? _serverAndroid.isConnected : _server.isConnected;

  KioskStageProvider? _kiosk;

  bool debugPause = false;

  String _currentData = "";
  String _currentPort = "";

  String get currentPort => _currentPort;
  String get lastData => _currentData;

  void init(SettingsProvider settings, KioskStageProvider kiosk) {
    if (debugPause) {
      notifyListeners();
      return;
    }

    _kiosk = kiosk;

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

    _startReading(
      targetPort,
      (rawData) {
        _currentData = rawData;
        notifyListeners();
      },
      onStatusChanged: (status) {
        if (!status) {
          _kiosk?.setStage(KioskStage.portError);
        }
        notifyListeners();
      },
      baudRate: settings.bpDevice.baudRate,
    );
  }

  void switchPort(String port) {
    _stopAll();

    _currentPort = port;

    _startReading(
      port,
      (raw) {
        _currentData = raw;
        notifyListeners();
      },
      onStatusChanged: (s) {
        if (!s) {
          _kiosk?.setStage(KioskStage.portError);
        }
        notifyListeners();
      },
    );
  }

  void stop() {
    _stopAll();
    notifyListeners();
  }
}