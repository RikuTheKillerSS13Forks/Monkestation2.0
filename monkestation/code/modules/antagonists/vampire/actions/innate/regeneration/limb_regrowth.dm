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

	var/static/list/organ_regrow_zones_by_limb_zone = list(
		BODY_ZONE_HEAD = list(BODY_ZONE_HEAD, BODY_ZONE_PRECISE_EYES, BODY_ZONE_PRECISE_MOUTH),
		BODY_ZONE_CHEST = list(BODY_ZONE_CHEST, BODY_ZONE_PRECISE_GROIN),
		BODY_ZONE_R_ARM = list(BODY_ZONE_R_ARM, BODY_ZONE_PRECISE_R_HAND),
		BODY_ZONE_L_ARM = list(BODY_ZONE_L_ARM, BODY_ZONE_PRECISE_L_HAND),
		BODY_ZONE_R_LEG = list(BODY_ZONE_R_LEG, BODY_ZONE_PRECISE_R_FOOT),
		BODY_ZONE_L_LEG = list(BODY_ZONE_L_LEG, BODY_ZONE_PRECISE_L_FOOT),
	)

/datum/action/cooldown/vampire/regeneration/proc/handle_limb_regrowth(regen_rate)
	if (length(user.bodyparts) >= 6)
		limb_regrowth_accumulation = 0
		return

	limb_regrowth_accumulation += regen_rate / 60
	if (limb_regrowth_accumulation < 1)
		return

	limb_regrowth_accumulation %= 1

	var/target_zone = null
	for (var/zone in limb_regrowth_order)
		if (!user.get_bodypart(zone))
			target_zone = zone
			break

	user.regenerate_limb(target_zone)
	regrow_limb_organs(target_zone)

	return VAMPIRE_LIMB_REGROWTH_COST

/datum/action/cooldown/vampire/regeneration/proc/regrow_limb_organs(target_zone)
	if (!user.dna?.species)
		return

	var/list/target_zones = organ_regrow_zones_by_limb_zone[target_zone]
	if (!target_zones)
		return

	for (var/slot in organ_regrowth_order)
		if (user.get_organ_slot(slot))
			continue

		var/obj/item/organ/organ_type = user.dna.species.get_mutant_organ_type_for_slot(slot)
		if (!organ_type || !(initial(organ_type.zone) in target_zones))
			continue

		var/obj/item/organ/organ = new organ_type
		if (!organ.get_availability(user.dna.species, user))
			qdel(organ)
			continue

		organ.Insert(user, special = TRUE, drop_if_replaced = FALSE)

	for (var/obj/item/organ/organ_type in user.dna.species.mutant_organs)
		if (user.get_organ_by_type(organ_type))
			continue

		if (!(initial(organ_type.zone) in target_zones))
			continue

		var/obj/item/organ/organ = new organ_type
		organ.Insert(user, special = TRUE, drop_if_replaced = FALSE)
