class Skin {
  final int id;
  final String key;
  final String name;
  final String accessory;
  final String buff;
  final int cost;
  final int? requiresLevel;

  const Skin({
    required this.id,
    required this.key,
    required this.name,
    required this.accessory,
    required this.buff,
    required this.cost,
    this.requiresLevel,
  });
}

class Level {
  final int id;
  final String key;
  final String keyB;
  final String foreground;
  final String platform;
  final String ledge;
  final String landmark;
  final String traversal;
  final String name;
  final List<String> soft;
  final List<String> hard;
  final List<String>? extraSoft;
  final List<String>? extraHard;
  final String? enemy;
  final String? extraEnemy;
  final String? moving;
  final String? hazard;
  final String? gap;

  const Level({
    required this.id,
    required this.key,
    required this.keyB,
    required this.foreground,
    required this.platform,
    required this.ledge,
    required this.landmark,
    required this.traversal,
    required this.name,
    required this.soft,
    required this.hard,
    this.extraSoft,
    this.extraHard,
    this.enemy,
    this.extraEnemy,
    this.moving,
    this.hazard,
    this.gap,
  });
}

class BiomeVariety {
  final String critter;
  final String sheet;
  final String relic;
  final bool high;

  const BiomeVariety({
    required this.critter,
    required this.sheet,
    required this.relic,
    required this.high,
  });
}

class NestItem {
  final String id;
  final String name;
  final int cost;
  final String buff;
  final double antsBonus;
  final double scoreBonus;
  final int extraHp;
  final double magnetBonus;
  final double comboBonus;
  final bool revive;
  final bool goldBonus;

  const NestItem({
    required this.id,
    required this.name,
    required this.cost,
    required this.buff,
    this.antsBonus = 0,
    this.scoreBonus = 0,
    this.extraHp = 0,
    this.magnetBonus = 0,
    this.comboBonus = 0,
    this.revive = false,
    this.goldBonus = false,
  });
}

const List<Skin> skins = [
  Skin(id: 1, key: "SKIN_01_SHEET", name: "The Native", accessory: "Natural", buff: "Tanpa buff — seimbang dan ringan.", cost: 0),
  Skin(id: 2, key: "SKIN_02_SHEET", name: "Explorer", accessory: "Topi safari + goggles", buff: "Kabut malam 45% lebih tipis.", cost: 80),
  Skin(id: 3, key: "SKIN_03_SHEET", name: "Artisan Saddle Bag", accessory: "Tas sadel handmade", buff: "Semut dan skor lari ×1.2.", cost: 140),
  Skin(id: 4, key: "SKIN_04_SHEET", name: "Mecha-Golin", accessory: "Pelat besi neon", buff: "Hancurkan 1 batu medium per lari.", cost: 220),
  Skin(id: 5, key: "SKIN_05_SHEET", name: "Canvas Carryall", accessory: "Tas kanvas besar", buff: "Magnet aktif 3 detik lebih lama.", cost: 300),
  Skin(id: 6, key: "SKIN_06_SHEET", name: "Crystal Shell", accessory: "Sisik kristal", buff: "Gua dan malam diterangi otomatis.", cost: 390),
  Skin(id: 7, key: "SKIN_07_SHEET", name: "Leather Sling Bag", accessory: "Tas selempang vintage", buff: "1× revive otomatis saat jatuh.", cost: 500),
  Skin(id: 8, key: "SKIN_08_SHEET", name: "Ronin", accessory: "Headband + armor bambu", buff: "Hitbox 10% lebih kecil.", cost: 650),
  Skin(id: 9, key: "SKIN_09_SHEET", name: "Cozy Knit", accessory: "Sweater + syal", buff: "Kebal slow lumpur dan salju.", cost: 820),
  Skin(id: 10, key: "SKIN_10_SHEET", name: "Golden Pangolin", accessory: "Sisik emas murni", buff: "Poin pembangunan sarang +200%.", cost: 0, requiresLevel: 10),
];

