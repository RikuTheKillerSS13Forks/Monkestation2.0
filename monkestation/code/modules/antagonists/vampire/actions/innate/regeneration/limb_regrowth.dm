/datum/action/cooldown/vampire/regeneration
	var/limb_regrowth_accumulation = 0

	var/static/list/limb_regrowth_order = list(
		BODY_ZONE_HEAD,
		BODY_ZONE_CHEST, // This has to be here because of the whole excluded zones thing.
		BODY_ZONE_R_ARM,
		BODY_ZONE_R_LEG,
		BODY_ZONE_L_ARM,
		BODY_ZONE_L_LEG,
	)

/datum/action/cooldown/vampire/regeneration/proc/handle_limb_regrowth(regen_rate)
	if (length(user.bodyparts) >= 6)
		limb_regrowth_accumulation = 0
		return 0

	limb_regrowth_accumulation += (1/60) * regen_rate
	if (limb_regrowth_accumulation < 1)
		return

	limb_regrowth_accumulation %= 1

	var/target_zone = null
	for (var/zone in limb_regrowth_order)
		if (!user.get_bodypart(zone))
			target_zone = zone
			break

	user.regenerate_limb(target_zone)
	user.dna?.species?.regenerate_organs(user, excluded_zones = (limb_regrowth_order - target_zone))

	return VAMPIRE_LIMB_REGROWTH_COST
