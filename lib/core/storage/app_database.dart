import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class AppDatabase {
  AppDatabase(this._preferences);

  final SharedPreferences _preferences;

  static Future<AppDatabase> create() async {
    final preferences = await SharedPreferences.getInstance();
    return AppDatabase(preferences);
  }

  String? readString(String key) => _preferences.getString(key);

  Future<void> writeString(String key, String value) async {
    await _preferences.setString(key, value);
  }

  List<Map<String, dynamic>> readJsonList(String key) {
    final raw = _preferences.getString(key);
    if (raw == null) {
      return const [];
    }
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded.cast<Map<String, dynamic>>();
  }

  Future<void> writeJsonList(String key, List<Map<String, dynamic>> value) async {
    await _preferences.setString(key, jsonEncode(value));
  }

  Map<String, dynamic>? readJsonObject(String key) {
    final raw = _preferences.getString(key);
    if (raw == null) {
      return null;
    }
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> writeJsonObject(String key, Map<String, dynamic> value) async {
    await _preferences.setString(key, jsonEncode(value));
  }
}
