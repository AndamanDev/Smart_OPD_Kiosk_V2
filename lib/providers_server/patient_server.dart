import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../api_env.dart';

class PatientServer {
  static Future<Map<String, dynamic>?> getPatientByHn({
    required String baseUrl,
    required String hn,
    required String accessToken,
  }) async {
    try {
      final value = hn.trim();

      final isIdCard = RegExp(r'^\d{13}$').hasMatch(value);

      final queryKey = isIdCard ? 'id_card' : 'HN';

      final uri = Uri.parse(
        '$baseUrl${ApiEnv.getPatient}',
      ).replace(queryParameters: {queryKey: value});

      final res = await http
          .post(
            uri,
            headers: {
              HttpHeaders.authorizationHeader: 'Bearer $accessToken',
              HttpHeaders.contentTypeHeader: 'application/json',
            },
            body: jsonEncode({queryKey: value}),
          )
          .timeout(const Duration(seconds: 5));

      print(res.statusCode);

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
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
