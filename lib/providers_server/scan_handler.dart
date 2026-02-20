import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/patient_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/kiosk_state_provider.dart';
import '../models/working_mode.dart';

class ScanHandler {
  Future<void> handle(
    BuildContext context,
    String value,
  ) async {
    final hn = value.trim();
    if (hn.isEmpty) return;

    final patient = context.read<PatientProvider>();
    final settings = context.read<SettingsProvider>();
    final auth = context.read<AuthProvider>();
    final kiosk = context.read<KioskStageProvider>();

    final success = await patient.fetchByHn(
      hn: hn,
      settings: settings,
      auth: auth,
    );

    if (!context.mounted) return;

    if (success) {
      if (settings.workingMode == WorkingMode.combined) {
        kiosk.setStage(KioskStage.measureCombined);
      } else {
        kiosk.setStage(KioskStage.measure);
      }
    } else {
      kiosk.setStage(KioskStage.scanError);
    }
  }
}
