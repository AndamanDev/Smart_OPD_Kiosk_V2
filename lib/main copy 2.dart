import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_libserialport/flutter_libserialport.dart';
import 'package:flutter_serial_communication/flutter_serial_communication.dart';
import 'package:flutter_serial_communication/models/device_info.dart';

/// ===============================================================
///  หน้าทดสอบ Serial แบบง่าย
///  - เลือก port
///  - baud 9600
///  - กด Connect แล้วดูว่ารับค่ามาได้ไหม
///  Android = flutter_serial_communication (event stream — ไม่ค้าง buffer)
///  Windows = flutter_libserialport
/// ===============================================================
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SerialTestApp());
}

class SerialTestApp extends StatelessWidget {
  const SerialTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Serial Test',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.teal),
      home: const SerialTestPage(),
    );
  }
}

class SerialTestPage extends StatefulWidget {
  const SerialTestPage({super.key});

  @override
  State<SerialTestPage> createState() => _SerialTestPageState();
}

class _SerialTestPageState extends State<SerialTestPage> {
  static const int _baudRate = 9600;

  List<String> _ports = [];
  String? _selectedPort;
  bool _connected = false;
  String _status = 'ยังไม่เชื่อมต่อ';
  final List<String> _log = [];
  final ScrollController _scroll = ScrollController();

  // ทดลอง flow control (Android)
  bool _dtr = true;
  bool _rts = true;

  // buffer สำหรับประกอบบรรทัดเต็ม (chunk อาจมาแยกหลายก้อน)
  final StringBuffer _rxBuf = StringBuffer();

  // --- Windows ---
  SerialPort? _winPort;
  Timer? _winPoll;

  // --- Android (flutter_serial_communication) ---
  final FlutterSerialCommunication _fsc = FlutterSerialCommunication();
  List<DeviceInfo> _androidDevices = [];
  StreamSubscription? _msgSub;
  StreamSubscription? _connSub;

  bool get _isAndroid => !kIsWeb && Platform.isAndroid;

  @override
  void initState() {
    super.initState();
    _refreshPorts();
  }

  @override
  void dispose() {
    _disconnect();
    _scroll.dispose();
    super.dispose();
  }

