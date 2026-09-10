import 'dart:math';
import 'dart:ui';

import 'config.dart';
import 'tweaks.dart';

class GameObject {
  final String kind;
  String? sheet;
  String? frame;
  String? animation;
  double x;
  double bottom;
  double width;
  double height;
  bool dead;
  bool enemy;
  bool moving;
  bool gap;
  int value;
  int? ledgeIndex;

  GameObject({
    required this.kind,
    this.sheet,
    this.frame,
    this.animation,
    required this.x,
    required this.bottom,
    required this.width,
    required this.height,
    this.dead = false,
    this.enemy = false,
    this.moving = false,
    this.gap = false,
    this.value = 0,
    this.ledgeIndex,
  });
}

class Particle {
  double x;
  double y;
  double vx;
  double vy;
  double life;
  String color;

  Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.life,
    required this.color,
  });
}

class PlayerState {
  double x = 118;
  double y = 0;
  double vy = 0;
  String animation = "run";
  double slideTimer = 0;
  GameObject? platform;
}

class WorldHooks {
  final void Function(String name, [double pitch]) sound;
  final void Function(dynamic pattern) haptic;
  final void Function(String message) toast;
  final void Function(int level, String name) levelChange;
  final void Function(int phase) sectionChange;
  final void Function(GameResult result) gameOver;

  WorldHooks({
    required this.sound,
    required this.haptic,
    required this.toast,
    required this.levelChange,
    required this.sectionChange,
    required this.gameOver,
  });
}

class GameResult {
  final int score;
  final int distance;
  final int ants;
  final int nestReward;
  final int bestCombo;
  final int relics;
  final int level;
  final String reason;

  GameResult({
    required this.score,
    required this.distance,
    required this.ants,
    required this.nestReward,
    required this.bestCombo,
    required this.relics,
    required this.level,
    required this.reason,
  });
}

bool _overlaps(Rect a, Rect b) {
  return a.left < b.right && a.right > b.left && a.top < b.bottom && a.bottom > b.top;
}

class World {
  final GameSettings settings;
  final WorldHooks hooks;

  String mode = "menu";
  double width = 480;
  double height = 640;
  double scale = 1;
  double time = 0;
  double animTime = 0;
  double distance = 0;
  double score = 0;
  double bonusScore = 0;
  double antsRun = 0;
  int combo = 0;
  int bestCombo = 0;
  double comboTimer = 0;
  int level = 1;
  int section = 0;
  int phase = 0;
  double speed = 0;
  double backgroundOffset = 0;
  double groundOffset = 0;
  double spawnTimer = 1.2;
  int pattern = 0;
  List<GameObject> objects = [];
  List<Particle> particles = [];
  double shake = 0;
  double flash = 0;
  double magnet = 0;
  double stumble = 0;
  int relicsRun = 0;
  int skinId = 1;
  bool reviveReady = false;
  bool mechaCharge = false;
  double nestAntsBonus = 0;
  double nestScoreBonus = 0;
  double nestMagnetBonus = 0;
  double nestComboBonus = 0;
  bool nestRevive = false;
  bool nestGoldBonus = false;
  int hp = 3;
  int maxHp = 3;
  double invuln = 0;
  final PlayerState player = PlayerState();

  World({required this.settings, required this.hooks}) {
    speed = settings.baseSpeed;
  }

  void setViewport(double w, double h) {
    width = w;
    height = h;
    scale = max(0.76, min(1.45, min(w, h) / 480));
    player.x = w * 0.24;
  }

  Skin selectedSkin() => skins[skinId - 1];

