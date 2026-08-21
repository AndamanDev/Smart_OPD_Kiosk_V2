import 'package:flutter/material.dart';
import '../models/device_models.dart';

class BloodReading {
  final int systolic;
  final int diastolic;
  final int map;   // Mean Arterial Pressure
  final int pulse;

  const BloodReading({
    required this.systolic,
    required this.diastolic,
    this.map = 0,
    required this.pulse,
  });

  bool get isEmpty => systolic == 0 && diastolic == 0 && pulse == 0;

  /// คำนวณ MAP ถ้าไม่มีค่า (MAP = (SYS + 2×DIA) / 3)
  int get mapValue => map > 0 ? map : ((systolic + 2 * diastolic) ~/ 3);
}

class BloodPressureUtils {

  static BloodReading parse(String raw) {
    final parts = raw.split(',');

    if (parts.length < 10) {
      debugPrint("Invalid packet: $raw");
      return const BloodReading(systolic: 0, diastolic: 0, pulse: 0);
    }

    final sys = int.tryParse(parts[7].trim());
    final dia = int.tryParse(parts[8].trim());
    final pul = int.tryParse(parts[9].trim());

    if (sys == null || dia == null || pul == null) {
      debugPrint("Parse error: $raw");
      return const BloodReading(systolic: 0, diastolic: 0, pulse: 0);
    }

    return BloodReading(
      systolic: sys,
      diastolic: dia,
      pulse: pul,
    );
  }

  /// ---- Terumo BR-500 ----
  /// Packet: <STX>R1,PATID,DDMMYY,HHMMSS,SYS,MAP,DIA,PUL,...<ETX>[BCC]
  /// ตรวจสอบด้วย formula: MAP = (SYS + 2×DIA) / 3
  ///   131, 090, 069, 092 → SYS=131, MAP=090, DIA=069, PUL=092
  ///   (131 + 2×69) / 3 = 89.7 ≈ 90 ✅
  /// fields: [0]=R1 [1]=PatID [2]=Date [3]=Time [4]=SYS [5]=MAP [6]=DIA [7]=Pulse
  static BloodReading parseTerumo(String raw) {
    // ตัด STX(0x02), ETX(0x03), control bytes และ BCC/high bytes (เช่น 0xED)
    // เก็บเฉพาะ printable ASCII เพื่อกันเศษ BCC ติดมากับ parts[0] แล้ว startsWith('R') พลาด
    final cleaned = raw.replaceAll(RegExp(r'[^\x20-\x7E]'), '').trim();
    final parts = cleaned.split(',');

    debugPrint("🩺 Terumo parts: $parts");

    if (parts.length < 8) {
      debugPrint("❌ Terumo: packet too short (${parts.length} fields)");
      return const BloodReading(systolic: 0, diastolic: 0, pulse: 0);
    }

    if (!parts[0].trim().startsWith('R')) {
      debugPrint("❌ Terumo: not a result record (${parts[0]})");
      return const BloodReading(systolic: 0, diastolic: 0, pulse: 0);
    }

    final sys = int.tryParse(parts[4].trim()); // SYS
    final map = int.tryParse(parts[5].trim()); // MAP  ← [5]
    final dia = int.tryParse(parts[6].trim()); // DIA  ← [6] (ไม่ใช่ [5])
    final pul = int.tryParse(parts[7].trim()); // Pulse

    if (sys == null || dia == null || pul == null) {
      debugPrint("❌ Terumo parse error: sys=$sys dia=$dia pul=$pul");
      return const BloodReading(systolic: 0, diastolic: 0, pulse: 0);
    }

    debugPrint("✅ Terumo: SYS=$sys MAP=$map DIA=$dia PUL=$pul");
    return BloodReading(
      systolic: sys,
      diastolic: dia,
      map: map ?? ((sys + 2 * dia) ~/ 3),
      pulse: pul,
    );
  }

  /// เลือก parser ตาม device ที่ใช้งาน
  static BloodReading parseByDevice(String raw, BloodPressureDevice device) {
    switch (device) {
      case BloodPressureDevice.terumoBR500:
        return parseTerumo(raw);
      default:
        return parse(raw);
    }
  }

  /// ---------- Validation ----------
  static bool isValid(int s, int d, int p) {
    if (s < 60 || s > 250) return false;
    if (d < 30 || d > 150) return false;
    if (p < 30 || p > 200) return false;
    return true;
  }

  /// ---------- Colors ----------
  static Color sysColor(int v, int max) {
    if (v == 0) return Colors.grey;
    if (v < (max - 20)) return Colors.green;
    if (v < max) return Colors.orange;
    return Colors.red;
  }

  static Color diaColor(int v) {
    if (v == 0) return Colors.grey;
    if (v < 80) return Colors.green;
    if (v < 90) return Colors.orange;
    return Colors.red;
  }

  static Color pulseColor(int v) {
    if (v == 0) return Colors.grey;
    if (v < 60 || v > 100) return Colors.orange;
    return Colors.green;
  }
}
