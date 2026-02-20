import 'dart:async';
import 'package:flutter/material.dart';
import 'serial_provider.dart';

enum KioskStage {
  settings,
  portError,
  loading,
  loginError,
  scan,
  scanError,
  measure,
  measureCombined,
  measureError,
  measureCombinedError,
  result,
  resultScale,
  resultCombined,
}

class KioskStageProvider extends ChangeNotifier {
  KioskStage _stage = KioskStage.loading;
  Timer? _resetTimer;
  bool _isRetry = false;
  int _measureVersion = 0;

  KioskStage get stage => _stage;
  bool get isRetry => _isRetry;
  int get measureVersion => _measureVersion;

  void setStage(KioskStage value, {bool isRetry = false}) {
    if (_stage == value) return;

    _stage = value;
    _isRetry = isRetry;
    notifyListeners();
  }

  void reset(SerialProvider serial) {
    _measureVersion = 0;
    _resetTimer?.cancel();
    serial.stop();

    _stage = KioskStage.scan;
    _isRetry = false;
    notifyListeners();
  }

    void resettosetting(SerialProvider serial) {
    _measureVersion = 0;
    _resetTimer?.cancel();
    serial.stop();
    _isRetry = false;
    notifyListeners();
  }

  void resetHn(SerialProvider serial, mode) {
    _measureVersion++;
    _resetTimer?.cancel();

    if (mode) {
      _stage = KioskStage.measureCombined;
    } else {
      _stage = KioskStage.measure;
    }
    _isRetry = false;
    notifyListeners();
  }

  void clearRetry({bool notify = false}) {
    _isRetry = false;
    if (notify) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _resetTimer?.cancel();
    super.dispose();
  }
}