  void startRun(int id, [List<String>? nestIds, int startLevel = 1]) {
    mode = "running";
    time = 0;
    distance = (startLevel - 1) * settings.levelDistance;
    level = startLevel;
    score = 0;
    bonusScore = 0;
    antsRun = 0;
    combo = 0;
    bestCombo = 0;
    comboTimer = 0;
    level = 1;
    section = 0;
    phase = 0;
    speed = settings.baseSpeed;
    backgroundOffset = 0;
    groundOffset = 0;
    spawnTimer = 1.35;
    pattern = 0;
    objects = [];
    particles = [];
    shake = 0;
    flash = 0;
    magnet = 0;
    stumble = 0;
    relicsRun = 0;
    skinId = id;
    nestAntsBonus = 0;
    nestScoreBonus = 0;
    nestMagnetBonus = 0;
    nestComboBonus = 0;
    nestRevive = false;
    nestGoldBonus = false;
    for (final nid in nestIds ?? const <String>[]) {
      final item = nestItems.firstWhere(
        (e) => e.id == nid,
        orElse: () => const NestItem(id: "", name: "", cost: 0, buff: ""),
      );
      if (item.id.isEmpty) continue;
      nestAntsBonus += item.antsBonus;
      nestScoreBonus += item.scoreBonus;
      nestMagnetBonus += item.magnetBonus;
      nestComboBonus += item.comboBonus;
      nestRevive = nestRevive || item.revive;
      nestGoldBonus = nestGoldBonus || item.goldBonus;
    }
    hp = 3 + (nestItems.fold<int>(0, (sum, e) => sum + (nestIds?.contains(e.id) == true ? e.extraHp : 0)));
    maxHp = hp;
    invuln = 0;
    reviveReady = id == 7 || nestRevive;
    mechaCharge = id == 4;
    player.y = 0;
    player.vy = 0;
    player.animation = "run";
    player.slideTimer = 0;
    player.platform = null;
  }

  void goMenu() {
    mode = "menu";
    objects = [];
    player.y = 0;
    player.animation = "run";
    player.platform = null;
  }

  bool isSupported() => player.y <= 2 || player.platform != null;

  void jump() {
    if (mode != "running" || !isSupported() || player.slideTimer > 0) return;
    player.vy = settings.jumpForce;
    player.platform = null;
    player.animation = "jump";
    hooks.sound("jump");
    hooks.haptic(18);
  }

  void slide() {
    if (mode != "running" || !isSupported() || player.slideTimer > 0.08) return;
    player.slideTimer = 0.82;
    player.animation = "slide";
    hooks.sound("slide");
    hooks.haptic(12);
  }

  void pause() {
    if (mode == "running") mode = "paused";
  }

  void resume() {
    if (mode == "paused") mode = "running";
  }

  void addCoins(double startX, List<double> heights, [String? forceType]) {
    final s = scale;
    for (int i = 0; i < heights.length; i++) {
      final coinType = forceType ??
          (Random().nextDouble() < settings.rareCoinChance * (nestGoldBonus ? 2 : 1)
              ? "golden_termite"
              : "ant_coin");
      final value = coinType == "golden_termite"
          ? 5
          : coinType == "nest_token"
              ? 3
              : 1;
      objects.add(GameObject(
        kind: "coin",
        animation: coinType,
        value: value,
        x: startX + i * 38 * s,
        bottom: heights[i] * s,
        width: 29 * s,
        height: 29 * s,
      ));
    }
  }

  GameObject addPlatform(double x, double top, double width, bool animated, Level levelCfg) {
    final s = scale;
    final platform = GameObject(
      kind: "platform",
      sheet: animated ? "traversal" : "ledge",
      animation: animated ? levelCfg.traversal : null,
      ledgeIndex: levelCfg.id - 1,
      x: x,
      bottom: top - 16 * s,
      width: width,
      height: 16 * s,
    );
    objects.add(platform);
    return platform;
  }

  void spawnPlatformRoute(Level levelCfg, double x) {
    final s = scale;
    final firstTop = min(82.0, 72 * s);
    final firstWidth = (phase == 2 ? 184 : 215) * s;
    addPlatform(x, firstTop, firstWidth, false, levelCfg);
    addCoins(x + 24 * s, [
      firstTop / s + 28,
      firstTop / s + 42,
      firstTop / s + 42,
      firstTop / s + 28,
    ]);
    final safeHard = levelCfg.hard.firstWhere(
      (name) => !name.contains("gap") && !name.contains("chasm"),
      orElse: () => "",
    );
    if (safeHard.isNotEmpty) {
      objects.add(GameObject(
        kind: "hard",
        sheet: "hard",
        frame: safeHard,
        x: x + firstWidth * 0.38,
        bottom: 0,
        width: 68 * s,
        height: min(firstTop - 8 * s, 60 * s),
      ));
    }
    if (phase == 2) {
      final secondX = x + firstWidth + 72 * s;
      final secondTop = min(98.0, 90 * s);
      final secondWidth = 145 * s;
      addPlatform(secondX, secondTop, secondWidth, true, levelCfg);
      addCoins(secondX + 12 * s, [secondTop / s + 25, secondTop / s + 38, secondTop / s + 25],
          pattern % 12 == 0 ? "golden_termite" : null);
    }
  }

