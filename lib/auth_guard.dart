import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/kiosk_state_provider.dart';

class AuthGuard {
  /// กัน relogin ซ้อนกันหลายที่
  static Future<bool>? _ongoingLogin;

  static Future<bool> ensureLogin(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final settings = context.read<SettingsProvider>();
    final kiosk = context.read<KioskStageProvider>();

    /// ✅ token ยังใช้ได้
    if (auth.token != null && !auth.isTokenExpired) {
      auth.setConnectionState(AuthConnectionState.connected);
      return true;
    }

    /// ✅ มี login กำลังวิ่งอยู่แล้ว
    if (_ongoingLogin != null) {
      return await _ongoingLogin!;
    }

    debugPrint("🔐 ensureLogin() start relogin");

    auth.setConnectionState(AuthConnectionState.reconnecting);

    _ongoingLogin = auth
        .ensureValidToken(settings)
        .timeout(const Duration(seconds: 15), onTimeout: () => false);

    final success = await _ongoingLogin!;

    _ongoingLogin = null;

    if (success) {
      auth.setConnectionState(AuthConnectionState.connected);
      return true;
    }

    /// ❌ login fail
    auth.setConnectionState(AuthConnectionState.disconnected);
    kiosk.setStage(KioskStage.loginError);

    return false;
  }
}