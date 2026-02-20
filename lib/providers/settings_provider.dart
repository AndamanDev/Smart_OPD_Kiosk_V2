import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/working_mode.dart';
import '../models/sound_mode.dart';
import '../models/display_mode.dart';
import '../models/device_models.dart';

class SettingsProvider extends ChangeNotifier {
  // -------- เพิ่มตัวแปรขีดจำกัด (Thresholds) --------
  int sysMax = 140;   // ค่าความดันบนสูงสุด
  int diaMax = 90;    // ค่าความดันล่างสูงสุด
  int pulseMin = 60;  // ชีพจรต่ำสุด
  int pulseMax = 100; // ชีพจรสูงสุด

  // -------- Mode --------
  WorkingMode workingMode = WorkingMode.combined;

  // -------- Sound / Display --------
  SoundMode soundMode = SoundMode();
  DisplayMode displayMode = const DisplayMode();

  // -------- Devices --------
  BloodPressureDevice bpDevice = BloodPressureDevice.andTM2655;
  String bpPort = '';

  ScaleDevice scaleDevice = ScaleDevice.bam205A;
  String scaleReadPort = '';
  String scaleControlPort = '';

  // -------- Server --------
  String serverIp = '';
  String username = '';
  String password = '';
  String deviceName = '';

  // -------- Delay Setting --------
  int delayBPSeconds = 180; 
  int delayScaleSeconds = 180; 

  Future<void> save({
    int? sysMax,
    int? diaMax,
    int? pulseMin,
    int? pulseMax,
    int? delayBPSeconds,
    int? delayScaleSeconds,

    required WorkingMode workingMode,
    required SoundMode soundMode,
    required DisplayMode displayMode,

    required BloodPressureDevice bpDevice,
    required String bpPort,

    required ScaleDevice scaleDevice,
    required String scaleReadPort,
    required String scaleControlPort,

    required String serverIp,
    required String username,
    required String password,
    required String deviceName,
  }) async {
    if (sysMax != null) this.sysMax = sysMax;
    if (diaMax != null) this.diaMax = diaMax;
    if (pulseMin != null) this.pulseMin = pulseMin;
    if (pulseMax != null) this.pulseMax = pulseMax;
    if (delayBPSeconds != null) { this.delayBPSeconds = delayBPSeconds; }
    if (delayScaleSeconds != null) { this.delayScaleSeconds = delayScaleSeconds; }

    // update state
    this.workingMode = workingMode;
    this.soundMode = soundMode;
    this.displayMode = displayMode;

    this.bpDevice = bpDevice;
    this.bpPort = bpPort;

    this.scaleDevice = scaleDevice;
    this.scaleReadPort = scaleReadPort;
    this.scaleControlPort = scaleControlPort;

    this.serverIp = serverIp;
    this.username = username;
    this.password = password;
    this.deviceName = deviceName;

    // persist
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('workingMode', workingMode.name);

    await prefs.setBool('sound_bell', soundMode.bellSound);
    await prefs.setBool('sound_thai', soundMode.thaiVoice);

    await prefs.setBool('display_resultColor', displayMode.showResultColors);

    await prefs.setString('bpDevice', bpDevice.name);
    await prefs.setString('bpPort', bpPort);

    await prefs.setString('scaleDevice', scaleDevice.name);
    await prefs.setString('scaleReadPort', scaleReadPort);
    await prefs.setString('scaleControlPort', scaleControlPort);

    await prefs.setString('serverIp', serverIp);
    await prefs.setString('username', username);
    await prefs.setString('password', password);
    await prefs.setString('deviceName', deviceName);

    await prefs.setInt('sysMax', this.sysMax);
    await prefs.setInt('diaMax', this.diaMax);
    await prefs.setInt('pulseMin', this.pulseMin);
    await prefs.setInt('pulseMax', this.pulseMax);

    await prefs.setInt('delayBPSeconds', this.delayBPSeconds);
    await prefs.setInt('delayScaleSeconds', this.delayScaleSeconds);

    notifyListeners();
  }

  Future<void> loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();

    workingMode = WorkingMode.values.firstWhere(
      (e) => e.name == prefs.getString('workingMode'),
      orElse: () => WorkingMode.combined,
    );

    soundMode = SoundMode(
      bellSound: prefs.getBool('sound_bell') ?? true,
      thaiVoice: prefs.getBool('sound_thai') ?? true,
    );

    displayMode = DisplayMode(
      showResultColors: prefs.getBool('display_resultColor') ?? true,
    );

    bpDevice = BloodPressureDevice.values.firstWhere(
      (e) => e.name == prefs.getString('bpDevice'),
      orElse: () => BloodPressureDevice.andTM2655,
    );
    bpPort = prefs.getString('bpPort') ?? '';

    scaleDevice = ScaleDevice.values.firstWhere(
      (e) => e.name == prefs.getString('scaleDevice'),
      orElse: () => ScaleDevice.bam205A,
    );
    scaleReadPort = prefs.getString('scaleReadPort') ?? '';
    scaleControlPort = prefs.getString('scaleControlPort') ?? '';

    serverIp = prefs.getString('serverIp') ?? '';
    username = prefs.getString('username') ?? '';
    password = prefs.getString('password') ?? '';
    deviceName = prefs.getString('deviceName') ?? '';

    sysMax = prefs.getInt('sysMax') ?? 140;
    diaMax = prefs.getInt('diaMax') ?? 90;
    pulseMin = prefs.getInt('pulseMin') ?? 60;
    pulseMax = prefs.getInt('pulseMax') ?? 100;

    delayBPSeconds = prefs.getInt('delaySeconds') ?? 180;
    delayScaleSeconds = prefs.getInt('delaySeconds') ?? 180;

    notifyListeners();
  }
}
