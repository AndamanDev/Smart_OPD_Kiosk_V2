import 'dart:async';
import 'package:flutter_libserialport/flutter_libserialport.dart';
import '../providers/kiosk_state_provider.dart';

class SerialServer {
  SerialPort? _port;
  SerialPortReader? _reader;
  StreamSubscription? _subscription;
  Timer? _pollTimer;               // ⭐ polling timer แทน stream (ป้องกัน crash)
  final StringBuffer _rxBuf = StringBuffer(); // ⭐ สะสม bytes จนครบ packet

  KioskStageProvider? kiosk;

  bool _running = false;
  String? _currentPort;
  int _baudRate = 9600;            // ⭐ baud rate ที่ตั้งจากภายนอก

  String? get currentPort => _currentPort;
  bool get isConnected => _port?.isOpen ?? false;

  Function(bool)? onStatusChanged;

  void startReading(
    String portName,
    Function(String) onDataReceived, {
    Function(bool)? onStatusChanged,
    KioskStageProvider? kioskProvider,
    int baudRate = 9600,           // ⭐ รับ baud rate จากผู้เรียก
  }) {
    _currentPort = portName;
    _baudRate = baudRate;
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
    _pollTimer?.cancel();
    _pollTimer = null;

    _rxBuf.clear();

    _subscription?.cancel();
    _subscription = null;

    _reader?.close();
    _reader = null;

    if (_port?.isOpen ?? false) {
      _port!.close();
    }
    _port?.dispose();
    _port = null;
  }

  // 2. ปรับฟังก์ชัน stop() สำหรับหยุดการทำงานจริงๆ (เช่น ออกจากหน้าจอ)
  void stop() {
    print("🛑 Stopping SerialServer...");
    _running = false;
    _cleanup();
  }

//   void _open(Function(String) onDataReceived) async {
//   if (!_running || _currentPort == null) return;

//   try {
//     final ports = SerialPort.availablePorts;
//     print("📡 Available Ports: $ports");

//     if (!ports.contains(_currentPort)) {
//       print("❌ Port $_currentPort not found");
//       onStatusChanged?.call(false);
//       return;
//     }

//     _cleanup();

//     print("🔌 กำลังเปิด port $_currentPort  baud=$_baudRate");
//     _port = SerialPort(_currentPort!);

//     final opened = _port!.openReadWrite();
//     if (!opened) {
//       print("❌ เปิด port ไม่สำเร็จ");
//       onStatusChanged?.call(false);
//       _retry(onDataReceived);
//       return;
//     }

//     final config = _port!.config;
//     config.baudRate = _baudRate;   // ⭐ ใช้ baud rate ที่รับมา (เช่น 19200 สำหรับ Terumo)
//     config.bits = 8;
//     config.parity = SerialPortParity.none;
//     config.stopBits = 1;
//     _port!.config = config;

//     print("✅ CONNECTED TO PORT: ${_port!.name}  baud=$_baudRate");
//     onStatusChanged?.call(true);

//     // ⭐ ใช้ Timer polling แทน SerialPortReader.stream
//     //    เพราะ bytesAvailable บน Windows คืน -1 เมื่อ port error
//     //    → SerialPortReader ส่ง -1 เป็น buffer length → crash
//     _pollTimer = Timer.periodic(const Duration(milliseconds: 20), (_) {
//       if (!_running || !(_port?.isOpen ?? false)) {
//         _pollTimer?.cancel();
//         _pollTimer = null;
//         onStatusChanged?.call(false);
//         _retry(onDataReceived);
//         return;
//       }
//       try {
//         final available = _port!.bytesAvailable;
//         if (available <= 0) return;          // ⭐ guard: ข้าม -1 และ 0

//         final data = _port!.read(available, timeout: 0);
//         if (data.isEmpty) return;

//         // 🐛 DEBUG log
//         final now = DateTime.now();
//         final ts = "[${now.hour.toString().padLeft(2, '0')}:"
//             "${now.minute.toString().padLeft(2, '0')}:"
//             "${now.second.toString().padLeft(2, '0')}]";
//         final hex =
//             data.map((b) => b.toRadixString(16).toUpperCase().padLeft(2, '0')).join(' ');
//         final str = String.fromCharCodes(data);
//         print("📦 $ts -> $str [HEX: $hex]");

//         _rxBuf.write(str);
//         var raw = _rxBuf.toString();

//         // ⭐ แยก packet ด้วย CR/LF (รูปแบบใหม่จบบรรทัดด้วย \r หรือ \n)
//         //    เช่น "R1,000000000,260429,100000,117,089,075,072,0000,0000,00000,000\r\n"
//         int nlIdx;
//         while ((nlIdx = raw.indexOf(RegExp(r'[\r\n]'))) >= 0) {
//           final line = raw.substring(0, nlIdx).trim();
//           raw = raw.substring(nlIdx + 1);
//           if (line.isNotEmpty) {
//               print("✅ FULL LINE -> $line");   
//             onDataReceived(line);            // ส่งทั้งบรรทัดออกไป
//           }
//         }

//         // เก็บเศษที่ยังไม่ครบบรรทัดไว้รอรอบหน้า
//         _rxBuf
//           ..clear()
//           ..write(raw);
//       } catch (e) {
//         print("⚠ Poll read error: $e");
//         _pollTimer?.cancel();
//         _pollTimer = null;
//         onStatusChanged?.call(false);
//         _cleanup();
//         _retry(onDataReceived);
//       }
//     });
//   } catch (e) {
//     print("❌ Exception: $e");
//     onStatusChanged?.call(false);
//     _retry(onDataReceived);
//   }
// }