const List<Level> levels = [
  Level(id: 1, key: "LEVEL_01_BG", keyB: "LEVEL_01_BG_B", foreground: "LEVEL_01_FG", platform: "PLATFORM_01", ledge: "LEDGE_01", landmark: "rainforest_tree_shrine", traversal: "leaf_bob", name: "Lush Rainforest", soft: ["bamboo_basket", "rotten_wood", "thorn_bush"], hard: ["fallen_tree", "large_rock"]),
  Level(id: 2, key: "LEVEL_02_BG", keyB: "LEVEL_02_BG_B", foreground: "LEVEL_02_FG", platform: "PLATFORM_02", ledge: "LEDGE_02", landmark: "mangrove_totem", traversal: "leaf_bob", name: "Muddy Riverbank", soft: ["mud_mound", "giant_lily"], hard: ["thick_log"], extraSoft: ["reed_bundle", "mud_pot"], extraEnemy: "macaque", enemy: "crocodile", hazard: "rolling_boulder"),
  Level(id: 3, key: "LEVEL_03_BG", keyB: "LEVEL_03_BG_B", foreground: "LEVEL_03_FG", platform: "PLATFORM_03", ledge: "LEDGE_03", landmark: "camp_watchtower", traversal: "canvas_spring", name: "Abandoned Camp", soft: ["old_tent", "wooden_crate"], hard: ["campfire", "iron_barrel"], extraSoft: ["canvas_screen", "supply_sack"], extraEnemy: "wild_boar", hazard: "spinning_trap"),
  Level(id: 4, key: "LEVEL_04_BG", keyB: "LEVEL_04_BG_B", foreground: "LEVEL_04_FG", platform: "PLATFORM_04", ledge: "LEDGE_04", landmark: "poacher_blind", traversal: "canvas_spring", name: "Poacher's Trail", soft: ["trap_net"], hard: ["iron_cage", "bear_trap"], extraSoft: ["rope_barricade"], extraHard: ["warning_post"], extraEnemy: "cobra", moving: "trap_net", hazard: "spinning_trap"),
  Level(id: 5, key: "LEVEL_05_BG", keyB: "LEVEL_05_BG_B", foreground: "LEVEL_05_FG", platform: "PLATFORM_05", ledge: "LEDGE_05", landmark: "crystal_waterfall", traversal: "crystal_lift", name: "Glowing Caves", soft: ["fragile_crystal", "giant_mushroom"], hard: ["stone_pillar", "dark_chasm_edge"], extraSoft: ["crystal_eggs", "bone_mushroom"], extraEnemy: "cave_bat", hazard: "falling_crystal", gap: "dark_chasm_edge"),
  Level(id: 6, key: "LEVEL_06_BG", keyB: "LEVEL_06_BG_B", foreground: "LEVEL_06_FG", platform: "PLATFORM_06", ledge: "LEDGE_06", landmark: "ruin_observatory", traversal: "ruin_slab", name: "Ancient Ruins", soft: ["clay_jar", "small_statue"], hard: ["stone_wall", "fallen_column"], extraSoft: ["mosaic_heap", "root_idol"], extraEnemy: "monitor_lizard", hazard: "rolling_boulder"),
  Level(id: 7, key: "LEVEL_07_BG", keyB: "LEVEL_07_BG_B", foreground: "LEVEL_07_FG", platform: "PLATFORM_07", ledge: "LEDGE_07", landmark: "termite_cathedral", traversal: "ruin_slab", name: "Dry Savannah", soft: ["dry_branches", "empty_termite_nest"], hard: ["baobab_trunk"], extraSoft: ["tumbleweed", "termite_tower"], enemy: "hyena", extraEnemy: "wild_boar", hazard: "rolling_boulder"),
  Level(id: 8, key: "LEVEL_08_BG", keyB: "LEVEL_08_BG_B", foreground: "LEVEL_08_FG", platform: "PLATFORM_08", ledge: "LEDGE_08", landmark: "cliff_shrine", traversal: "bridge_plank", name: "Wobbly Bridge", soft: ["rotten_planks", "loose_vines"], hard: ["broken_bridge_gap"], extraSoft: ["bridge_bucket"], extraEnemy: "macaque", moving: "bridge_rope", hazard: "swinging_log", gap: "broken_bridge_gap"),
  Level(id: 9, key: "LEVEL_09_BG", keyB: "LEVEL_09_BG_B", foreground: "LEVEL_09_FG", platform: "PLATFORM_09", ledge: "LEDGE_09", landmark: "moon_gate", traversal: "leaf_bob", name: "Midnight Jungle", soft: ["loose_vines"], hard: ["thorn_tree"], extraSoft: ["moon_flower"], enemy: "owl", extraEnemy: "cobra", moving: "poison_vine", hazard: "falling_crystal"),
  Level(id: 10, key: "LEVEL_10_BG", keyB: "LEVEL_10_BG_B", foreground: "LEVEL_10_FG", platform: "PLATFORM_10", ledge: "LEDGE_10", landmark: "core_world_root", traversal: "crystal_lift", name: "The Core · Endless", soft: ["bamboo_basket", "mud_mound", "wooden_crate", "fragile_crystal", "clay_jar", "dry_branches"], hard: ["large_rock", "iron_barrel", "stone_wall", "medium_rock", "thorn_tree"], extraSoft: ["fern_bundle", "supply_sack", "crystal_eggs", "mosaic_heap", "tumbleweed", "moon_flower"], extraHard: ["warning_post"], enemy: "hyena", extraEnemy: "wild_boar", hazard: "spinning_trap"),
];

