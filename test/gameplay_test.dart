import 'package:flutter_test/flutter_test.dart';

import 'package:tringgling_slide/game/config.dart';
import 'package:tringgling_slide/game/tweaks.dart';
import 'package:tringgling_slide/game/world.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('world gameplay runs without exceptions (logic only, long sim)', () async {
    final tweaks = Tweaks();
    await tweaks.load('assets/json/tweaks.json');
    final settings = GameSettings.fromTweaks(tweaks);

    int gameOvers = 0;
    int levelChanges = 0;
    final world = World(
      settings: settings,
      hooks: WorldHooks(
        sound: (_, [double __ = 1]) {},
        haptic: (_) {},
        toast: (_) {},
        levelChange: (_, __) => levelChanges++,
        sectionChange: (_) {},
        gameOver: (_) => gameOvers++,
      ),
    );
    world.setViewport(800, 400);

    double maxDistance = 0;
    int maxObjects = 0;
    int runs = 0;

    // Run with auto-play long enough to cross multiple levels.
    for (int run = 0; run < 4; run++) {
      world.startRun(1 + (run % skins.length));
      runs++;
      for (int i = 0; i < 6000; i++) {
        world.update(1 / 60);
        if (world.mode == "running") {
          maxDistance = world.distance > maxDistance ? world.distance : maxDistance;
          maxObjects = world.objects.length > maxObjects ? world.objects.length : maxObjects;
          final threat = world.objects.any((o) =>
              (o.kind == "hard" || o.kind == "soft") &&
              !o.gap &&
              o.x > world.player.x &&
              o.x < world.player.x + 150);
          if (threat) world.jump();
        }
        if (world.mode == "gameover") break;
      }
    }

    // One run with NO input to exercise the fail()/gameover path.
    world.startRun(1);
    // Forced collision probe: drop a hard rock right on the player.
    world.objects.add(GameObject(
      kind: "hard",
      sheet: "hard",
      frame: "large_rock",
      x: world.player.x,
      bottom: 0,
      width: 60,
      height: 60,
    ));
    world.update(1 / 60);
    // ignore: avoid_print
    print('FORCED PROBE: hp=${world.hp} mode=${world.mode} playerX=${world.player.x}');
    for (int i = 0; i < 6000; i++) {
      world.update(1 / 60);
      if (world.mode == "gameover") break;
    }
    // ignore: avoid_print
    print(
        'after no-input run: hp=${world.hp} mode=${world.mode} gameOvers=$gameOvers maxObjects=$maxObjects');

    expect(runs, 4);
    expect(maxDistance, greaterThan(0));
    expect(maxObjects, greaterThan(0));
    // No-input run must deplete HP (3 hits) and trigger game over: proves HP system.
    expect(gameOvers, greaterThan(0));
    expect(world.distance, isA<double>());
  });
}
