import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../api_env.dart';
import '../models/auth_models.dart';

class AuthService {
  static Future<AuthResult> login({
    required String serverIp,
    required String username,
    required String password,
  }) async {
    try {
      final baseUrl = serverIp.startsWith('http')
          ? serverIp
          : 'http://$serverIp';

      final uri = Uri.parse('$baseUrl${ApiEnv.deviceLogin}');

      final res = await http
          .post(
            uri,
            headers: {HttpHeaders.contentTypeHeader: 'application/json'},
            body: jsonEncode({'username': username, 'password': password}),
          )
          .timeout(const Duration(seconds: 5));

    print("==== LOGIN RESPONSE ====");
    print("URL: $uri");
    print("STATUS: ${res.statusCode}");
    print("BODY: ${res.body}");
    print("username: ${username}");
    print("password: ${password}");
    print("========================");



      if (res.statusCode == 200) {
        
        final json = jsonDecode(res.body);


        return AuthResult(
          token: json['access_token'],
          name: json['user']['username'] ?? username,
          expiresIn: json['expires_in'],
        );
      }

      if (res.statusCode == 401) {
        throw Exception('Username หรือ Password ไม่ถูกต้อง ${res.body}');
      }

      throw Exception('Server error (${res.statusCode})');
    } on SocketException {
      throw Exception('ไม่สามารถเชื่อมต่อ Server ได้');
    } on TimeoutException {
      throw Exception('Server ตอบสนองช้าเกินไป');
    } catch (e) {
      rethrow; 
    }
  }
}
