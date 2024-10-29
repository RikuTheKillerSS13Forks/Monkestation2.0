//NEEDS TO BE MADE FAST
/datum/species/zombie/infectious/runner
	name = "Runner Zombie"
	armor = 0
	hand_path = /obj/item/mutant_hand/zombie/low_infection/weak
	granted_action_types = list(
		/datum/action/cooldown/zombie/feast,
	)
	bodypart_overrides = list(
		BODY_ZONE_HEAD = /obj/item/bodypart/head/zombie,
		BODY_ZONE_CHEST = /obj/item/bodypart/chest/zombie,
		BODY_ZONE_L_ARM = /obj/item/bodypart/arm/left/zombie,
		BODY_ZONE_R_ARM = /obj/item/bodypart/arm/right/zombie,
		BODY_ZONE_L_LEG = /obj/item/bodypart/leg/left/zombie/runner,
		BODY_ZONE_R_LEG = /obj/item/bodypart/leg/right/zombie/runner,
	)

/obj/item/bodypart/leg/left/zombie/runner
	speed_modifier = -0.35

/obj/item/bodypart/leg/right/zombie/runner
	speed_modifier = -0.35
