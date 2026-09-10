import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'atlas.dart';
import 'world.dart';

double _clamp(double v, double min, double max) => math.max(min, math.min(max, v));

void _drawContained(Canvas canvas, Sheet sheet, AtlasFrame frame, Rect dest) {
  final crop = frame.content;
  final scale = math.min(dest.width / crop.width, dest.height / crop.height);
  final drawW = crop.width * scale;
  final drawH = crop.height * scale;
  final dx = dest.left + (dest.width - drawW) / 2;
  final dy = dest.top + dest.height - drawH;
  canvas.drawImageRect(
    sheet.image,
    crop,
    Rect.fromLTWH(dx, dy, drawW, drawH),
    _paint,
  );
}

void _drawAnchored(Canvas canvas, Sheet sheet, List<AtlasFrame> frames, int index,
    Offset anchorPos, double targetHeight, {double alpha = 1}) {
  if (frames.isEmpty) return;
  final frame = frames[index % frames.length];
  final crop = frame.content;
  double maxH = 0;
  for (final f in frames) {
    maxH = math.max(maxH, f.content.height);
  }
  final scale = targetHeight / maxH;
  final anchor = frame.anchor ??
      Offset(frame.source.left + frame.source.width / 2,
          frame.source.top + frame.source.height);
  final dx = anchorPos.dx - (anchor.dx - crop.left) * scale;
  final dy = anchorPos.dy - (anchor.dy - crop.top) * scale;
  canvas.drawImageRect(
    sheet.image,
    crop,
    Rect.fromLTWH(dx, dy, crop.width * scale, crop.height * scale),
    alpha < 1 ? (Paint()..color = const Color(0xffffffff).withOpacity(alpha)) : _paint,
  );
}

final Paint _paint = Paint();

void _drawLoopingImage(Canvas canvas, ui.Image image, double width, double height,
    double offset, {double layerFactor = 1.0, double alpha = 1.0}) {
  final tileHeight = height * layerFactor;
  final tileWidth = tileHeight * (image.width / image.height);
  final period = tileWidth * 2;
  final start = -((((offset % period) + period) % period)) - tileWidth;
  for (double x = start, i = 0; x < width + tileWidth; x += tileWidth, i++) {
    final flip = (i.round() % 2 == 1);
    if (!flip) {
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        Rect.fromLTWH(x, height - tileHeight, tileWidth, tileHeight),
        _alphaPaint(alpha),
      );
    } else {
      canvas.save();
      canvas.translate(x + tileWidth, height - tileHeight);
      canvas.scale(-1, 1);
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        Rect.fromLTWH(0, 0, tileWidth, tileHeight),
        _alphaPaint(alpha),
      );
      canvas.restore();
    }
  }
}

Paint _alphaPaint(double alpha) {
  if (alpha >= 1) return _paint;
  return Paint()..color = const Color(0xffffffff).withOpacity(alpha);
}

void _drawPlatform(Canvas canvas, Sheet sheet, double width, double height,
    double groundY, double offset) {
  final frame = frameByName(sheet, "center") ??
      sheet.frames.values.firstWhere((f) => f.surfaceY != null,
          orElse: () => sheet.frames.values.first);
  final crop = frame.content;
  final surfaceY = frame.surfaceY ?? crop.top;
  final lowerSource = math.max(1.0, crop.top + crop.height - surfaceY);
  final scaleY = math.max(0.55, (height - groundY + 30) / lowerSource);
  final drawY = groundY - (surfaceY - crop.top) * scaleY;
  final tileWidth = crop.width * scaleY;
  final tileHeight = crop.height * scaleY;
  final period = tileWidth * 2;
  final start = -((((offset % period) + period) % period)) - tileWidth;
  for (double x = start, i = 0; x < width + tileWidth; x += tileWidth, i++) {
    if (i.round() % 2 == 0) {
      canvas.drawImageRect(
        sheet.image,
        crop,
        Rect.fromLTWH(x, drawY, tileWidth + 1, tileHeight),
        _paint,
      );
    } else {
      canvas.save();
      canvas.translate(x + tileWidth, drawY);
      canvas.scale(-1, 1);
      canvas.drawImageRect(
        sheet.image,
        crop,
        Rect.fromLTWH(0, 0, tileWidth + 1, tileHeight),
        _paint,
      );
      canvas.restore();
    }
  }
}

