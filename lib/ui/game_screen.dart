import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../game/atlas.dart';
import '../game/config.dart';
import '../game/game.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  late final TumbletailGame game;
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    game = TumbletailGame();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _focus.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      game.persistNow();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff1b2a30),
      body: SafeArea(
        child: Focus(
          focusNode: _focus,
          autofocus: true,
          onKeyEvent: (node, event) {
            if (event is KeyDownEvent) {
              if (event.logicalKey == LogicalKeyboardKey.space ||
                  event.logicalKey == LogicalKeyboardKey.arrowUp ||
                  event.logicalKey == LogicalKeyboardKey.keyW) {
                game.tapJump();
                return KeyEventResult.handled;
              }
              if (event.logicalKey == LogicalKeyboardKey.arrowDown ||
                  event.logicalKey == LogicalKeyboardKey.keyS) {
                game.tapSlide();
                return KeyEventResult.handled;
              }
              if (event.logicalKey == LogicalKeyboardKey.escape) {
                game.pauseToggle();
                return KeyEventResult.handled;
              }
            }
            return KeyEventResult.ignored;
          },
          child: ListenableBuilder(
            listenable: game,
            builder: (context, _) {
              return GestureDetector(
                onTapDown: (_) => game.tapJump(),
                child: Stack(
                  children: [
                    GameWidget(game: game),
                    if (game.phase == "loading") const LoadingView(),
                    if (game.phase == "menu") MenuOverlay(game: game),
                    if (game.phase == "running") HudOverlay(game: game),
                    if (game.phase == "paused") PauseOverlay(game: game),
                    if (game.phase == "gameover") GameOverOverlay(game: game),
                  if (game.tutorialOpen) HowToPlayOverlay(game: game),
                  if (game.levelSelectOpen) LevelSelectOverlay(game: game),
                  ToastOverlay(game: game),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class LevelSelectOverlay extends StatelessWidget {
  final TumbletailGame game;
  const LevelSelectOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final maxLevel = game.save.maxLevel;
    return Container(
      color: const Color(0xff101a1d).withOpacity(0.88),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620, maxHeight: 560),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
            decoration: BoxDecoration(
              color: const Color(0xff1d2a2d),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: const Color(0xff52746f).withOpacity(0.5)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.35),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xff9ce5ce).withOpacity(0.14),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text("✦", style: TextStyle(color: Color(0xff9ce5ce), fontSize: 24)),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Pilih Area", style: TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.bold)),
                          SizedBox(height: 3),
                          Text("Tentukan jalur petualanganmu", style: TextStyle(color: Colors.white54, fontSize: 12)),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: game.closeLevelSelect,
                      icon: const Icon(Icons.close, color: Colors.white60),
                      tooltip: "Tutup",
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          minHeight: 6,
                          value: maxLevel / levels.length,
                          backgroundColor: Colors.white10,
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xff9ce5ce)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text("$maxLevel / ${levels.length} area", style: const TextStyle(color: Colors.white60, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.only(top: 2, bottom: 4),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 280,
                      mainAxisExtent: 76,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: levels.length,
                    itemBuilder: (context, i) {
                      final lv = levels[i];
                      final unlocked = lv.id <= maxLevel;
                      final accent = _levelAccent(i);
                      return _LevelCard(
                        level: lv,
                        accent: accent,
                        unlocked: unlocked,
                        onTap: unlocked
                            ? () {
                                game.closeLevelSelect();
                                game.startRun(lv.id);
                              }
                            : null,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: game.closeLevelSelect,
                  child: const Text("Kembali ke Sarang", style: TextStyle(color: Colors.white70)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Color _levelAccent(int index) {
  const accents = [
    Color(0xff75c69b),
    Color(0xff78b9ad),
    Color(0xffd19a68),
    Color(0xffcf8164),
    Color(0xff91c8d2),
    Color(0xffc6a477),
    Color(0xffd6b65c),
    Color(0xffb88970),
    Color(0xff777db7),
    Color(0xffe0b85d),
  ];
  return accents[index % accents.length];
}

class _LevelCard extends StatelessWidget {
  final Level level;
  final Color accent;
  final bool unlocked;
  final VoidCallback? onTap;

  const _LevelCard({
    required this.level,
    required this.accent,
    required this.unlocked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            color: const Color(0xff26383a),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: accent.withOpacity(unlocked ? 0.55 : 0.16)),
          ),
          child: Row(
            children: [
              Container(
                width: 64,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: accent.withOpacity(unlocked ? 0.18 : 0.06),
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(17)),
                ),
                child: Center(
                  child: Text(
                    level.id.toString().padLeft(2, '0'),
                    style: TextStyle(color: unlocked ? accent : Colors.white30, fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(level.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: unlocked ? Colors.white : Colors.white38, fontSize: 14, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 5),
                      Text(unlocked ? "SIAP DIJELAJAHI" : "SELESAIKAN AREA SEBELUMNYA",
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: unlocked ? accent : Colors.white24, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Icon(unlocked ? Icons.arrow_forward_rounded : Icons.lock_outline_rounded,
                    size: 18, color: unlocked ? accent : Colors.white24),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HowToPlayOverlay extends StatelessWidget {
  final TumbletailGame game;
  const HowToPlayOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final auto = game.tutorialIsAuto;
    return Container(
      color: const Color(0xff101a1d).withOpacity(0.88),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 620, maxHeight: 560),
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xff24383a), Color(0xff1b292d)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: const Color(0xff9ce5ce).withOpacity(0.28)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 28, offset: const Offset(0, 12)),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xff9ce5ce).withOpacity(0.14),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.menu_book_rounded, color: Color(0xff9ce5ce), size: 25),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Cara Main", style: TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.bold)),
                        SizedBox(height: 3),
                        Text("Kuasai gerakan, kumpulkan koin, bertahan sejauh mungkin.",
                            style: TextStyle(color: Colors.white54, fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Expanded(
                child: Scrollbar(
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(right: 6, bottom: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _GuideSection(
                          title: "GERAKAN",
                          icon: Icons.gamepad_rounded,
                          color: const Color(0xff7ed0c4),
                          items: const [
                            _GuideItem(icon: Icons.arrow_upward_rounded, title: "LONCAT", text: "Spasi, W, ↑, atau tombol kiri untuk melewati rintangan dan jurang."),
                            _GuideItem(icon: Icons.shield_rounded, title: "ARMOR SLIDE", text: "S, ↓, atau tombol kanan untuk menghancurkan benda lunak dan hewan kecil."),
                          ],
                        ),
                        _GuideSection(
                          title: "KUMPULKAN",
                          icon: Icons.auto_awesome_rounded,
                          color: const Color(0xffe4b85e),
                          items: const [
                            _GuideItem(icon: Icons.circle, title: "KOIN SEMUT", text: "Koin emas bernilai 5×. Koin beruntun membangun COMBO dan skor lebih besar."),
                            _GuideItem(icon: Icons.bolt_rounded, title: "POWER-UP", text: "Magnet menarik koin otomatis. Relik biome memberi bonus besar."),
                          ],
                        ),
                        _GuideSection(
                          title: "BERTAHAN",
                          icon: Icons.favorite_rounded,
                          color: const Color(0xffe58b78),
                          items: const [
                            _GuideItem(icon: Icons.warning_amber_rounded, title: "HINDARI", text: "Rintangan keras, musuh, dan jurang dapat mengurangi nyawa."),
                            _GuideItem(icon: Icons.favorite_border_rounded, title: "3 NYAWA", text: "Habis nyawa berarti perjalanan selesai. Kelola timing lompat dan slide."),
                          ],
                        ),
                        _GuideSection(
                          title: "PETUALANGAN",
                          icon: Icons.explore_rounded,
                          color: const Color(0xffb7a0e5),
                          items: const [
                            _GuideItem(icon: Icons.trending_up_rounded, title: "MAKIN JAUH", text: "Level, rintangan, dan musuh akan semakin variatif."),
                            _GuideItem(icon: Icons.home_work_rounded, title: "KEMBANGKAN SARANG", text: "Beli skin dan perabot untuk mendapatkan buff tambahan."),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff7ed0c4),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
                ),
                onPressed: game.closeTutorial,
                child: Text(auto ? "Mengerti, Mulai!" : "Tutup",
                    style: const TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GuideSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<_GuideItem> items;

  const _GuideSection({required this.title, required this.icon, required this.color, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.13),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 17, color: color),
              const SizedBox(width: 7),
              Text(title, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1)),
            ],
          ),
          const SizedBox(height: 5),
          ...items,
        ],
      ),
    );
  }
}

class _GuideItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;

  const _GuideItem({required this.icon, required this.title, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.white70),
          const SizedBox(width: 9),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.white60, fontSize: 12, height: 1.35),
                children: [
                  TextSpan(text: "$title  ", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  TextSpan(text: text),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: Colors.white),
          SizedBox(height: 16),
          Text("Menyiapkan jalur …",
              style: TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}

class ToastOverlay extends StatelessWidget {
  final TumbletailGame game;
  const ToastOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    if (game.toastMessage.isEmpty) return const SizedBox.shrink();
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.only(top: 60),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.54),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(game.toastMessage,
              style: const TextStyle(color: Colors.white, fontSize: 14)),
        ),
      ),
    );
  }
}

class HudOverlay extends StatelessWidget {
  final TumbletailGame game;
  const HudOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final w = game.world!;
    return Stack(
      children: [
        Positioned(
          top: 12,
          left: 12,
          right: 12,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.38),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Text("◉",
                        style: TextStyle(color: Color(0xffd7a34c), fontSize: 16)),
                    const SizedBox(width: 4),
                    Text(w.antsRun.floor().toString(),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    if (w.combo >= 2)
                      Text(" ×${w.combo}",
                          style: const TextStyle(color: Color(0xff9ce5ce))),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("${w.distance.floor()}m",
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  Text(levels[w.level - 1].name,
                      style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.38),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    for (int i = 0; i < w.maxHp; i++)
                      Text(
                        i < w.hp ? "❤" : "🤍",
                        style: const TextStyle(fontSize: 14),
                      ),
                  ],
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: game.openTutorial,
                icon: const Text("?", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              ),
              IconButton(
                onPressed: game.pauseToggle,
                icon: const Text("Ⅱ", style: TextStyle(color: Colors.white, fontSize: 20)),
              ),
            ],
          ),
        ),
        Positioned(
          bottom: 24,
          right: 16,
          child: _ActionButton(
            label: "ARMOR SLIDE",
            color: const Color(0xffd98b5e),
            onTap: game.tapSlide,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionButton({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => onTap(),
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 8, 14, 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.92), const Color(0xffa95443)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xffffd2a1).withOpacity(0.58), width: 1.2),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.42), blurRadius: 15, spreadRadius: 1),
            BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 7, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: const Icon(Icons.shield_rounded, color: Color(0xfffff0d0), size: 25),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                ),
                const SizedBox(height: 3),
              
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AtlasFramePainter extends CustomPainter {
  final ui.Image image;
  final Rect content;
  _AtlasFramePainter(this.image, this.content);

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(size.width / content.width, size.height / content.height);
    final drawW = content.width * scale;
    final drawH = content.height * scale;
    final dx = (size.width - drawW) / 2;
    final dy = (size.height - drawH) / 2;
    canvas.drawImageRect(
      image,
      content,
      Rect.fromLTWH(dx, dy, drawW, drawH),
      Paint(),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class SkinPreview extends StatelessWidget {
  final Sheet sheet;
  final double size;
  const SkinPreview({required this.sheet, this.size = 46});

  @override
  Widget build(BuildContext context) {
    final frames = animationByName(sheet, "run");
    final frame = frames.isNotEmpty ? frames[0] : sheet.frames.values.first;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _AtlasFramePainter(sheet.image, frame.content)),
    );
  }
}

class NestPreview extends StatelessWidget {
  final Sheet sheet;
  final String id;
  final double size;
  const NestPreview({required this.sheet, required this.id, this.size = 46});

  @override
  Widget build(BuildContext context) {
    final frame = frameByName(sheet, id);
    if (frame == null) return SizedBox(width: size, height: size);
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _AtlasFramePainter(sheet.image, frame.content)),
    );
  }
}

class MenuOverlay extends StatelessWidget {
  final TumbletailGame game;
  const MenuOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.45),
      padding: const EdgeInsets.all(5),
      child: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: game.openTutorial,
                  icon: const Text("?", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const Text("Rolling Jungle Run",
                style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text("Gulung. Terobos. Bawa pulang coin yang banyak.",
                style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("AREA TERJAUH",
                          style: TextStyle(color: Colors.white54, fontSize: 11)),
                      Text(levels[math.max(0, game.save.maxLevel - 1)].name,
                          style: const TextStyle(color: Colors.white)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text("KOIN SEMUT", style: TextStyle(color: Colors.white54, fontSize: 11)),
                      Text("◉ ${game.save.ants}",
                          style: const TextStyle(color: Color(0xffd7a34c), fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const TabBar(
              tabs: [
                Tab(text: "Lari"),
                Tab(text: "Skin"),
                Tab(text: "Sarang"),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TabBarView(
                children: [
                  _RunTab(game: game),
                  _SkinsTab(game: game),
                  _NestTab(game: game),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RunTab extends StatelessWidget {
  final TumbletailGame game;
  const _RunTab({required this.game});

  @override
  Widget build(BuildContext context) {
    final skin = skins[game.save.selectedSkin - 1];
    return Row(
      children: [
        const Spacer(),
        Text("Memakai Skin ${skin.name}", style: const TextStyle(color: Colors.white70)),
        const SizedBox(width: 30),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xff7ed0c4),
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
          ),
          onPressed: game.startRun,
          child: const Text("Mulai Lari", style: TextStyle(color: Colors.white, fontSize: 18)),
        ),
        const SizedBox(width: 30),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.white54),
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
          ),
          onPressed: game.openLevelSelect,
          child: const Text("Pilih Lvl", style: TextStyle(color: Colors.white70)),
        ),
        const Spacer(),
      ],
    );
  }
}

class _SkinsTab extends StatelessWidget {
  final TumbletailGame game;
  const _SkinsTab({required this.game});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xffd7a34c).withOpacity(0.14),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xffd7a34c).withOpacity(0.35)),
                ),
                child: Text("◉ ${game.save.ants}",
                    style: const TextStyle(color: Color(0xffffd98b), fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: skins.length,
            itemBuilder: (context, i) {
              final skin = skins[i];
              final unlocked = game.save.unlockedSkins.contains(skin.id);
              final selected = game.save.selectedSkin == skin.id;
              return ListTile(
                onTap: () => game.selectSkin(skin.id),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                leading: game.resources != null
                    ? SkinPreview(sheet: game.resources!.skins[i])
                    : null,
                title: Text("${skin.id.toString().padLeft(2, '0')} · ${skin.name}",
                    style: const TextStyle(color: Colors.white)),
                subtitle: Text(skin.buff, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0xff9ce5ce).withOpacity(0.16)
                        : Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected ? const Color(0xff9ce5ce).withOpacity(0.55) : Colors.white12,
                    ),
                  ),
                  child: Text(
                    selected
                        ? "DIPAKAI"
                        : unlocked
                            ? "PAKAI"
                            : skin.requiresLevel != null
                                ? "LV ${skin.requiresLevel}"
                                : "✦ ${skin.cost}",
                    style: TextStyle(
                      color: selected ? const Color(0xff9ce5ce) : Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _NestTab extends StatelessWidget {
  final TumbletailGame game;
  const _NestTab({required this.game});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text("Sarang Nyaman ${game.save.nestItems.length}/${nestItems.length}",
              style: const TextStyle(color: Colors.white)),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: nestItems.length,
            itemBuilder: (context, i) {
              final item = nestItems[i];
              final owned = game.save.nestItems.contains(item.id);
              return ListTile(
                leading: game.resources != null
                    ? NestPreview(sheet: game.resources!.pickup, id: item.id)
                    : null,
                title: Text(item.name, style: const TextStyle(color: Colors.white)),
                subtitle: Text(item.buff, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                trailing: TextButton(
                  onPressed: owned ? null : () => game.buyNest(item.id),
                  child: Text(
                    owned ? "Sudah" : "✦ ${item.cost}",
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class PauseOverlay extends StatelessWidget {
  final TumbletailGame game;
  const PauseOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.54),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Tarik napas.", style: TextStyle(color: Colors.white, fontSize: 26)),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xff7ed0c4)),
              onPressed: game.pauseToggle,
              child: const Text("Lanjutkan", style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: game.goMenu,
              child: const Text("Ke Sarang", style: TextStyle(color: Colors.white70)),
            ),
          ],
        ),
      ),
    );
  }
}

class GameOverOverlay extends StatelessWidget {
  final TumbletailGame game;
  const GameOverOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final r = game.lastResult!;
    return Container(
      color: Colors.black.withOpacity(0.66),
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("PERJALANAN SELESAI",
                style: TextStyle(color: Colors.white54, fontSize: 14)),
            Text("${r.distance}m", style: const TextStyle(color: Colors.white, fontSize: 36)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _Stat(label: "SKOR", value: r.score.toString()),
                const SizedBox(width: 24),
                _Stat(label: "KOIN PULANG", value: "+${r.nestReward}"),
              ],
            ),
            const SizedBox(height: 8),
            Text("Combo terbaik ×${r.bestCombo} · Relik ${r.relics}",
                style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xff7ed0c4)),
              onPressed: game.startRun,
              child: const Text("Lari Lagi", style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: game.goMenu,
              child: const Text("Ke Sarang", style: TextStyle(color: Colors.white70)),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
