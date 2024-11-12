/mob/living/basic/droid/basic
	name = "droid frame"
	desc = "A basic droid frame with no armaments or armor. It can still bash skulls with its fists just fine, though."

	icon = 'monkestation/icons/mob/basic/basic_droids.dmi'
	icon_state = "frame"

	maxHealth = 50
	health = 50

	melee_damage_lower = 5
	melee_damage_upper = 10
	obj_damage = 20

/datum/armor/basic_melee_droid
	melee = 50
	bullet = 30 // Shotguns exist.

/mob/living/basic/droid/basic/melee
	name = "melee droid"
	desc = "A basic melee droid with heavy armor that excels in close quarters combat."
	armor_type = /datum/armor/basic_melee_droid
	speed = 1.2

	melee_damage_lower = 20
	melee_damage_upper = 30
	armour_penetration = 15
	obj_damage = 30

	wound_bonus = 10
	bare_wound_bonus = 10
	sharpness = SHARP_EDGED

	attack_verb_simple = "slash"
	attack_verb_continuous = "slashes"
	attack_sound = 'sound/weapons/bladeslice.ogg'

/datum/armor/basic_ranged_droid
	bullet = 50
	laser = 50
	energy = 30

/mob/living/basic/droid/basic/ranged
	name = "ranged droid"
	desc = "A basic ranged droid with light armor capable of outranging its targets."
	armor_type = /datum/armor/basic_ranged_droid
	speed = 0.8
