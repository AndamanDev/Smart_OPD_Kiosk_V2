import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'auth_provider.dart';
import 'settings_provider.dart';

/// ตรวจสอบการเชื่อมต่อ 2 อย่างเป็นระยะ ๆ:
///   1. มีอินเทอร์เน็ตไหม  → TCP ไป public DNS
///   2. IP Server เข้าได้ไหม → TCP ไป host:port ที่ระบุใน settings.serverIp
/// ต้องผ่าน "ทั้งคู่" ถึงจะถือว่า connected (แสดง "เชื่อมต่อแล้ว")
class ServerStatusProvider extends ChangeNotifier {
  final SettingsProvider settings;

  Timer? _timer;
  bool _checking = false;
  bool _disposed = false;

  /// ใช้ enum เดียวกับ AuthProvider เพื่อให้ UI ด้านล่างแสดงผลได้เหมือนเดิม
  AuthConnectionState state = AuthConnectionState.reconnecting;

  /// สถานะย่อยของแต่ละอย่าง (ไว้ให้ UI แสดงรายละเอียด/ดีบั๊ก)
  bool hasInternet = false;
  bool serverReachable = false;

  /// ปลายทางสำหรับเช็คอินเทอร์เน็ต — ใช้ TCP ตรงไปที่ IP (ไม่ผ่าน DNS lookup)
  /// เพื่อกันผลลวงจาก DNS cache; ลองตัวถัดไปถ้าตัวแรกไม่ผ่าน
  static const List<(String, int)> _internetProbes = [
    ('8.8.8.8', 53), // Google DNS
    ('1.1.1.1', 53), // Cloudflare DNS
  ];

  static const Duration _probeTimeout = Duration(seconds: 3);

  ServerStatusProvider(this.settings);

  /// เริ่มตรวจสอบเป็นระยะ (ทุก 10 วินาที) + เช็คทันที 1 ครั้ง
  void start() {
    _timer ??= Timer.periodic(
      const Duration(seconds: 10),
      (_) => _check(),
    );
    _check();
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  /// เรียกให้เช็คทันที (เช่น หลังกด Save ตั้งค่า IP ใหม่)
  Future<void> refresh() => _check();

  Future<void> _check() async {
    if (_checking || _disposed) return;
    _checking = true;

    try {
      // เช็คพร้อมกันทั้งคู่ เพื่อไม่ต้องรอต่อคิวกัน
      final results = await Future.wait([_checkInternet(), _pingServer()]);
      if (_disposed) return;

      final prevInternet = hasInternet;
      final prevServer = serverReachable;

      hasInternet = results[0];
      serverReachable = results[1];

      // ⭐ ต้องได้ทั้ง "อินเทอร์เน็ต" และ "IP Server" ถึงจะถือว่าเชื่อมต่อแล้ว
      final next = (hasInternet && serverReachable)
          ? AuthConnectionState.connected
          : AuthConnectionState.disconnected;

      if (next != state ||
          prevInternet != hasInternet ||
          prevServer != serverReachable) {
        state = next;
        notifyListeners();
      }
    } finally {
      _checking = false;
    }
  }

  /// ลองเปิด TCP socket ไปยัง host:port — ใช้ร่วมกันทั้งเช็คเน็ตและเช็ค Server
  Future<bool> _tcpProbe(String host, int port) async {
    Socket? socket;
    try {
      socket = await Socket.connect(host, port, timeout: _probeTimeout);
      return true;
    } catch (_) {
      return false;
    } finally {
      socket?.destroy();
    }
  }

  /// 1) เช็คว่าออกอินเทอร์เน็ตได้จริงไหม (ผ่านตัวใดตัวหนึ่งก็ถือว่าผ่าน)
  Future<bool> _checkInternet() async {
    for (final (host, port) in _internetProbes) {
      if (_disposed) return false;
      if (await _tcpProbe(host, port)) return true;
    }
    return false;
  }

  /// 2) เช็คว่า IP Server ที่ตั้งค่าไว้เข้าได้ไหม
  Future<bool> _pingServer() async {
    final raw = settings.serverIp.trim();
    if (raw.isEmpty) return false;

    // รองรับทั้ง "192.168.1.10", "192.168.1.10:8080" และ "http(s)://..."
    final normalized = raw.startsWith('http') ? raw : 'http://$raw';

    final Uri uri;
    try {
      uri = Uri.parse(normalized);
    } catch (_) {
      return false;
    }

    final host = uri.host;
    if (host.isEmpty) return false;

    final port = uri.hasPort ? uri.port : (uri.scheme == 'https' ? 443 : 80);

    return _tcpProbe(host, port);
  }

  @override
  void dispose() {
    _disposed = true;
    stop();
    super.dispose();
  }
}
