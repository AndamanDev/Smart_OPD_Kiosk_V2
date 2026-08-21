import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class PatientServer {
  static Future<Map<String, dynamic>?> getPatientByHn({
    required String baseUrl,
    required String getpatients,
    required String hn,
    required Map<String, String> headers,
  }) async {
    try {
      final value = hn.trim();

      final isIdCard = RegExp(r'^\d{13}$').hasMatch(value);

      // API ต้องการ hn (ตัวเล็ก) และ national_id สำหรับบัตรประชาชน
      final queryKey = isIdCard ? 'national_id' : 'hn';

      // ใช้ GET + query string เท่านั้น (ไม่ส่ง body)
      final uri = Uri.parse('$baseUrl$getpatients')
          .replace(queryParameters: {queryKey: value});

      print("===== GET PATIENT =====");
      print("URL: $uri");
      print("HEADERS: $headers");

      final res = await http.get(uri, headers: headers);

      print(res.statusCode);
      print(res.body);

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);

        // รองรับโครงสร้าง { data: { attributes: {...} } }
        Map<String, dynamic> attrs;
        if (json['data'] != null && json['data']['attributes'] != null) {
          attrs = Map<String, dynamic>.from(json['data']['attributes']);
        } else {
          attrs = Map<String, dynamic>.from(json);
        }

        // normalize field names ให้ตรงกับที่แอปใช้
        final firstName = (attrs['first_name'] ?? '').toString().trim();
        final lastName = (attrs['last_name'] ?? '').toString().trim();
        final fullname = '$firstName $lastName'.trim();

        if (fullname.isEmpty) return null;

        return {
          'FULLNAME': fullname,
          'HN': attrs['hn'] ?? attrs['HN'] ?? '',
          'NATIONAL_ID': attrs['national_id'] ?? '',
          'TITLE': attrs['title'] ?? '',
          'FIRST_NAME': firstName,
          'LAST_NAME': lastName,
          'BIRTH_DATE': attrs['birth_date'] ?? '',
          'GENDER': attrs['gender'] ?? '',
          'BLOOD_TYPE': attrs['blood_type'] ?? '',
          'PHONE': attrs['phone_main'] ?? '',
          // เก็บ raw ด้วยเผื่อใช้ทีหลัง
          ...attrs,
        };
      }

      if (res.statusCode == 404) {
        throw Exception('ไม่พบข้อมูลผู้ป่วย');
      }

      if (res.statusCode == 401) {
        throw Exception('Token หมดอายุ / Unauthorized');
      }
      throw Exception('Server error (${res.statusCode})');
    } catch (e) {
      debugPrint('ERROR: $e');
      rethrow;
    }
  }
}