void _drawObject(Canvas canvas, World world, Resources res, GameObject object, double groundY) {
  final drawY = groundY - object.bottom - object.height;
  final dest = Rect.fromLTWH(object.x, drawY, object.width, object.height);
  if (object.kind == "coin" || object.kind == "power" || object.kind == "relic") {
    if (object.kind == "coin") {
      final frames = animationByName(res.coins, object.animation ?? "ant_coin");
      final frame = frames[((world.animTime * 10).floor()) % math.max(1, frames.length)];
      _drawContained(canvas, res.coins, frame, dest);
      return;
    }
    Color c;
    if (object.kind == "relic") {
      c = const Color(0x94e9cf);
    } else {
      c = const Color(0x76d2cd);
    }
    final grad = RadialGradient(
      center: Alignment.center,
      radius: 1.25,
      colors: [c, const Color(0x00ffffff)],
    );
    final paint = Paint()..shader = grad.createShader(Rect.fromLTWH(
      object.x - object.width,
      drawY - object.height,
      object.width * 3,
      object.height * 3,
    ));
    canvas.drawRect(
        Rect.fromLTWH(object.x - object.width, drawY - object.height, object.width * 3,
            object.height * 3),
        paint);
    if (object.kind == "relic") {
      _drawContained(canvas, res.relics, frameByName(res.relics, object.frame!)!, dest);
    } else {
      _drawContained(canvas, res.pickup, frameByName(res.pickup, object.frame!)!, dest);
    }
    return;
  }
  if (object.sheet == "soft" || object.sheet == "hard" || object.sheet == "extended") {
    final sheet = object.sheet == "soft"
        ? res.soft
        : object.sheet == "hard"
            ? res.hard
            : res.extended;
    _drawContained(canvas, sheet, frameByName(sheet, object.frame!)!,
        Rect.fromLTWH(dest.left - dest.width * 0.08, dest.top - dest.height * 0.08,
            dest.width * 1.16, dest.height * 1.16));
    return;
  }
  final sheets = {
    "enemy": res.enemies,
    "moving": res.moving,
    "extraEnemy": res.extraEnemies,
    "extraHazard": res.extraHazards,
    "gentleA": res.gentleEnemiesA,
    "gentleB": res.gentleEnemiesB,
  };
  final sheet = sheets[object.sheet]!;
  final frames = animationByName(sheet, object.animation!);
  final frame = frames[((world.animTime * 8).floor()) % math.max(1, frames.length)];
  _drawContained(canvas, sheet, frame,
      Rect.fromLTWH(dest.left - dest.width * 0.1, dest.top - dest.height * 0.15,
          dest.width * 1.2, dest.height * 1.2));
}

void _drawElevatedPlatform(Canvas canvas, World world, Resources res, GameObject object,
    double groundY) {
  final topY = groundY - object.bottom - object.height;
  if (object.sheet == "ledge") {
    final sheet = res.ledges[object.ledgeIndex!];
    final frame = sheet.frames.values.first;
    final crop = frame.content;
    final scale = object.width / crop.width;
    final surfaceY = frame.surfaceY ?? crop.top;
    canvas.drawImageRect(sheet.image, crop,
        Rect.fromLTWH(object.x, topY - (surfaceY - crop.top) * scale, object.width, crop.height * scale), _paint);
    return;
  }
  final frames = animationByName(res.traversalPlatforms, object.animation!);
  if (frames.isEmpty) return;
  final frame = frames[((world.animTime * 6).floor()) % frames.length];
  final crop = frame.content;
  final scale = object.width / crop.width;
  canvas.drawImageRect(res.traversalPlatforms.image, crop,
      Rect.fromLTWH(object.x, topY - 3 * world.scale, object.width, crop.height * scale), _paint);
}

void _drawLandmark(Canvas canvas, Resources res, GameObject object, double groundY) {
  _drawContained(canvas, res.landmarks, frameByName(res.landmarks, object.frame!)!,
      Rect.fromLTWH(object.x, groundY - object.height, object.width, object.height));
}

