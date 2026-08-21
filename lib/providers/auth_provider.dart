import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'settings_provider.dart';

enum AuthConnectionState {
  connected,
  reconnecting,
  disconnected,
}

class AuthProvider extends ChangeNotifier {
  /// token เก็บ accessKey (ใช้เพื่อเช็ค isLoggedIn)
  String? token;
  String? tokenName;
  DateTime? tokenExpiry;

  bool isLoading = false;
  String? errorMessage;

  bool _didAutoLogin = false;

  AuthConnectionState connectionState = AuthConnectionState.connected;

  bool get isLoggedIn => token != null;

  bool get isTokenExpired {
    if (tokenExpiry == null) return true;
    return DateTime.now().isAfter(tokenExpiry!);
  }

  void setConnectionState(AuthConnectionState state) {
    connectionState = state;
    notifyListeners();
  }

  /// สร้าง HMAC-SHA256 headers สำหรับ request
  /// method   : "GET" | "POST" | "PUT" | "DELETE"
  /// path     : เส้นทาง API เช่น "/emr-bc/v1/external-smart-opd-patients"
  /// secretKey: ค่าจาก settings.secretKey
  /// body     : request body string (ถ้าไม่มีให้ส่ง '')
  static Map<String, String> buildHmacHeaders({
    required String accessKey,
    required String secretKey,
    required String method,
    required String path,
    String body = '',
  }) {
    // trim ป้องกัน whitespace แอบซ่อน
    final cleanAccessKey = accessKey.trim();
    final cleanSecretKey = secretKey.trim();
    final cleanMethod = method.trim().toUpperCase();
    // path ต้องขึ้นต้นด้วย / และไม่มี trailing slash (ยกเว้น root)
    String cleanPath = path.trim();
    if (!cleanPath.startsWith('/')) cleanPath = '/$cleanPath';
    if (cleanPath.length > 1 && cleanPath.endsWith('/')) {
      cleanPath = cleanPath.substring(0, cleanPath.length - 1);
    }

    final timestamp = DateTime.now()
        .toUtc()
        .toIso8601String()
        .replaceFirst(RegExp(r'\.\d+Z$'), 'Z');

    final bodyHash = sha256.convert(utf8.encode(body)).toString();

    final stringToSign = '$cleanMethod\n$cleanPath\n$timestamp\n$bodyHash';

    final hmacSha256 = Hmac(sha256, utf8.encode(cleanSecretKey));
    final signature =
        hmacSha256.convert(utf8.encode(stringToSign)).toString();

    print('===== HMAC AUTH HEADERS =====');
    print('Method: $cleanMethod');
    print('Path: $cleanPath');
    print('String to Sign: ${jsonEncode(stringToSign)}');
    print('Body Hash: $bodyHash');
    print('X-Access-Key-Id: $cleanAccessKey');
    print('X-Timestamp: $timestamp');
    print('X-Signature: $signature');
    print('Secret Key length: ${cleanSecretKey.length}');

    // GET request ไม่ต้องส่ง content-type
    final headers = <String, String>{
      'X-Access-Key-Id': cleanAccessKey,
      'X-Timestamp': timestamp,
      'X-Signature': signature,
    };
    if (cleanMethod != 'GET') {
      headers[HttpHeaders.contentTypeHeader] = 'application/json';
    }
    return headers;
  }

  /// ตรวจสอบ accessKey/secretKey แล้ว set connected (ไม่มี network call)
  Future<bool> autoLogin(SettingsProvider settings) async {
    if (_didAutoLogin) return isLoggedIn;
    _didAutoLogin = true;
    return _login(settings);
  }

  Future<bool> ensureValidToken(SettingsProvider settings) async {
    if (token != null && !isTokenExpired) {
      return true;
    }
    return _login(settings);
  }

  Future<bool> _login(SettingsProvider settings) async {
    if (settings.serverIp.isEmpty || settings.accessKey.isEmpty) {
      errorMessage = 'กรุณาตั้งค่า IP Server และ Access Key';
      return false;
    }

    isLoading = true;
    notifyListeners();

    try {
      // ใช้ HMAC แทน username/password — ไม่ต้อง login API
      token = settings.accessKey;
      tokenName = 'HMAC Auth';
      tokenExpiry = DateTime.now().add(const Duration(hours: 24));

      setConnectionState(AuthConnectionState.connected);
      return true;
    } catch (e) {
      token = null;
      tokenExpiry = null;
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    token = null;
    tokenName = null;
    tokenExpiry = null;
    _didAutoLogin = false;
    setConnectionState(AuthConnectionState.disconnected);
  }
}