  void spawnLandmark(Level levelCfg) {
    final s = scale;
    objects.add(GameObject(
      kind: "landmark",
      sheet: "landmark",
      frame: levelCfg.landmark,
      x: width + 35 * s,
      bottom: 0,
      width: 185 * s,
      height: 205 * s,
    ));
  }

  void spawnCritter(Level levelCfg, double x) {
    final s = scale;
    final variety = biomeVariety[levelCfg.id - 1];
    objects.add(GameObject(
      kind: "critter",
      sheet: variety.sheet,
      animation: variety.critter,
      x: x,
      bottom: variety.high ? 44 * s : 0,
      width: (variety.high ? 56 : 62) * s,
      height: (variety.high ? 52 : 43) * s,
      enemy: true,
    ));
    addCoins(x + 78 * s, variety.high ? [18, 20, 18] : [58, 78, 58]);
  }

  void spawnRelic(Level levelCfg) {
    final s = scale;
    final variety = biomeVariety[levelCfg.id - 1];
    objects.add(GameObject(
      kind: "relic",
      sheet: "relic",
      frame: variety.relic,
      x: width + 145 * s,
      bottom: 74 * s,
      width: 42 * s,
      height: 42 * s,
    ));
  }

  void spawnObstacle() {
    final levelCfg = levels[level - 1];
    final s = scale;
    final x = width + 100 * s;
    pattern += 1;

    if (phase >= 1 && pattern % 6 == 0) {
      spawnPlatformRoute(levelCfg, x);
      return;
    }
    if (phase >= 1 && pattern % 8 == 0) {
      spawnCritter(levelCfg, x);
      return;
    }
    if (pattern % 9 == 0) {
      objects.add(GameObject(
        kind: "power",
        frame: "magnet",
        x: x,
        bottom: 62 * s,
        width: 38 * s,
        height: 38 * s,
      ));
      addCoins(x + 70 * s, [42, 58, 42], pattern % 18 == 0 ? "nest_token" : null);
      return;
    }
    if (levelCfg.hazard != null && level >= 2 && pattern % 7 == 0) {
      final high = levelCfg.hazard == "swinging_log" || levelCfg.hazard == "falling_crystal";
      objects.add(GameObject(
        kind: "hard",
        sheet: "extraHazard",
        animation: levelCfg.hazard,
        x: x,
        bottom: high ? 45 * s : 0,
        width: 76 * s,
        height: high ? 68 * s : 66 * s,
        moving: true,
      ));
      addCoins(x + 100 * s, high ? [18, 20, 18, 20] : [72, 104, 112, 78]);
      return;
    }
    if (levelCfg.moving != null && pattern % 4 == 0) {
      final isBridge = levelCfg.moving == "bridge_rope";
      objects.add(GameObject(
        kind: isBridge ? "hard" : "soft",
        sheet: "moving",
        animation: levelCfg.moving,
        x: x,
        bottom: isBridge ? 0 : 45 * s,
        width: 78 * s,
        height: isBridge ? 54 * s : 72 * s,
        moving: true,
        gap: isBridge,
      ));
      addCoins(x + 110 * s, isBridge ? [82, 112, 82] : [20, 22, 20]);
      return;
    }
    if ((levelCfg.enemy != null || levelCfg.extraEnemy != null) && pattern % 5 == 0) {
      final useExtra = section == 1 && levelCfg.extraEnemy != null;
      final enemy = useExtra ? levelCfg.extraEnemy! : (levelCfg.enemy ?? levelCfg.extraEnemy)!;
      final isHigh = enemy == "owl" || enemy == "cave_bat" || enemy == "macaque";
      objects.add(GameObject(
        kind: "hard",
        sheet: (!useExtra && levelCfg.enemy != null) ? "enemy" : "extraEnemy",
        animation: enemy,
        x: x,
        bottom: isHigh ? 44 * s : 0,
        width: (isHigh ? 74 : 92) * s,
        height: (isHigh ? 64 : 50) * s,
        enemy: true,
      ));
      addCoins(x + 118 * s, isHigh ? [18, 20, 18, 20] : [72, 104, 112, 76]);
      return;
    }

    final soft = pattern % 3 != 0;
    final expandedPool = soft ? levelCfg.extraSoft : levelCfg.extraHard;
    final useExtended = section == 1 &&
        expandedPool != null &&
        expandedPool.isNotEmpty &&
        pattern % 2 == 0;
    final pool = useExtended
        ? expandedPool
        : soft
            ? levelCfg.soft
            : levelCfg.hard;
    final frame = pool[pattern % pool.length];
    final gap = frame == levelCfg.gap || frame.contains("gap") || frame.contains("chasm");
    final widthObj = (gap ? 92 : soft ? 62 : 74) * s;
    final heightObj = (gap ? 38 : soft ? 55 : 68) * s;
    objects.add(GameObject(
      kind: soft ? "soft" : "hard",
      sheet: useExtended ? "extended" : soft ? "soft" : "hard",
      frame: frame,
      x: x,
      bottom: gap ? -8 * s : 0,
      width: widthObj,
      height: heightObj,
      gap: gap,
    ));

    if (level >= 4 && pattern % 3 == 0 && !gap) {
      final secondPool = levelCfg.extraSoft != null && levelCfg.extraSoft!.isNotEmpty
          ? levelCfg.extraSoft!
          : levelCfg.soft;
      final secondFrame = secondPool[(pattern + 1) % secondPool.length];
      objects.add(GameObject(
        kind: "soft",
        sheet: levelCfg.extraSoft != null && levelCfg.extraSoft!.contains(secondFrame)
            ? "extended"
            : "soft",
        frame: secondFrame,
        x: x + (170 + level * 3) * s,
        bottom: 0,
        width: 60 * s,
        height: 52 * s,
      ));
      addCoins(x + 72 * s, soft ? [22, 24, 22, 24, 22] : [70, 98, 116, 98, 70]);
    } else {
      addCoins(x + widthObj + 45 * s, soft ? [22, 24, 22, 24] : [62, 96, 112, 82]);
    }
  }

