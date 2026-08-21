import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class PatientServer {
  static Future<Map<String, dynamic>?> getPatientByHn({
    required String baseUrl,
    required String getpatients,
    required String hn,
    required String accessToken,
  }) async {
    try {
      final value = hn.trim();

      final isIdCard = RegExp(r'^\d{13}$').hasMatch(value);

      final queryKey = isIdCard ? 'id_card' : 'HN';

      // final uri = Uri.parse('$baseUrl${ApiEnv.getPatient}',
      final uri = Uri.parse('$baseUrl$getpatients',
      ).replace(queryParameters: {queryKey: value});

      final res = await http
          .post(
            uri,
            headers: {
              HttpHeaders.authorizationHeader: 'Bearer $accessToken',
              HttpHeaders.contentTypeHeader: 'application/json',
            },
            body: jsonEncode({queryKey: value}),
          );
          // .timeout(const Duration(seconds: 5));

      print(res.statusCode);
      print(res.body);

      if (res.statusCode == 200) {
    
        final json = jsonDecode(res.body);
        if (json['FULLNAME'] == 'null') {
          return null;
        }

        return json;
      }

      if (res.statusCode == 404) {
        throw Exception('ไม่พบข้อมูลผู้ป่วย');
      }

      if (res.statusCode == 401) {
        throw Exception('Token หมดอายุ');
      }
      throw Exception('Server error (${res.statusCode})');
    } catch (e) {
      debugPrint('ERROR: $e');
      rethrow;
    }
  }
}
