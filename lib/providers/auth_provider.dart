import 'package:flutter/material.dart';
import '../providers_server/auth_server.dart';
import 'settings_provider.dart';

class AuthProvider extends ChangeNotifier {
  String? token;
  String? tokenName;
  DateTime? tokenExpiry;
  bool isLoading = false;
  String? errorMessage;

  bool _didAutoLogin = false;

  bool get isLoggedIn => token != null;

  bool get isTokenExpired {
    if (tokenExpiry == null) return true;
    return DateTime.now().isAfter(tokenExpiry!);
  }

  Future<bool> autoLogin(SettingsProvider settings) async {
    if (_didAutoLogin) return isLoggedIn;
    _didAutoLogin = true;

    return await _login(settings);
  }

  Future<bool> ensureValidToken(SettingsProvider settings) async {
    if (token != null && !isTokenExpired) {
      return true;
    }

    return await _login(settings);
  }

  Duration _parseExpiry(String value) {
    final v = value.trim().toLowerCase();

    if (v.endsWith('h')) {
      return Duration(hours: int.parse(v.replaceAll('h', '')));
    }
    if (v.endsWith('m')) {
      return Duration(minutes: int.parse(v.replaceAll('m', '')));
    }
    if (v.endsWith('s')) {
      return Duration(seconds: int.parse(v.replaceAll('s', '')));
    }

    // fallback
    return Duration(hours: 24);
  }

  Future<bool> _login(SettingsProvider settings) async {
    if (settings.serverIp.isEmpty ||
        settings.username.isEmpty ||
        settings.password.isEmpty) {
      return false;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {

      print("auto login test");

      final result = await AuthService.login(
        serverIp: settings.serverIp,
        username: settings.username,
        password: settings.password,
      );


      token = result.token;
      tokenName = result.name;

      tokenExpiry = DateTime.now().add(_parseExpiry(result.expiresIn));
      print("Token expires at: $tokenExpiry");
      return true;
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      token = null;
      tokenExpiry = null;
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

Future<void> logout() async {
    token = null;
    tokenName = null;
    tokenExpiry = null;
    _didAutoLogin = false;
    notifyListeners();
  }
}
