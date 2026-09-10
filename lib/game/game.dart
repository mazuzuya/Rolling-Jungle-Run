import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'audio.dart';
import 'atlas.dart';
import 'config.dart';
import 'renderer.dart';
import 'save.dart';
import 'tweaks.dart';
import 'world.dart';

class TumbletailGame extends Game with ChangeNotifier {
  Vector2 _size = Vector2(480, 640);
  Resources? resources;
  World? world;
  GameSettings? settings;
  GameSave save = GameSave();
  final GameAudio audio = GameAudio();
  final SaveStore store = SaveStore();
  final Tweaks tweaks = Tweaks();

  String phase = "loading";
  String toastMessage = "";
  GameResult? lastResult;
  int _toastUntil = 0;
  bool tutorialOpen = false;
  bool _tutorialAuto = false;
  bool _tutorialShown = false;
  bool _tutorialPaused = false;

  // HUD snapshot to avoid notifying every frame.
  int _snapAnts = -1;
  int _snapDistance = -1;
  int _snapLevel = -1;
  int _snapCombo = -1;
  String _snapPhase = "";

  @override
  Future<void> onLoad() async {
    await tweaks.load("assets/json/tweaks.json");
    settings = GameSettings.fromTweaks(tweaks);
    save = await store.load();
    resources = await Resources.load(
      "assets/json/asset_manifest.json",
      skins.map((s) => s.key).toList(),
      levels,
      const [
        "SOFT_OBSTACLES_ATLAS",
        "HARD_OBSTACLES_ATLAS",
        "PICKUP_NEST_ATLAS",
        "ENEMY_SHEET",
        "MOVING_OBSTACLE_SHEET",
        "COIN_SHEET",
        "EXTRA_ENEMY_SHEET",
        "EXTRA_HAZARD_SHEET",
        "EXTENDED_OBSTACLES_ATLAS",
        "TRAVERSAL_PLATFORM_SHEET",
        "LANDMARK_ATLAS",
        "GENTLE_ENEMY_SHEET_A",
        "GENTLE_ENEMY_SHEET_B",
        "RELIC_ATLAS",
      ],
    );
    world = World(
      settings: settings!,
      hooks: WorldHooks(
        sound: (name, [double pitch = 1]) => audio.play(name, pitch),
        haptic: (pattern) => _haptic(),
        toast: (message) => showToast(message),
        levelChange: (level, name) => _onLevelChange(level, name),
        sectionChange: (phase) => _onSectionChange(phase),
        gameOver: (result) => _onGameOver(result),
      ),
    );
    world!.setViewport(size.x, size.y);
    phase = "menu";
    if (save.bestScore == 0 && save.bestDistance == 0 && !_tutorialShown) {
      tutorialOpen = true;
      _tutorialAuto = true;
    }
    notifyListeners();
  }

  @override
  void onGameResize(Vector2 size) {
    _size = size;
    world?.setViewport(size.x, size.y);
    super.onGameResize(size);
  }

  void _haptic() {
    HapticFeedback.lightImpact();
  }

  void showToast(String message) {
    toastMessage = message;
    _toastUntil = DateTime.now().millisecondsSinceEpoch + 1500;
    notifyListeners();
  }

  void _onLevelChange(int level, String name) {
    save.maxLevel = math.max(save.maxLevel, level);
    if (level == 10 && !save.unlockedSkins.contains(10)) {
      save.unlockedSkins.add(10);
      showToast("Golden Pangolin terbuka!");
      audio.play("win");
    } else {
      showToast("Level $level · $name");
    }
    audio.setLevelBgm(level);
    _persist();
  }

  void _onSectionChange(int phase) {
    const messages = [
      "",
      "Jalur bercabang · Cari platform",
      "Landmark baru · Platform bergerak",
      "Zona fauna · Cari relik langka",
    ];
    showToast(messages[phase]);
  }

  void _onGameOver(GameResult result) {
    save.ants += result.nestReward;
    save.bestScore = math.max(save.bestScore, result.score);
    save.bestDistance = math.max(save.bestDistance, result.distance);
    save.maxLevel = math.max(save.maxLevel, result.level);
    lastResult = result;
    phase = "gameover";
    audio.play("gameover");
    _persist();
    notifyListeners();
  }