void _drawPlayer(Canvas canvas, World world, Resources res, double groundY) {
  final player = world.player;
  final sheet = res.skins[world.skinId - 1];
  final frames = animationByName(sheet, player.animation);
  int index = ((world.animTime * (player.animation == "run" ? 10 : 7)).floor()) % 4;
  if (player.animation == "jump") {
    if (player.y < 18 && player.vy > 0) {
      index = 0;
    } else if (player.vy > 80) {
      index = 1;
    } else if (player.vy < -120) {
      index = 3;
    } else {
      index = 2;
    }
  }
  final targetHeight = _clamp((player.animation == "slide" ? 62 : 94) * world.scale, 56, 130);
  final anchor = Offset(player.x, groundY - player.y);
  double alpha = 1;
  if (world.invuln > 0 && (world.animTime * 12).floor() % 2 == 0) alpha = 0.35;
  _drawAnchored(canvas, sheet, frames, index, anchor, targetHeight, alpha: alpha);

  if (world.magnet > 0) {
    final c = Offset(player.x, groundY - player.y - targetHeight * 0.4);
    final grad = RadialGradient(
      center: Alignment.center,
      radius: 1.5,
      colors: [
        const Color(0x0089d6cd),
        const Color(0x1e89d6cd),
        const Color(0x0089d6cd),
      ],
      stops: const [0.0, 0.7, 1.0],
    );
    final paint = Paint()..shader = grad.createShader(Rect.fromCircle(center: c, radius: targetHeight * 1.5));
    canvas.drawCircle(c, targetHeight * 1.5, paint);
  }
}

Color _parseColor(String hex) {
  final h = hex.replaceFirst('#', '');
  return Color(int.parse('ff$h', radix: 16));
}

void renderGame(Canvas canvas, World world, Resources res, Size size) {
  final width = size.width;
  final height = size.height;
  final levelIndex = world.level - 1;
  final groundY = height * 0.72;
  final shakeX = world.shake != 0 ? (math.Random().nextDouble() - 0.5) * 8 * world.shake : 0.0;
  final shakeY = world.shake != 0 ? (math.Random().nextDouble() - 0.5) * 5 * world.shake : 0.0;

  canvas.save();
  canvas.translate(shakeX, shakeY);
  canvas.drawRect(Rect.fromLTWH(-10, -10, width + 20, height + 20),
      Paint()..color = const Color(0xffc9dde0));

  final backdrop = world.section == 0
      ? res.backgrounds[levelIndex]
      : res.backgroundVariants[levelIndex];
  _drawLoopingImage(canvas, backdrop, width, height, world.backgroundOffset);

  final darkLevel = world.level == 5 || world.level == 9;
  if (darkLevel && ![2, 6].contains(world.skinId)) {
    final alpha = world.skinId == 2 ? 0.12 : 0.28;
    canvas.drawRect(Rect.fromLTWH(0, 0, width, height),
        Paint()..color = const Color(0xff11232a).withOpacity(alpha));
  }

  for (final object in world.objects.where((o) => o.kind == "landmark")) {
    _drawLandmark(canvas, res, object, groundY);
  }
  _drawPlatform(canvas, res.platforms[levelIndex], width, height, groundY, world.groundOffset);
  for (final object in world.objects.where((o) => o.kind == "platform")) {
    _drawElevatedPlatform(canvas, world, res, object, groundY);
  }
  for (final object in world.objects.where((o) => o.kind != "landmark" && o.kind != "platform")) {
    _drawObject(canvas, world, res, object, groundY);
  }
  _drawPlayer(canvas, world, res, groundY);

  for (final particle in world.particles) {
    final paint = Paint()
      ..color = _parseColor(particle.color)
          .withOpacity(_clamp(particle.life * 2.2, 0, 1));
    canvas.drawCircle(
        Offset(particle.x, groundY - particle.y), 2.5 * world.scale, paint);
  }

  _drawLoopingImage(canvas, res.foregrounds[levelIndex], width, height,
      world.backgroundOffset * 2.1, layerFactor: 0.56, alpha: 0.72);

  canvas.restore();

  if (world.flash > 0) {
    canvas.drawRect(Rect.fromLTWH(0, 0, width, height),
        Paint()..color = const Color(0xfffeeecd).withOpacity(world.flash * 0.36));
  }
}