  void burst(GameObject object, [String color = "#d7a34c"]) {
    final count = (10 * settings.effectsIntensity).toInt();
    for (int i = 0; i < count; i++) {
      particles.add(Particle(
        x: object.x + object.width / 2,
        y: object.bottom + object.height / 2,
        vx: (Random().nextDouble() - 0.5) * 210,
        vy: 90 + Random().nextDouble() * 170,
        life: 0.35 + Random().nextDouble() * 0.35,
        color: color,
      ));
    }
  }

  void collect(GameObject object) {
    object.dead = true;
    if (object.kind == "power") {
      magnet = settings.magnetDuration + (skinId == 5 ? 3 : 0) + nestMagnetBonus;
      hooks.toast("Magnet ${magnet.ceil()} dtk");
      hooks.sound("magnet");
      return;
    }
    if (object.kind == "relic") {
      relicsRun += 1;
      antsRun += skinId == 3 ? 12 : 10;
      bonusScore += 500;
      comboTimer = settings.comboWindow + nestComboBonus;
      burst(object, "#9ce5ce");
      hooks.toast("Relik biome ditemukan · +10 koin");
      hooks.sound("relic");
      hooks.haptic([18, 22, 28]);
      return;
    }
    final gain = (skinId == 3 ? 1.2 : 1) * object.value;
    antsRun += gain;
    combo = comboTimer > 0 ? combo + 1 : 1;
    bestCombo = max(bestCombo, combo);
    comboTimer = settings.comboWindow + nestComboBonus;
    final comboMultiplier = 1 + min(20.0, combo) * 0.05;
    bonusScore += 25 * object.value * comboMultiplier;
    burst(object, object.animation == "golden_termite" ? "#ffe59a" : "#d99a4b");
    hooks.sound("ant", 1 + min(0.4, (combo % 10) * 0.035));
    if (combo == 10 || combo == 20) hooks.toast("Combo koin ×$combo!");
  }

