import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class Tweaks {
  final Map<String, double> _values = {};

  double get(String key) => _values[key] ?? 0;

  Future<void> load(String assetPath) async {
    final raw = await rootBundle.loadString(assetPath);
    final Map<String, dynamic> parsed = jsonDecode(raw);
    for (final entry in parsed.entries) {
      final node = entry.value as Map<String, dynamic>;
      _values[entry.key] = (node["value"] as num).toDouble();
    }
  }
}

class GameSettings {
  late double baseSpeed;
  late double jumpForce;
  late double gravity;
  late double spawnInterval;
  late double levelDistance;
  late double magnetDuration;
  late double effectsIntensity;
  late double comboWindow;
  late double rareCoinChance;

  GameSettings.fromTweaks(Tweaks tweaks) {
    baseSpeed = tweaks.get("baseSpeed");
    jumpForce = tweaks.get("jumpForce");
    gravity = tweaks.get("gravity");
    spawnInterval = tweaks.get("spawnInterval");
    levelDistance = tweaks.get("levelDistance");
    magnetDuration = tweaks.get("magnetDuration");
    effectsIntensity = tweaks.get("effectsIntensity");
    comboWindow = tweaks.get("comboWindow");
    rareCoinChance = tweaks.get("rareCoinChance");
  }
}