const List<BiomeVariety> biomeVariety = [
  BiomeVariety(critter: "leaf_beetle", sheet: "gentleA", relic: "rain_seed", high: false),
  BiomeVariety(critter: "mud_frog", sheet: "gentleA", relic: "river_pearl", high: false),
  BiomeVariety(critter: "camp_civet", sheet: "gentleA", relic: "camp_compass", high: false),
  BiomeVariety(critter: "net_spider", sheet: "gentleA", relic: "freedom_key", high: false),
  BiomeVariety(critter: "cave_moth", sheet: "gentleA", relic: "crystal_heart", high: true),
  BiomeVariety(critter: "ruin_gecko", sheet: "gentleB", relic: "sun_disk", high: false),
  BiomeVariety(critter: "meerkat", sheet: "gentleB", relic: "savannah_feather", high: false),
  BiomeVariety(critter: "bridge_crab", sheet: "gentleB", relic: "bridge_charm", high: false),
  BiomeVariety(critter: "moon_mantis", sheet: "gentleB", relic: "moon_berry", high: false),
  BiomeVariety(critter: "core_sprite", sheet: "gentleB", relic: "core_seed", high: true),
];

const List<NestItem> nestItems = [
  NestItem(id: "round_rug", name: "Karpet Anyam", cost: 45, buff: "Koin pulang +8%", antsBonus: 0.08),
  NestItem(id: "nest_lamp", name: "Lampu Keramik", cost: 70, buff: "Magnet +1.5 dtk", magnetBonus: 1.5),
  NestItem(id: "woven_chair", name: "Kursi Rotan", cost: 95, buff: "+1 nyawa awal", extraHp: 1),
  NestItem(id: "low_table", name: "Meja Akar", cost: 120, buff: "Skor +10%", scoreBonus: 0.10),
  NestItem(id: "leaf_bed", name: "Ranjang Daun", cost: 160, buff: "1× revive otomatis saat jatuh", revive: true),
  NestItem(id: "hanging_lantern", name: "Lentera Gantung", cost: 210, buff: "Koin emas 2× lebih sering", goldBonus: true),
  NestItem(id: "shelf", name: "Rak Akar", cost: 260, buff: "Combo tahan +1.5 dtk", comboBonus: 1.5),
  NestItem(id: "tea_set", name: "Set Teh Tanah Liat", cost: 320, buff: "Koin pulang +15%", antsBonus: 0.15),
];

class GameSave {
  int version = 1;
  int ants = 0;
  int bestScore = 0;
  int bestDistance = 0;
  int maxLevel = 1;
  int selectedSkin = 1;
  List<int> unlockedSkins = [1];
  List<String> nestItems = [];

  GameSave();

  Map<String, dynamic> toJson() => {
        "version": version,
        "ants": ants,
        "bestScore": bestScore,
        "bestDistance": bestDistance,
        "maxLevel": maxLevel,
        "selectedSkin": selectedSkin,
        "unlockedSkins": unlockedSkins,
        "nestItems": nestItems,
      };

  static GameSave fromJson(Map<String, dynamic>? value) {
    final source = (value != null && value["version"] == 1) ? value : <String, dynamic>{};
    final save = GameSave();
    save.ants = _clampInt(source["ants"], 0, null);
    save.bestScore = _clampInt(source["bestScore"], 0, null);
    save.bestDistance = _clampInt(source["bestDistance"], 0, null);
    save.maxLevel = _clampInt(source["maxLevel"], 1, 10);
    save.selectedSkin = _clampInt(source["selectedSkin"], 1, 10);
    final unlocked = source["unlockedSkins"];
    save.unlockedSkins = {
      1,
      ...(unlocked is List ? unlocked.whereType<int>() : <int>[]),
    }.toList();
    final nests = source["nestItems"];
    save.nestItems = (nests is List ? nests.whereType<String>() : <String>[]).toList();
    return save;
  }
}

int _clampInt(dynamic value, int min, int? max) {
  int v = (value is int ? value : int.tryParse(value?.toString() ?? "") ?? min);
  if (v < min) v = min;
  if (max != null && v > max) v = max;
  return v;
}
