class_name Cards
extends RefCounted
## Card definitions. Speeds are in pixels per second, ranges in pixels
## (measured edge to edge), hit_speed is seconds between attacks.

const DECK := ["scrapper", "archers", "giant", "drones", "gremlins", "cannon", "firebomb", "ram"]

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
	"splash": 0.0,
	"lifetime": 0.0,
	"spell_radius": 0.0,
	"tower_mult": 1.0,
}

const DATA := {
	"scrapper": {
		"name": "Scrapper", "cost": 3, "hp": 1350.0, "damage": 160.0, "hit_speed": 1.2,
		"range": 14.0, "speed": 60.0, "sight": 190.0, "targets": "ground", "radius": 15.0,
		"desc": "Tough melee bot with a giant wrench.",
	},
	"archers": {
		"name": "Bolt Archers", "cost": 3, "count": 2, "hp": 300.0, "damage": 85.0,
		"hit_speed": 1.0, "range": 150.0, "speed": 60.0, "sight": 200.0, "targets": "any",
		"radius": 11.0, "desc": "Two ranged bots. Hit air and ground.",
	},
	"giant": {
		"name": "Junk Giant", "cost": 5, "hp": 3200.0, "damage": 210.0, "hit_speed": 1.5,
		"range": 14.0, "speed": 45.0, "sight": 200.0, "targets": "buildings", "radius": 22.0,
		"desc": "Slow tank. Only attacks buildings.",
	},
	"drones": {
		"name": "Drone Swarm", "cost": 3, "count": 3, "hp": 200.0, "damage": 75.0,
		"hit_speed": 1.0, "range": 50.0, "speed": 85.0, "sight": 190.0, "targets": "any",
		"air": true, "radius": 10.0, "desc": "Three flying drones.",
	},
	"gremlins": {
		"name": "Gear Gremlins", "cost": 2, "count": 4, "hp": 110.0, "damage": 70.0,
		"hit_speed": 1.0, "range": 10.0, "speed": 90.0, "sight": 170.0, "targets": "ground",
		"radius": 8.0, "desc": "Four fast little biters.",
	},
	"cannon": {
		"name": "Magnet Cannon", "cost": 3, "type": "building", "hp": 900.0, "damage": 120.0,
		"hit_speed": 0.9, "range": 200.0, "speed": 0.0, "sight": 200.0, "targets": "ground",
		"radius": 20.0, "lifetime": 30.0, "desc": "Defensive building. Pulls tanks in.",
	},
	"firebomb": {
		"name": "Fire Bomb", "cost": 4, "type": "spell", "damage": 520.0, "spell_radius": 85.0,
		"tower_mult": 0.35, "desc": "Area damage anywhere on the map.",
	},
	"ram": {
		"name": "Wrecking Ram", "cost": 4, "hp": 1300.0, "damage": 240.0, "hit_speed": 1.6,
		"range": 14.0, "speed": 110.0, "sight": 220.0, "targets": "buildings", "radius": 16.0,
		"desc": "Fast. Charges straight at buildings.",
	},
}


static func get_card(id: String) -> Dictionary:
	var card: Dictionary = DEFAULTS.duplicate()
	card.merge(DATA[id], true)
	card["id"] = id
	return card
