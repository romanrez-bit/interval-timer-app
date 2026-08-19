import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Хранит настройки приложения.
/// Чтобы добавить новую настройку: добавить ключ, поле, геттер и сеттер
/// по образцу существующих.
class SettingsService extends ChangeNotifier {
  SettingsService._internal();
  static final SettingsService instance = SettingsService._internal();

  static const _keySound = 'sound_enabled';
  static const _keyVibration = 'vibration_enabled';
  static const _keyNotifications = 'notifications_enabled';

  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _notificationsEnabled = true;
  bool _loaded = false;

  bool get soundEnabled => _soundEnabled;
  bool get vibrationEnabled => _vibrationEnabled;
  bool get notificationsEnabled => _notificationsEnabled;

  Future<void> init() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    _soundEnabled = prefs.getBool(_keySound) ?? true;
    _vibrationEnabled = prefs.getBool(_keyVibration) ?? true;
    _notificationsEnabled = prefs.getBool(_keyNotifications) ?? true;
    _loaded = true;
  }

  Future<void> setNotificationsEnabled(bool value) async {
    _notificationsEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNotifications, value);
  }

  Future<void> setSoundEnabled(bool value) async {
    _soundEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keySound, value);
  }

  Future<void> setVibrationEnabled(bool value) async {
    _vibrationEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyVibration, value);
  }
}