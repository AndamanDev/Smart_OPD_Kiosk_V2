import 'dart:async';
import 'dart:typed_data';
import 'package:usb_serial/usb_serial.dart';
import '../providers/kiosk_state_provider.dart';

/// Android implementation ใช้ usb_serial package
class SerialServerAndroid {
  UsbPort? _usbPort;
  StreamSubscription? _subscription;

  bool _running = false;
  String? _currentDeviceName;
  int _baudRate = 9600;

  KioskStageProvider? kiosk;
  Function(bool)? onStatusChanged;

  bool get isConnected => _usbPort != null;
  String? get currentPort => _currentDeviceName;

  final StringBuffer _rxBuf = StringBuffer();

  void startReading(
    String deviceName,
    Function(String) onDataReceived, {
    Function(bool)? onStatusChanged,
    KioskStageProvider? kioskProvider,
    int baudRate = 9600,
  }) {
    _currentDeviceName = deviceName;
    _baudRate = baudRate;
    _running = true;
    this.onStatusChanged = onStatusChanged;
    kiosk = kioskProvider;
    _open(onDataReceived);
  }

  void stop() {
    print("🛑 [Android] Stopping SerialServerAndroid...");
    _running = false;
    _cleanup();
  }

  void _cleanup() {
    _subscription?.cancel();
    _subscription = null;
    _rxBuf.clear();
    _usbPort?.close();
    _usbPort = null;
  }

  Future<void> _open(Function(String) onDataReceived) async {
    if (!_running || _currentDeviceName == null) return;

    try {
      _cleanup();

      print("📡 [Android] ค้นหา USB device: $_currentDeviceName");

      final devices = await UsbSerial.listDevices();
      print("📡 [Android] พบ ${devices.length} device(s): ${devices.map((d) => d.deviceName).toList()}");

      // หา device ที่ตรงกับชื่อที่เลือก
      UsbDevice? target;
      for (final d in devices) {
        if (d.deviceName == _currentDeviceName) {
          target = d;
          break;
        }
      }

      if (target == null) {
        print("❌ [Android] ไม่พบ device: $_currentDeviceName");
        onStatusChanged?.call(false);
        _retry(onDataReceived);
        return;
      }

      // สร้าง port
      final port = await target.create();
      if (port == null) {
        print("❌ [Android] create() คืน null");
        onStatusChanged?.call(false);
        _retry(onDataReceived);
        return;
      }

      final opened = await port.open();
      if (!opened) {
        print("❌ [Android] เปิด port ไม่สำเร็จ");
        onStatusChanged?.call(false);
        _retry(onDataReceived);
        return;
      }

      await port.setPortParameters(
        _baudRate,
        UsbPort.DATABITS_8,
        UsbPort.STOPBITS_1,
        UsbPort.PARITY_NONE,
      );

      _usbPort = port;
      print("✅ [Android] CONNECTED: $_currentDeviceName  baud=$_baudRate");
      onStatusChanged?.call(true);

      // Subscribe ข้อมูล
      _subscription = port.inputStream?.listen(
        (Uint8List data) {
          if (!_running) return;

          // 🐛 DEBUG log
          final now = DateTime.now();
          final ts = "[${now.hour.toString().padLeft(2, '0')}:"
              "${now.minute.toString().padLeft(2, '0')}:"
              "${now.second.toString().padLeft(2, '0')}]";
          final str = String.fromCharCodes(data);
          final hex = data.map((b) => b.toRadixString(16).toUpperCase().padLeft(2, '0')).join(' ');
          print("📦 [Android] $ts -> $str [HEX: $hex]");

          _rxBuf.write(str);
          var raw = _rxBuf.toString();

          // ⭐ แยก packet ด้วย CR/LF (รูปแบบใหม่จบบรรทัดด้วย \r หรือ \n)
          //    เช่น "R1,000000000,260429,100000,117,089,075,072,0000,0000,00000,000\r\n"
          int nlIdx;
          while ((nlIdx = raw.indexOf(RegExp(r'[\r\n]'))) >= 0) {
            final line = raw.substring(0, nlIdx).trim();
            raw = raw.substring(nlIdx + 1);
            if (line.isNotEmpty) {
              print("✅ [Android] FULL LINE -> $line");
              onDataReceived(line);          // ส่งทั้งบรรทัดออกไป
            }
          }

          // เก็บเศษที่ยังไม่ครบบรรทัดไว้รอรอบหน้า
          _rxBuf
            ..clear()
            ..write(raw);
        },
        onError: (e) {
          print("⚠ [Android] Stream error: $e");
          onStatusChanged?.call(false);
          _cleanup();
          _retry(onDataReceived);
        },
        onDone: () {
          print("⚠ [Android] Stream closed");
          onStatusChanged?.call(false);
          _cleanup();
          _retry(onDataReceived);
        },
        cancelOnError: true,
      );
    } catch (e) {
      print("❌ [Android] Exception: $e");
      onStatusChanged?.call(false);
      _retry(onDataReceived);
    }
  }