  void _addLog(String msg) {
    setState(() {
      final t = TimeOfDay.now();
      final ts =
          '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
      _log.add('[$ts] $msg');
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  // ---------------- รายการ port ----------------
  Future<void> _refreshPorts() async {
    List<String> ports = [];
    try {
      if (_isAndroid) {
        _androidDevices = await _fsc.getAvailableDevices();
        ports = _androidDevices.map((d) => d.deviceName).toList();
        for (final d in _androidDevices) {
          final vid = d.vendorId?.toRadixString(16).toUpperCase();
          final pid = d.productId?.toRadixString(16).toUpperCase();
          _addLog('🔍 ${d.deviceName}\n'
              '     VID=0x$vid PID=0x$pid\n'
              '     mfg=${d.manufacturerName} product=${d.productName}');
        }
      } else {
        ports = SerialPort.availablePorts.toList();
      }
    } catch (e) {
      _addLog('❌ list ports error: $e');
    }

    setState(() {
      _ports = ports;
      if (_selectedPort == null || !ports.contains(_selectedPort)) {
        _selectedPort = ports.isNotEmpty ? ports.first : null;
      }
    });
    _addLog('🔄 พบ ${ports.length} port: $ports');
  }

  // ---------------- connect ----------------
  Future<void> _connect() async {
    if (_selectedPort == null) {
      _addLog('⚠ ยังไม่ได้เลือก port');
      return;
    }
    await _disconnect();

    if (_isAndroid) {
      await _connectAndroid(_selectedPort!);
    } else {
      _connectWindows(_selectedPort!);
    }
  }

  // ---------------- Windows ----------------
  void _connectWindows(String portName) {
    try {
      _addLog('🔌 เปิด $portName baud=$_baudRate');
      final port = SerialPort(portName);
      if (!port.openReadWrite()) {
        _addLog('❌ เปิด port ไม่สำเร็จ');
        return;
      }
      final cfg = port.config;
      cfg.baudRate = _baudRate;
      cfg.bits = 8;
      cfg.parity = SerialPortParity.none;
      cfg.stopBits = 1;
      port.config = cfg;

      _winPort = port;
      setState(() {
        _connected = true;
        _status = 'เชื่อมต่อแล้ว: $portName @ $_baudRate';
      });
      _addLog('✅ CONNECTED $portName');

      _winPoll = Timer.periodic(const Duration(milliseconds: 20), (_) {
        final p = _winPort;
        if (p == null || !p.isOpen) return;
        try {
          final available = p.bytesAvailable;
          if (available <= 0) return;
          final data = p.read(available, timeout: 0);
          if (data.isEmpty) return;
          _onBytes(data);
        } catch (e) {
          _addLog('⚠ read error: $e');
        }
      });
    } catch (e) {
      _addLog('❌ exception: $e');
    }
  }

  // ---------------- Android ----------------
  Future<void> _connectAndroid(String deviceName) async {
    try {
      DeviceInfo? target;
      for (final d in _androidDevices) {
        if (d.deviceName == deviceName) {
          target = d;
          break;
        }
      }
      if (target == null) {
        _addLog('❌ ไม่พบ device: $deviceName');
        return;
      }

      _addLog('🔌 connect ${target.productName} baud=$_baudRate');
      final ok = await _fsc.connect(target, _baudRate);
      if (!ok) {
        _addLog('❌ connect ไม่สำเร็จ (permission?)');
        return;
      }

      // 8-N-1
      await _fsc.setParameters(_baudRate, 8, 1, 0);
      await _fsc.setDTR(_dtr);
      await _fsc.setRTS(_rts);
      _addLog('⚙ 8-N-1  DTR=$_dtr RTS=$_rts');

      // ฟังข้อมูลเข้า (event stream — ไม่ค้าง buffer)
      _msgSub = _fsc
          .getSerialMessageListener()
          .receiveBroadcastStream()
          .listen((event) {
        final List<int> data =
            (event is List<int>) ? event : List<int>.from(event as List);
        _onBytes(data);
      }, onError: (e) => _addLog('⚠ msg stream error: $e'));

      // ฟังสถานะการเชื่อมต่อ
      _connSub = _fsc
          .getDeviceConnectionListener()
          .receiveBroadcastStream()
          .listen((event) {
        final isConn = event == true;
        if (mounted) {
          setState(() {
            _connected = isConn;
            _status = isConn
                ? 'เชื่อมต่อแล้ว: $deviceName @ $_baudRate'
                : 'หลุดการเชื่อมต่อ';
          });
        }
        _addLog(isConn ? '🔗 device connected' : '🔌 device disconnected');
      });

      setState(() {
        _connected = true;
        _status = 'เชื่อมต่อแล้ว: $deviceName @ $_baudRate';
      });
      _addLog('✅ CONNECTED $deviceName');
    } catch (e) {
      _addLog('❌ exception: $e');
    }
  }

  // ---------------- รับ byte ----------------
  void _onBytes(List<int> data) {
    if (data.isEmpty) return;

    final str = String.fromCharCodes(data);
    final hex = data
        .map((b) => b.toRadixString(16).toUpperCase().padLeft(2, '0'))
        .join(' ');
    _addLog('📦 chunk "$str"  [${data.length}B]\n     HEX: $hex');

    // ประกอบบรรทัดเต็ม: chunk อาจมาแยกหลายก้อน รวมจน \r หรือ \n
    _rxBuf.write(str);
    var raw = _rxBuf.toString();
    int nl;
    while ((nl = raw.indexOf(RegExp(r'[\r\n]'))) >= 0) {
      final line = raw.substring(0, nl).trim();
      raw = raw.substring(nl + 1);
      if (line.isNotEmpty) _addLog('✅ LINE -> $line');
    }
    _rxBuf
      ..clear()
      ..write(raw);
  }

  // ---------------- disconnect ----------------
  Future<void> _disconnect() async {
    // Windows
    _winPoll?.cancel();
    _winPoll = null;
    _winPort?.close();
    _winPort = null;

    // Android
    await _msgSub?.cancel();
    _msgSub = null;
    await _connSub?.cancel();
    _connSub = null;
    if (_isAndroid) {
      try {
        await _fsc.disconnect();
      } catch (_) {}
    }

    _rxBuf.clear();

    if (mounted) {
      setState(() {
        _connected = false;
        _status = 'ยังไม่เชื่อมต่อ';
      });
    }
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Serial Test (baud 9600)'),
        actions: [
          IconButton(
            onPressed: _refreshPorts,
            icon: const Icon(Icons.refresh),
            tooltip: 'รีเฟรช port',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // เลือก port
            Row(
              children: [
                Expanded(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedPort,
                    hint: const Text('เลือก port'),
                    items: _ports
                        .map((p) =>
                            DropdownMenuItem(value: p, child: Text(p)))
                        .toList(),
                    onChanged: _connected
                        ? null
                        : (v) => setState(() => _selectedPort = v),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _connected ? _disconnect : _connect,
                  icon: Icon(_connected ? Icons.link_off : Icons.link),
                  label: Text(_connected ? 'Disconnect' : 'Connect'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _connected ? Colors.red : Colors.teal,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // สถานะ
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color:
                    _connected ? Colors.green.shade50 : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    _connected ? Icons.check_circle : Icons.circle_outlined,
                    color: _connected ? Colors.green : Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_status)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // สวิตช์ DTR/RTS (เฉพาะ Android)
            if (_isAndroid)
              Row(
                children: [
                  const Text('Flow control: '),
                  Switch(
                    value: _dtr,
                    onChanged: (v) {
                      setState(() => _dtr = v);
                      if (_connected) {
                        _fsc.setDTR(v);
                        _addLog('⚙ DTR=$v');
                      }
                    },
                  ),
                  const Text('DTR'),
                  const SizedBox(width: 12),
                  Switch(
                    value: _rts,
                    onChanged: (v) {
                      setState(() => _rts = v);
                      if (_connected) {
                        _fsc.setRTS(v);
                        _addLog('⚙ RTS=$v');
                      }
                    },
                  ),
                  const Text('RTS'),
                ],
              ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('ค่าที่รับได้ (${_log.length})',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                TextButton.icon(
                  onPressed: () => setState(() => _log.clear()),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('ล้าง'),
                ),
              ],
            ),
            // log
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.builder(
                  controller: _scroll,
                  itemCount: _log.length,
                  itemBuilder: (_, i) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: SelectableText(
                      _log[i],
                      style: const TextStyle(
                        color: Colors.greenAccent,
                        fontFamily: 'monospace',
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
