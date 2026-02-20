import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_libserialport/flutter_libserialport.dart';
import '../providers/kiosk_state_provider.dart';

class SerialServer {
  SerialPort? _port;
  SerialPortReader? _reader;
  StreamSubscription? _subscription;


  KioskStageProvider? kiosk;

  bool _running = false;
  String? _currentPort;

  
  String? get currentPort => _currentPort;
bool get isConnected => _port?.isOpen ?? false;

  Function(bool)? onStatusChanged;

  void startReading(
    String portName,
    Function(String) onDataReceived, {
    Function(bool)? onStatusChanged,
    KioskStageProvider? kioskProvider,
  }) {
    _currentPort = portName;
    _running = true;
    this.onStatusChanged = onStatusChanged;
    kiosk = kioskProvider;
    _open(onDataReceived);
  }

  // void _open(Function(String) onDataReceived) async {
  //   if (!_running || _currentPort == null) return;

  //   try {
  //     stop();

  //     print("🔌 กำลังเปิด port $_currentPort");

  //     _port = SerialPort(_currentPort!);

  //     if (!_port!.openReadWrite()) {
  //       print("❌ เปิด port ไม่สำเร็จ → retry...");
  //       onStatusChanged?.call(false);
  //       _retry(onDataReceived);
  //       return;
  //     }

  //     final config = _port!.config;
  //     config.baudRate = 9600;
  //     config.bits = 8;
  //     config.parity = SerialPortParity.none;
  //     config.stopBits = 1;
  //     _port!.config = config;

  //     print("✅ Port เปิดแล้ว: $_currentPort");
  //     onStatusChanged?.call(true);

  //     _reader = SerialPortReader(_port!);
  //     _subscription = _reader!.stream.listen(
  //       (Uint8List data) {
  //         final stringData = String.fromCharCodes(data);
  //         onDataReceived(stringData);
  //       },
  //       onError: (e) {
  //         print("⚠ Stream error: $e");
  //         _retry(onDataReceived);
  //       },
  //       onDone: () {
  //         print("⚠ Stream closed");
  //         _retry(onDataReceived);
  //       },
  //       cancelOnError: true,
  //     );
  //   } catch (e) {
  //     print("❌ Exception opening port: $e");
  //     _retry(onDataReceived);
  //   }
  // }

  void _cleanup() {
    _subscription?.cancel();
    _subscription = null;

    _reader?.close();
    _reader = null;

    if (_port?.isOpen ?? false) {
      _port!.close();
    }
    _port?.dispose(); // เพิ่มการ dispose เพื่อคืน memory
    _port = null;
  }

  // 2. ปรับฟังก์ชัน stop() สำหรับหยุดการทำงานจริงๆ (เช่น ออกจากหน้าจอ)
  void stop() {
    print("🛑 Stopping SerialServer...");
    _running = false;
    _cleanup();
  }

  void _open(Function(String) onDataReceived) async {
  if (!_running || _currentPort == null) return;

  try {
    _cleanup();

    print("🔌 กำลังเปิด port $_currentPort");

    _port = SerialPort(_currentPort!);

    final opened = _port!.openReadWrite();

    if (!opened) {
      print("❌ เปิด port ไม่สำเร็จ");
      onStatusChanged?.call(false);
      _retry(onDataReceived);
      return;
    }

    final config = _port!.config;
    config.baudRate = 9600;
    config.bits = 8;
    config.parity = SerialPortParity.none;
    config.stopBits = 1;
    _port!.config = config;

    print("✅ CONNECTED TO PORT: ${_port!.name}");
    print("🔎 isOpen: ${_port!.isOpen}");

    onStatusChanged?.call(true);

    _reader = SerialPortReader(_port!);

    _subscription = _reader!.stream.listen(
      (Uint8List data) {
        final stringData = String.fromCharCodes(data);
        onDataReceived(stringData);
      },
      onError: (e) {
        print("⚠ Stream error: $e");
        onStatusChanged?.call(false);
        _retry(onDataReceived);
      },
      onDone: () {
        print("⚠ Stream closed");
        onStatusChanged?.call(false);
        _retry(onDataReceived);
      },
      cancelOnError: true,
    );
  } catch (e) {
    print("❌ Exception: $e");
    onStatusChanged?.call(false);
    _retry(onDataReceived);
  }
}

  void _retry(Function(String) onDataReceived) {
    if (!_running) return;

    Future.delayed(const Duration(seconds: 2), () {
      if (_running) {
        print("🔁 Retry opening port...");
        _open(onDataReceived);
      }
    });
  }

  // void stop() {
  //   _running = false;

  //   _subscription?.cancel();
  //   _subscription = null;

  //   _reader?.close();
  //   _reader = null;

  //   if (_port?.isOpen ?? false) {
  //     _port!.close();
  //     print("🔌 Port ปิดแล้ว");
  //   }

  //   _port = null;
  // }
}