  Future<void> _open1(Function(String) onDataReceived) async {
    if (!_running || _currentDeviceName == null) return;

    try {
      _cleanup();

      print("📡 [Android] ค้นหา USB device: $_currentDeviceName");

      final devices = await UsbSerial.listDevices();
      print("📡 [Android] พบ ${devices.length} device(s): ${devices.map((d) => d.deviceName).toList()}");

      // หา device ที่ตรงกับชื่อที่เลือก
      UsbDevice? target;
      for (final d in devices) {
        if (d.deviceName == _currentDeviceName) {
          target = d;
          break;
        }
      }

      if (target == null) {
        print("❌ [Android] ไม่พบ device: $_currentDeviceName");
        onStatusChanged?.call(false);
        _retry(onDataReceived);
        return;
      }

      // สร้าง port
      final port = await target.create();
      if (port == null) {
        print("❌ [Android] create() คืน null");
        onStatusChanged?.call(false);
        _retry(onDataReceived);
        return;
      }

      final opened = await port.open();
      if (!opened) {
        print("❌ [Android] เปิด port ไม่สำเร็จ");
        onStatusChanged?.call(false);
        _retry(onDataReceived);
        return;
      }

      await port.setPortParameters(
        _baudRate,
        UsbPort.DATABITS_8,
        UsbPort.STOPBITS_1,
        UsbPort.PARITY_NONE,
      );

      _usbPort = port;
      print("✅ [Android] CONNECTED: $_currentDeviceName  baud=$_baudRate");
      onStatusChanged?.call(true);

      // Subscribe ข้อมูล
      _subscription = port.inputStream?.listen(
        (Uint8List data) {
          if (!_running) return;

          final str = String.fromCharCodes(data);
          final hex = data.map((b) => b.toRadixString(16).toUpperCase().padLeft(2, '0')).join(' ');
          print("📦 [Android] -> $str [HEX: $hex]");

          _rxBuf.write(str);
          final raw = _rxBuf.toString();

          // รอจนครบ packet (ETX = 0x03)
          final etxIdx = raw.indexOf('\x03');
          if (etxIdx >= 0) {
            final packet = raw.substring(0, etxIdx + 1);
            final remaining = raw.substring(etxIdx + 1);
            _rxBuf.clear();
            if (remaining.isNotEmpty) _rxBuf.write(remaining);
            onDataReceived(packet);
          }
        },
        onError: (e) {
          print("⚠ [Android] Stream error: $e");
          onStatusChanged?.call(false);
          _cleanup();
          _retry(onDataReceived);
        },
        onDone: () {
          print("⚠ [Android] Stream closed");
          onStatusChanged?.call(false);
          _cleanup();
          _retry(onDataReceived);
        },
        cancelOnError: true,
      );
    } catch (e) {
      print("❌ [Android] Exception: $e");
      onStatusChanged?.call(false);
      _retry(onDataReceived);
    }
  }

  void _retry(Function(String) onDataReceived) {
    if (!_running) return;
    Future.delayed(const Duration(seconds: 2), () {
      if (_running) {
        print("🔁 [Android] Retry...");
        _open(onDataReceived);
      }
    });
  }
}