  void fail(String reason, GameObject object) {
    mode = "gameover";
    shake = 0.7;
    flash = 0.45;
    hooks.sound("hit");
    hooks.haptic([60, 40, 80]);
    hooks.gameOver(GameResult(
      score: score.floor(),
      distance: distance.floor(),
      ants: antsRun.floor(),
      nestReward: (antsRun * (skinId == 10 ? 3 : 1) * (1 + nestAntsBonus)).floor(),
      bestCombo: bestCombo,
      relics: relicsRun,
      level: level,
      reason: reason,
    ));
  }

  void _damage(String reason, GameObject object) {
    object.dead = true;
    hp -= 1;
    if (hp <= 0) {
      fail(reason, object);
      return;
    }
    invuln = 1.2;
    stumble = 1.15;
    shake = 0.5;
    flash = 0.3;
    hooks.sound("hit");
    hooks.haptic([60, 40, 80]);
    hooks.toast("Nyawa $hp!");
  }

  void collisionStep() {
    final s = scale;
    final sliding = player.slideTimer > 0 && isSupported();
    final hitScale = skinId == 8 ? 0.9 : 1;
    final playerWidth = (sliding ? 48 : 58) * s * hitScale;
    final playerHeight = (sliding ? 34 : 68) * s * hitScale;
    final playerRect = Rect.fromLTRB(
      player.x - playerWidth * 0.45,
      player.y,
      player.x + playerWidth * 0.55,
      player.y + playerHeight,
    );

    for (final object in objects) {
      if (object.dead) continue;
      if (object.kind == "platform" || object.kind == "landmark") continue;
      if (object.kind == "coin" || object.kind == "power" || object.kind == "relic") {
        final centerY = object.bottom + object.height / 2;
        final playerCenterY = player.y + playerHeight / 2;
        if ((object.x + object.width / 2 - player.x).abs() <
                (object.width + playerWidth) * 0.55 &&
            (centerY - playerCenterY).abs() < 58 * s) {
          collect(object);
        }
        continue;
      }
      final rect = Rect.fromLTRB(
        object.x,
        object.bottom,
        object.x + object.width,
        object.bottom + object.height,
      );
      if (!_overlaps(playerRect, rect)) continue;

      if (object.kind == "critter") {
        object.dead = true;
        if (sliding) {
          bonusScore += 100;
          burst(object, "#9fc999");
          hooks.sound("break");
          hooks.toast("Wildlife lewat dengan aman · +100");
        } else {
          combo = 0;
          comboTimer = 0;
          stumble = 1.15;
          shake = 0.16;
          hooks.sound("slide");
          hooks.toast("Tersenggol sedikit — lanjut!");
        }
        hooks.haptic(16);
        continue;
      }

      if (object.kind == "soft" && sliding) {
        object.dead = true;
        burst(object, "#b98b5e");
        bonusScore += 75;
        shake = 0.14;
        hooks.sound("break");
        hooks.haptic(24);
      } else if (object.frame == "medium_rock" && mechaCharge && sliding) {
        mechaCharge = false;
        object.dead = true;
        burst(object, "#8fd8dc");
        hooks.toast("Pelat mecha terpakai");
        hooks.sound("break");
      } else if (object.gap && reviveReady) {
        reviveReady = false;
        object.dead = true;
        player.y = 82 * scale;
        player.vy = settings.jumpForce * 0.72;
        flash = 0.55;
        hooks.toast("Sling Bag menyelamatkanmu!");
        hooks.sound("level");
        hooks.haptic([35, 30, 35]);
      } else if (object.gap) {
        _damage("Terlambat melompat", object);
      } else if (invuln > 0) {
        object.dead = true;
      } else {
        _damage(
          object.kind == "soft" ? "Gunakan Armor Slide" : "Rintangan keras",
          object,
        );
      }
      if (mode == "gameover") break;
    }
  }

