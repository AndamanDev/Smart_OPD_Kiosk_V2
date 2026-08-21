import 'dart:convert';
import 'package:http/http.dart' as http;

class VitalsServer {
  static Future<void> sendVitals({
    required String baseUrl,
    required String savevitalpath,
    required Map<String, String> headers,
    required Map<String, dynamic> payload,
  }) async {
    // final uri = Uri.parse('$baseUrl${ApiEnv.saveToVitals}');
    final uri = Uri.parse('$baseUrl$savevitalpath');

    print("===== SEND VITALS =====");
    print("URL: $uri");
    print("PAYLOAD:");
    print(jsonEncode(payload));

    final res = await http
        .post(
          uri,
          headers: headers,
          body: jsonEncode(payload),
        );
        // .timeout(const Duration(seconds: 5));

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
