import 'dart:async';
import 'package:flutter/services.dart';

class ThaiIDCardData {
  final String? cid;
  final String? nameTh;
  final String? dob;

  ThaiIDCardData({this.cid, this.nameTh, this.dob});

  factory ThaiIDCardData.fromMap(Map<dynamic, dynamic> map) {
    return ThaiIDCardData(
      cid: map['cid'] as String?,
      nameTh: map['fullname_th'] as String?,
      dob: map['birth_date'] as String?,
    );
  }
}

class SmartCardService {
  static const _method = MethodChannel('com.example.thai_smartcard/method');
  static const _event = EventChannel('com.example.thai_smartcard/events');

  static Stream<Map<dynamic, dynamic>> get eventStream =>
      _event.receiveBroadcastStream().cast<Map<dynamic, dynamic>>();

  static Future<bool> findReader() async {
    return await _method.invokeMethod<bool>('findReader') ?? false;
  }
}