  void _open(Function(String) onDataReceived) async {
    if (!_running || _currentPort == null) return;

    try {
      final ports = SerialPort.availablePorts;
      print("📡 Available Ports: $ports");

      if (!ports.contains(_currentPort)) {
        print("❌ Port $_currentPort not found");
        onStatusChanged?.call(false);
        return;
      }

      _cleanup();

      print("🔌 กำลังเปิด port $_currentPort  baud=$_baudRate");
      _port = SerialPort(_currentPort!);

      final opened = _port!.openReadWrite();
      if (!opened) {
        print("❌ เปิด port ไม่สำเร็จ");
        onStatusChanged?.call(false);
        _retry(onDataReceived);
        return;
      }

      final config = _port!.config;
      config.baudRate = _baudRate;   // ⭐ ใช้ baud rate ที่รับมา (19200 สำหรับ Terumo)
      config.bits = 8;
      config.parity = SerialPortParity.none;
      config.stopBits = 1;
      _port!.config = config;

      print("✅ CONNECTED TO PORT: ${_port!.name}  baud=$_baudRate");
      onStatusChanged?.call(true);

      // ⭐ ใช้ Timer polling แทน SerialPortReader.stream
      //    เพราะ bytesAvailable บน Windows คืน -1 เมื่อ port error
      //    → SerialPortReader ส่ง -1 เป็น buffer length → crash
      _pollTimer = Timer.periodic(const Duration(milliseconds: 20), (_) {
        if (!_running || !(_port?.isOpen ?? false)) {
          _pollTimer?.cancel();
          _pollTimer = null;
          onStatusChanged?.call(false);
          _retry(onDataReceived);
          return;
        }
        try {
          final available = _port!.bytesAvailable;
          if (available <= 0) return;       // ⭐ guard: ข้าม -1 และ 0

          final data = _port!.read(available, timeout: 0);
          if (data.isEmpty) return;

          // 🐛 DEBUG log
          final now = DateTime.now();
          final ts = "[${now.hour.toString().padLeft(2,'0')}:${now.minute.toString().padLeft(2,'0')}:${now.second.toString().padLeft(2,'0')}]";
          final hex = data.map((b) => b.toRadixString(16).toUpperCase().padLeft(2,'0')).join(' ');
          final str = String.fromCharCodes(data);
          print("📦 $ts -> $str [HEX: $hex]");

          _rxBuf.write(str);
          final raw = _rxBuf.toString();

          // รอจนเจอ ETX (0x03) = packet ครบ
          final etxIdx = raw.indexOf('\x03');
          if (etxIdx >= 0) {
            final packet = raw.substring(0, etxIdx + 1);
            final remaining = raw.substring(etxIdx + 1);
            _rxBuf.clear();
            if (remaining.isNotEmpty) _rxBuf.write(remaining);
            onDataReceived(packet);
          }
        } catch (e) {
          print("⚠ Poll read error: $e");
          _pollTimer?.cancel();
          _pollTimer = null;
          onStatusChanged?.call(false);
          _cleanup();
          _retry(onDataReceived);
        }
      });

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
