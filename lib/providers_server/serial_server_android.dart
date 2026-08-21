import 'dart:async';
import 'package:flutter_serial_communication/flutter_serial_communication.dart';
import 'package:flutter_serial_communication/models/device_info.dart';
import '../providers/kiosk_state_provider.dart';

/// Android implementation ใช้ flutter_serial_communication
/// (อ่านผ่าน event stream — ไม่ค้าง buffer เหมือน usb_serial)
class SerialServerAndroid {
  final FlutterSerialCommunication _fsc = FlutterSerialCommunication();

  StreamSubscription? _msgSub;
  StreamSubscription? _connSub;

  bool _running = false;
  bool _connected = false;
  String? _currentDeviceName;
  int _baudRate = 9600;

  KioskStageProvider? kiosk;
  Function(bool)? onStatusChanged;

  bool get isConnected => _connected;
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

  Future<void> _cleanup() async {
    await _msgSub?.cancel();
    _msgSub = null;
    await _connSub?.cancel();
    _connSub = null;
    _rxBuf.clear();
    try {
      await _fsc.disconnect();
    } catch (_) {}
    _connected = false;
  }

  Future<void> _open(Function(String) onDataReceived) async {
    if (!_running || _currentDeviceName == null) return;

    try {
      await _cleanup();

      print("📡 [Android] ค้นหา USB device: $_currentDeviceName");

      final devices = await _fsc.getAvailableDevices();
      print(
          "📡 [Android] พบ ${devices.length} device(s): ${devices.map((d) => d.deviceName).toList()}");

      // หา device ที่ตรงกับชื่อที่เลือก
      DeviceInfo? target;
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

      final ok = await _fsc.connect(target, _baudRate);
      if (!ok) {
        print("❌ [Android] connect ไม่สำเร็จ (permission?)");
        onStatusChanged?.call(false);
        _retry(onDataReceived);
        return;
      }

      // 8-N-1 + assert DTR/RTS (จำเป็นสำหรับ CH340 ไม่งั้นข้อมูลถูก buffer ค้าง)
      await _fsc.setParameters(_baudRate, 8, 1, 0);
      await _fsc.setDTR(true);
      await _fsc.setRTS(true);

      _connected = true;
      print("✅ [Android] CONNECTED: $_currentDeviceName  baud=$_baudRate");
      onStatusChanged?.call(true);

      // ฟังข้อมูลเข้า
      _msgSub = _fsc
          .getSerialMessageListener()
          .receiveBroadcastStream()
          .listen((event) {
        if (!_running) return;

        final List<int> data =
            (event is List<int>) ? event : List<int>.from(event as List);
        if (data.isEmpty) return;

        final str = String.fromCharCodes(data);
        final hex = data
            .map((b) => b.toRadixString(16).toUpperCase().padLeft(2, '0'))
            .join(' ');
        print("📦 [Android] -> $str [HEX: $hex]");

        _rxBuf.write(str);
        var raw = _rxBuf.toString();

        // ⭐ แยก packet ด้วย CR/LF (จบบรรทัดด้วย \r หรือ \n)
        //    เช่น "R1,000000000,260429,100000,117,089,075,072,0000,0000,00000,000\r\n"
        int nlIdx;
        while ((nlIdx = raw.indexOf(RegExp(r'[\r\n]'))) >= 0) {
          final line = raw.substring(0, nlIdx).trim();
          raw = raw.substring(nlIdx + 1);
          if (line.isNotEmpty) {
            print("✅ [Android] FULL LINE -> $line");
            onDataReceived(line);
          }
        }

        // เก็บเศษที่ยังไม่ครบบรรทัดไว้รอรอบหน้า
        _rxBuf
          ..clear()
          ..write(raw);
      }, onError: (e) {
        print("⚠ [Android] msg stream error: $e");
        onStatusChanged?.call(false);
        _cleanup();
        _retry(onDataReceived);
      });

      // ฟังสถานะการเชื่อมต่อ (device หลุด)
      _connSub = _fsc
          .getDeviceConnectionListener()
          .receiveBroadcastStream()
          .listen((event) {
        final isConn = event == true;
        if (!isConn && _running) {
          print("⚠ [Android] device disconnected");
          _connected = false;
          onStatusChanged?.call(false);
          _cleanup();
          _retry(onDataReceived);
        }
      });
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
