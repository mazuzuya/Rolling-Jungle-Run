import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'config.dart';

class SaveStore {
  static const String _key = 'tumbletail_save_v1';

  Future<GameSave> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return GameSave();
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return GameSave.fromJson(map);
    } catch (_) {
      return GameSave();
    }
  }

  Future<void> persist(GameSave save) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(save.toJson()));
  }
}
