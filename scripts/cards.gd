class_name Cards
extends RefCounted
## Factions and card definitions. Speeds are in pixels per second, ranges in
## pixels (measured edge to edge), hit_speed is seconds between attacks.
## `size` is how big the sprite is drawn (its longer side, in pixels).

const FACTION_IDS := ["scrappers", "infected", "dead_crown"]

const FACTIONS := {
	"scrappers": {
		"name": "Scrappers", "tagline": "Junk, rockets and grit",
		"color": Color(0.95, 0.4, 0.2), "hero": "rivet_warden",
		"princess": "scrap_watchtower", "king": "rocket_nest", "projectile": "scrap_rocket",
		"deck": ["rivet_warden", "signal_sniper", "scrap_colossus", "scrap_drone",
			"rocket_rider", "boom_buggy", "turret_tinker", "rocket_barrage"],
	},
	"infected": {
		"name": "Infected", "tagline": "Toxins, mutants and plague",
		"color": Color(0.55, 0.88, 0.2), "hero": "serum_mauler",
		"princess": "toxic_sprayer", "king": "hive_mother", "projectile": "blight_rocket",
		"deck": ["serum_mauler", "mutation_marksman", "hazmat_juggernaut", "plague_glider",
			"fat_dragon", "smog_caster", "chem_turret", "blight_cloud"],
	},
	"dead_crown": {
		"name": "Dead Crown", "tagline": "Bone, hexes and dark kings",
		"color": Color(0.68, 0.4, 0.98), "hero": "crown_bastion",
		"princess": "gargoyle_roost", "king": "soul_obelisk", "projectile": "hex_orb",
		"deck": ["crown_bastion", "hex_archer", "bone_paladin", "soul_harrier",
			"bone_dragon", "soul_seer", "obelisk_priest", "hex_nova"],
	},
}

const DEFAULTS := {
	"type": "troop",
	"count": 1,
	"hp": 100.0,
	"damage": 50.0,
	"hit_speed": 1.0,
	"range": 14.0,
	"speed": 60.0,
	"sight": 200.0,
	"targets": "any",
	"air": false,
	"radius": 12.0,
	"size": 64.0,
	"splash": 0.0,
	"lifetime": 0.0,
	"spell_radius": 0.0,
	"tower_mult": 1.0,
	"poison": 0.0,
	"kamikaze": false,
}

