import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';
import 'dart:ui' as ui;

import 'package:flutter/services.dart' show rootBundle;

import 'config.dart';

class AtlasFrame {
  final Rect source;
  final Rect content;
  final Offset? anchor;
  final double? surfaceY;

  AtlasFrame({
    required this.source,
    required this.content,
    this.anchor,
    this.surfaceY,
  });
}

class Sheet {
  final ui.Image image;
  final Map<String, AtlasFrame> frames;
  final Map<String, List<AtlasFrame>> animations;

  Sheet(this.image, this.frames, this.animations);
}

AtlasFrame? frameByName(Sheet sheet, String name) => sheet.frames[name];

Future<ui.Image> _decodeImage(ByteData data) async {
  final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
  final frameInfo = await codec.getNextFrame();
  return frameInfo.image;
}

List<AtlasFrame> animationByName(Sheet sheet, String name) =>
    sheet.animations[name] ?? [];

class Resources {
  final Map<String, ui.Image> images = {};
  final Map<String, Sheet> sheets = {};

  late List<Sheet> skins;
  late List<ui.Image> backgrounds;
  late List<ui.Image> backgroundVariants;
  late List<ui.Image> foregrounds;
  late List<Sheet> platforms;
  late List<Sheet> ledges;
  late Sheet soft;
  late Sheet hard;
  late Sheet pickup;
  late Sheet enemies;
  late Sheet moving;
  late Sheet coins;
  late Sheet extraEnemies;
  late Sheet extraHazards;
  late Sheet extended;
  late Sheet traversalPlatforms;
  late Sheet landmarks;
  late Sheet gentleEnemiesA;
  late Sheet gentleEnemiesB;
  late Sheet relics;

  static Future<Resources> load(String manifestPath, List<String> skinKeys,
      List<Level> levelList, List<String> sheetKeys) async {
    final manifestRaw = await rootBundle.loadString(manifestPath);
    final Map<String, dynamic> manifest = jsonDecode(manifestRaw);
    final res = Resources();

    String fileName(String url) {
      final base = url.split('?').first;
      return base.split('/').last;
    }

    Future<ui.Image> loadImageByKey(String key) async {
      final name = fileName(manifest[key] as String);
      final bytes = await rootBundle.load('assets/images/$name');
      final image = await _decodeImage(bytes);
      res.images[key] = image;
      return image;
    }

    Future<Sheet> loadSheetByKey(String key) async {
      final name = fileName(manifest[key] as String);
      final base = name.substring(0, name.length - 5); // strip .webp
      final imgBytes = await rootBundle.load('assets/images/$name');
      final image = await _decodeImage(imgBytes);
      final jsonStr = await rootBundle.loadString('assets/json/$base.frames.json');
      final Map<String, dynamic> data = jsonDecode(jsonStr);
      final frames = <String, AtlasFrame>{};
      for (final f in (data['frames'] as List)) {
        frames[f['name']] = _parseFrame(f);
      }
      final animations = <String, List<AtlasFrame>>{};
      for (final a in (data['animations'] as List? ?? [])) {
        final list = (a['frames'] as List)
            .map((f) => _parseFrame(f))
            .toList();
        animations[a['name']] = list;
      }
      final sheet = Sheet(image, frames, animations);
      res.sheets[key] = sheet;
      return sheet;
    }

    res.skins = [];
    for (final k in skinKeys) {
      res.skins.add(await loadSheetByKey(k));
    }
    res.backgrounds = [];
    res.backgroundVariants = [];
    res.foregrounds = [];
    res.platforms = [];
    res.ledges = [];
    for (final lv in levelList) {
      res.backgrounds.add(await loadImageByKey(lv.key));
      res.backgroundVariants.add(await loadImageByKey(lv.keyB));
      res.foregrounds.add(await loadImageByKey(lv.foreground));
      res.platforms.add(await loadSheetByKey(lv.platform));
      res.ledges.add(await loadSheetByKey(lv.ledge));
    }
    final sheetMap = <String, Sheet>{};
    for (final k in sheetKeys) {
      sheetMap[k] = await loadSheetByKey(k);
    }
    res.soft = sheetMap['SOFT_OBSTACLES_ATLAS']!;
    res.hard = sheetMap['HARD_OBSTACLES_ATLAS']!;
    res.pickup = sheetMap['PICKUP_NEST_ATLAS']!;
    res.enemies = sheetMap['ENEMY_SHEET']!;
    res.moving = sheetMap['MOVING_OBSTACLE_SHEET']!;
    res.coins = sheetMap['COIN_SHEET']!;
    res.extraEnemies = sheetMap['EXTRA_ENEMY_SHEET']!;
    res.extraHazards = sheetMap['EXTRA_HAZARD_SHEET']!;
    res.extended = sheetMap['EXTENDED_OBSTACLES_ATLAS']!;
    res.traversalPlatforms = sheetMap['TRAVERSAL_PLATFORM_SHEET']!;
    res.landmarks = sheetMap['LANDMARK_ATLAS']!;
    res.gentleEnemiesA = sheetMap['GENTLE_ENEMY_SHEET_A']!;
    res.gentleEnemiesB = sheetMap['GENTLE_ENEMY_SHEET_B']!;
    res.relics = sheetMap['RELIC_ATLAS']!;
    return res;
  }
}

AtlasFrame _parseFrame(Map<String, dynamic> f) {
  final src = f['source'] as Map<String, dynamic>;
  final contentSrc = (f['content'] as Map<String, dynamic>?) ?? src;
  final anchor = f['anchor'] as Map<String, dynamic>?;
  return AtlasFrame(
    source: Rect.fromLTWH(
      (src['x'] as num).toDouble(),
      (src['y'] as num).toDouble(),
      (src['w'] as num).toDouble(),
      (src['h'] as num).toDouble(),
    ),
    content: Rect.fromLTWH(
      (contentSrc['x'] as num).toDouble(),
      (contentSrc['y'] as num).toDouble(),
      (contentSrc['w'] as num).toDouble(),
      (contentSrc['h'] as num).toDouble(),
    ),
    anchor: anchor == null
        ? null
        : Offset((anchor['x'] as num).toDouble(), (anchor['y'] as num).toDouble()),
    surfaceY: (f['surfaceY'] as num?)?.toDouble(),
  );
}
