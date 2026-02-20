import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../api_env.dart';

class VitalsServer {
  static Future<void> sendVitals({
    required String baseUrl,
    required String accessToken,
    required Map<String, dynamic> payload,
  }) async {
    final uri = Uri.parse('$baseUrl${ApiEnv.saveToVitals}');

    print("===== SEND VITALS =====");
    print("URL: $uri");
    print("TOKEN: $accessToken");
    print("PAYLOAD:");
    print(jsonEncode(payload));

    final res = await http
        .post(
          uri,
          headers: {
            HttpHeaders.authorizationHeader: 'Bearer $accessToken',
            HttpHeaders.contentTypeHeader: 'application/json',
          },
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 5));

    // ✅ Print response
    print("===== RESPONSE =====");
    print("STATUS: ${res.statusCode}");
    print("BODY:");
    print(res.body);

    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception("ส่งข้อมูล vitals ไม่สำเร็จ (${res.statusCode})");
    }
  }
}