const DATA := {
	# --- Scrappers -----------------------------------------------------------
	"rivet_warden": {
		"name": "Rivet Warden", "cost": 3, "hp": 1350.0, "damage": 160.0, "hit_speed": 1.2,
		"speed": 60.0, "sight": 190.0, "targets": "ground", "radius": 15.0, "size": 76.0,
		"desc": "Shield brawler with a spiked mace.",
	},
	"signal_sniper": {
		"name": "Signal Sniper", "cost": 4, "hp": 520.0, "damage": 210.0, "hit_speed": 1.7,
		"range": 200.0, "speed": 55.0, "sight": 230.0, "radius": 13.0, "size": 69.0,
		"desc": "Long-range marksman. Hits air and ground.",
	},
	"scrap_colossus": {
		"name": "Scrap Colossus", "cost": 5, "hp": 3300.0, "damage": 210.0, "hit_speed": 1.5,
		"speed": 45.0, "targets": "buildings", "radius": 22.0, "size": 108.0,
		"desc": "Huge tank. Only attacks buildings.",
	},
	"scrap_drone": {
		"name": "Scrap Drones", "cost": 3, "count": 3, "hp": 200.0, "damage": 75.0,
		"range": 50.0, "speed": 85.0, "sight": 190.0, "air": true, "radius": 10.0, "size": 57.0,
		"desc": "Three flying scout drones.",
	},
	"rocket_rider": {
		"name": "Rocket Rider", "cost": 4, "hp": 750.0, "damage": 150.0, "splash": 35.0,
		"hit_speed": 1.4, "range": 60.0, "speed": 70.0, "targets": "ground", "air": true,
		"radius": 15.0, "size": 80.0, "desc": "Flying raider. Splash damage on ground troops.",
	},
	"boom_buggy": {
		"name": "Boom Buggy", "cost": 2, "hp": 380.0, "damage": 380.0, "splash": 55.0,
		"hit_speed": 0.2, "range": 8.0, "speed": 120.0, "sight": 230.0, "targets": "buildings",
		"radius": 14.0, "size": 74.0, "kamikaze": true,
		"desc": "Rushes a building and explodes.",
	},
	"turret_tinker": {
		"name": "Turret Tinker", "cost": 4, "type": "building", "hp": 1000.0, "damage": 100.0,
		"hit_speed": 0.8, "range": 200.0, "speed": 0.0, "radius": 20.0, "size": 87.0,
		"lifetime": 35.0, "desc": "Defensive turret. Hits air and ground.",
	},
	"rocket_barrage": {
		"name": "Rocket Barrage", "cost": 4, "type": "spell", "damage": 500.0, "spell_radius": 85.0,
		"tower_mult": 0.35, "size": 80.0, "desc": "Rocket strike anywhere on the map.",
	},
	# --- Infected ------------------------------------------------------------
	"serum_mauler": {
		"name": "Serum Mauler", "cost": 3, "hp": 1250.0, "damage": 185.0, "hit_speed": 1.3,
		"speed": 60.0, "sight": 190.0, "targets": "ground", "radius": 15.0, "size": 76.0,
		"desc": "Hammer-swinging mutant brute.",
	},
	"mutation_marksman": {
		"name": "Mutation Marksman", "cost": 4, "hp": 480.0, "damage": 230.0, "hit_speed": 1.8,
		"range": 200.0, "speed": 55.0, "sight": 230.0, "radius": 13.0, "size": 69.0,
		"desc": "Chem sniper. Hits air and ground.",
	},
	"hazmat_juggernaut": {
		"name": "Hazmat Juggernaut", "cost": 5, "hp": 3000.0, "damage": 240.0, "hit_speed": 1.5,
		"speed": 45.0, "targets": "buildings", "radius": 22.0, "size": 106.0,
		"desc": "Armoured tank. Only attacks buildings.",
	},
	"plague_glider": {
		"name": "Plague Gliders", "cost": 3, "count": 2, "hp": 300.0, "damage": 90.0,
		"range": 110.0, "speed": 80.0, "air": true, "radius": 11.0, "size": 62.0,
		"desc": "Two gliders. Hit air and ground.",
	},
	"fat_dragon": {
		"name": "Fat Dragon", "cost": 5, "hp": 1500.0, "damage": 130.0, "splash": 45.0,
		"hit_speed": 1.6, "range": 70.0, "speed": 50.0, "air": true, "radius": 20.0, "size": 120.0,
		"desc": "Flying tank with toxic splash breath.",
	},
	"smog_caster": {
		"name": "Smog Caster", "cost": 4, "hp": 650.0, "damage": 110.0, "splash": 55.0,
		"hit_speed": 1.5, "range": 150.0, "speed": 55.0, "targets": "ground", "radius": 14.0,
		"size": 71.0, "desc": "Lobs toxin that splashes ground troops.",
	},
	"chem_turret": {
		"name": "Chem Turret", "cost": 4, "type": "building", "hp": 1000.0, "damage": 60.0,
		"splash": 45.0, "hit_speed": 0.7, "range": 170.0, "speed": 0.0, "targets": "ground",
		"radius": 20.0, "size": 90.0, "lifetime": 35.0, "desc": "Toxic turret. Splash on ground troops.",
	},
	"blight_cloud": {
		"name": "Blight Cloud", "cost": 4, "type": "spell", "damage": 560.0, "spell_radius": 95.0,
		"tower_mult": 0.35, "poison": 4.0, "size": 80.0,
		"desc": "Poison cloud. Damage over 4 seconds.",
	},
	# --- Dead Crown ----------------------------------------------------------
	"crown_bastion": {
		"name": "Crown Bastion", "cost": 4, "hp": 1900.0, "damage": 150.0, "hit_speed": 1.3,
		"speed": 50.0, "sight": 190.0, "targets": "ground", "radius": 17.0, "size": 83.0,
		"desc": "Armoured shield wall.",
	},
	"hex_archer": {
		"name": "Hex Archers", "cost": 3, "count": 2, "hp": 300.0, "damage": 85.0,
		"range": 150.0, "speed": 60.0, "radius": 11.0, "size": 64.0,
		"desc": "Two crystal-bow archers. Hit air and ground.",
	},
	"bone_paladin": {
		"name": "Bone Paladin", "cost": 5, "hp": 3100.0, "damage": 230.0, "hit_speed": 1.5,
		"speed": 45.0, "targets": "buildings", "radius": 22.0, "size": 106.0,
		"desc": "Undead tank. Only attacks buildings.",
	},
	"soul_harrier": {
		"name": "Soul Harriers", "cost": 3, "count": 2, "hp": 320.0, "damage": 100.0,
		"hit_speed": 1.1, "range": 30.0, "speed": 85.0, "air": true, "radius": 12.0, "size": 67.0,
		"desc": "Two winged blades. Hit air and ground.",
	},
	"bone_dragon": {
		"name": "Bone Dragon", "cost": 5, "hp": 1400.0, "damage": 150.0, "splash": 45.0,
		"hit_speed": 1.6, "range": 80.0, "speed": 55.0, "air": true, "radius": 20.0, "size": 124.0,
		"desc": "Flying arcane destroyer. Splash damage.",
	},
	"soul_seer": {
		"name": "Soul Seer", "cost": 4, "hp": 600.0, "damage": 120.0, "splash": 50.0,
		"hit_speed": 1.4, "range": 160.0, "speed": 55.0, "radius": 14.0, "size": 74.0,
		"desc": "Cursed mage. Splash hits air and ground.",
	},
	"obelisk_priest": {
		"name": "Obelisk Priest", "cost": 4, "type": "building", "hp": 1100.0, "damage": 120.0,
		"hit_speed": 0.9, "range": 200.0, "speed": 0.0, "radius": 20.0, "size": 97.0,
		"lifetime": 35.0, "desc": "Summoned obelisk. Hits air and ground.",
	},
	"hex_nova": {
		"name": "Hex Nova", "cost": 4, "type": "spell", "damage": 480.0, "spell_radius": 90.0,
		"tower_mult": 0.35, "size": 80.0, "desc": "Arcane burst anywhere on the map.",
	},
}


static func get_card(id: String) -> Dictionary:
	var card: Dictionary = DEFAULTS.duplicate()
	card.merge(DATA[id], true)
	card["id"] = id
	return card


static func faction(id: String) -> Dictionary:
	return FACTIONS[id]


static func faction_of_card(card_id: String) -> String:
	for f in FACTION_IDS:
		if FACTIONS[f]["deck"].has(card_id):
			return f
	return FACTION_IDS[0]