  Future<void> _persist() async {
    await store.persist(save);
  }

  Future<void> persistNow() => _persist();

  // ----- UI actions -----
  bool levelSelectOpen = false;

  void openLevelSelect() {
    levelSelectOpen = true;
    notifyListeners();
  }

  void closeLevelSelect() {
    levelSelectOpen = false;
    notifyListeners();
  }

  void startRun([int startLevel = 1]) {
    audio.unlock();
    audio.setLevelBgm(startLevel);
    world!.startRun(save.selectedSkin, save.nestItems, startLevel);
    levelSelectOpen = false;
    phase = "running";
    notifyListeners();
  }

  void pauseToggle() {
    if (phase == "running") {
      world!.pause();
      phase = "paused";
      audio.pauseBgm();
    } else if (phase == "paused") {
      world!.resume();
      phase = "running";
      audio.resumeBgm();
    }
    notifyListeners();
  }

  void goMenu() {
    world!.goMenu();
    phase = "menu";
    audio.resumeBgm();
    notifyListeners();
  }

  void openTutorial() {
    tutorialOpen = true;
    _tutorialAuto = false;
    if (phase == "running") {
      world!.pause();
      _tutorialPaused = true;
    }
    notifyListeners();
  }

  void closeTutorial() {
    tutorialOpen = false;
    final auto = _tutorialAuto;
    _tutorialAuto = false;
    _tutorialShown = true;
    final wasPaused = _tutorialPaused;
    _tutorialPaused = false;
    if (wasPaused) world!.resume();
    notifyListeners();
    if (auto) startRun();
  }

  bool get tutorialIsAuto => _tutorialAuto;

  void selectSkin(int id) {
    final skin = skins[id - 1];
    if (!save.unlockedSkins.contains(id)) {
      if (skin.requiresLevel != null && save.maxLevel < skin.requiresLevel!) {
        showToast("Capai Level ${skin.requiresLevel} dulu");
        return;
      }
      if (save.ants < skin.cost) {
        showToast("Coin belum cukup");
        return;
      }
      save.ants -= skin.cost;
      save.unlockedSkins.add(id);
      audio.play("buy");
    }
    save.selectedSkin = id;
    world!.skinId = id;
    _persist();
    notifyListeners();
  }

  void buyNest(String id) {
    final item = nestItems.firstWhere((e) => e.id == id, orElse: () => const NestItem(id: "", name: "", cost: 0, buff: ""));
    if (item.id.isEmpty || save.nestItems.contains(id)) return;
    if (save.ants < item.cost) {
      showToast("Coin belum cukup");
      return;
    }
    save.ants -= item.cost;
    save.nestItems.add(id);
    audio.play("buy");
    _persist();
    notifyListeners();
  }

  void setTestCoins() {
    save.ants = 9999;
    showToast("Koin testing diatur ke 9999");
    _persist();
    notifyListeners();
  }

  void tapJump() {
    if (phase == "running") world!.jump();
  }

  void tapSlide() {
    if (phase == "running") world!.slide();
  }

  // ----- loop -----
  @override
  void update(double dt) {
    if (world == null) return;
    if (phase == "running") {
      world!.update(dt);
    }
    _syncHud();
  }

  void _syncHud() {
    final w = world!;
    final ants = w.antsRun.floor();
    final dist = w.distance.floor();
    final lvl = w.level;
    final combo = w.combo;
    if (ants != _snapAnts ||
        dist != _snapDistance ||
        lvl != _snapLevel ||
        combo != _snapCombo ||
        phase != _snapPhase) {
      _snapAnts = ants;
      _snapDistance = dist;
      _snapLevel = lvl;
      _snapCombo = combo;
      _snapPhase = phase;
      notifyListeners();
    }
    if (_toastUntil != 0 && DateTime.now().millisecondsSinceEpoch > _toastUntil) {
      _toastUntil = 0;
      toastMessage = "";
      notifyListeners();
    }
  }

  @override
  void render(ui.Canvas canvas) {
    if (resources == null || world == null) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, _size.x, _size.y),
        Paint()..color = const Color(0xff1b2a30),
      );
      return;
    }
    renderGame(canvas, world!, resources!, Size(_size.x, _size.y));
  }
}