  void update(double dt) {
    animTime += dt;
    flash = max(0.0, flash - dt);
    shake = max(0.0, shake - dt * 2.5);
    if (mode != "running") return;

    time += dt;
    final previousLevel = level;
    final previousSection = section;
    final previousPhase = phase;
    level = min(10.0, (distance / settings.levelDistance).floor() + 1).toInt();
    final distanceInLevel = level == 10
        ? distance % settings.levelDistance
        : distance - (level - 1) * settings.levelDistance;
    phase = min(3.0, (distanceInLevel / (settings.levelDistance / 4)).floor()).toInt();
    section = phase == 0 ? 0 : 1;
    final levelFactor = level == 10 ? 2 : 1 + (level - 1) * 0.055;
    final mudFactor = level == 2 && skinId != 9 ? 0.88 : 1;
    stumble = max(0.0, stumble - dt);
    speed = settings.baseSpeed * levelFactor * mudFactor * (stumble > 0 ? 0.78 : 1);
    distance += speed * dt * 0.045;
    score = (distance * 10 + bonusScore) * (skinId == 3 ? 1.2 : 1) * (1 + nestScoreBonus);
    backgroundOffset += speed * dt * 0.12;
    groundOffset += speed * dt;
    magnet = max(0.0, magnet - dt);
    comboTimer = max(0.0, comboTimer - dt);
    invuln = max(0.0, invuln - dt);
    if (comboTimer <= 0) combo = 0;

    if (level != previousLevel) {
      objects = objects.where((o) => o.kind == "coin").toList();
      spawnTimer = 1.5;
      hooks.levelChange(level, levels[level - 1].name);
      hooks.sound("level");
    }
    if (phase != previousPhase && level == previousLevel) {
      hooks.sectionChange(phase);
      if (phase == 2) spawnLandmark(levels[level - 1]);
      if (phase == 3) spawnRelic(levels[level - 1]);
    } else if (section != previousSection && level == previousLevel) {
      hooks.sectionChange(section);
    }

    player.slideTimer = max(0.0, player.slideTimer - dt);
    final previousY = player.y;
    player.vy -= settings.gravity * dt;
    player.y += player.vy * dt;

    spawnTimer -= dt;
    if (spawnTimer <= 0) {
      spawnObstacle();
      spawnTimer = settings.spawnInterval * max(0.58, 1 - (level - 1) * 0.042);
    }

    for (final object in objects) {
      if (object.dead) continue;
      object.x -= speed * dt * (object.enemy ? 1.12 : 1);
      if (magnet > 0 && object.kind == "coin") {
        final dx = player.x - object.x;
        if (dx.abs() < 280 * scale) {
          object.x += dx.sign * min(dx.abs(), 460 * dt);
          object.bottom += (player.y + 30 * scale - object.bottom) * min(1.0, dt * 7);
        }
      }
    }

    final currentPlatform = player.platform;
    if (currentPlatform != null && !currentPlatform.dead && player.vy <= 0 &&
        player.x > currentPlatform.x && player.x < currentPlatform.x + currentPlatform.width) {
      player.y = currentPlatform.bottom + currentPlatform.height;
      player.vy = 0;
    } else {
      player.platform = null;
      if (player.vy <= 0) {
        final landing = objects.firstWhere(
          (object) {
            if (object.kind != "platform" || object.dead) return false;
            final top = object.bottom + object.height;
            return player.x > object.x - 8 * scale &&
                player.x < object.x + object.width + 8 * scale &&
                previousY >= top - 3 * scale &&
                player.y <= top + 5 * scale;
          },
          orElse: () => GameObject(
              kind: "platform", x: 0, bottom: 0, width: 0, height: 0, dead: true),
        );
        if (!landing.dead) {
          player.platform = landing;
          player.y = landing.bottom + landing.height;
          player.vy = 0;
        }
      }
    }
    if (player.y <= 0) {
      player.y = 0;
      player.vy = 0;
      player.platform = null;
    }
    player.animation = !isSupported()
        ? "jump"
        : player.slideTimer > 0
            ? "slide"
            : "run";
    objects = objects.where((o) => !o.dead && o.x + o.width > -120).toList();

    for (final particle in particles) {
      particle.x += particle.vx * dt;
      particle.y += particle.vy * dt;
      particle.vy -= 460 * dt;
      particle.life -= dt;
    }
    particles = particles.where((p) => p.life > 0).toList();
    collisionStep();
  }
}
