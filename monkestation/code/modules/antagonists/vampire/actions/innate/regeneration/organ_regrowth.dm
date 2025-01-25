/datum/action/cooldown/vampire/regeneration
	var/organ_regrowth_accumulation = 0

	var/list/organ_regrowth_order = list(
		ORGAN_SLOT_BRAIN,
		ORGAN_SLOT_HEART,
		ORGAN_SLOT_LUNGS,
		ORGAN_SLOT_APPENDIX,
		ORGAN_SLOT_EYES,
		ORGAN_SLOT_EARS,
		ORGAN_SLOT_TONGUE,
		ORGAN_SLOT_LIVER,
		ORGAN_SLOT_SPLEEN,
		ORGAN_SLOT_STOMACH,
		ORGAN_SLOT_BUTT,
		ORGAN_SLOT_BLADDER,
	)

/datum/action/cooldown/vampire/regeneration/proc/handle_organ_regrowth(regen_rate)
	var/target_organ = get_organ_to_regrow()

	if (!target_organ)
		organ_regrowth_accumulation = 0
		return 0

	organ_regrowth_accumulation += (1/10) * regen_rate
	if (organ_regrowth_accumulation < 1)
		qdel(target_organ)
		return

	organ_regrowth_accumulation %= 1

	target_organ.Insert(user, special = TRUE, drop_if_replaced = FALSE)
	target_organ.set_organ_damage(0)

	if (istype(target_organ, /obj/item/organ/internal/ears))
		var/obj/item/organ/internal/ears/ears = target_organ
		ears.adjustEarDamage(0, -INFINITY) // Clears temporary deafness.

	return 0.2

/datum/action/cooldown/vampire/regeneration/proc/get_organ_to_regrow()
	if (!user.dna?.species)
		return null

	for (var/slot in organ_regrowth_order)
		if (user.get_organ_slot(slot))
			continue

		var/organ_type = user.dna.species.get_mutant_organ_type_for_slot(slot)
		if (!organ_type)
			continue

		var/obj/item/organ/organ = new organ_type // I would use the wardrobe here if it wasn't for the fact this happens once every 2 seconds on repeat.
		if (!organ.get_availability(user.dna.species, user))
			qdel(organ)
			continue

		return organ

	for (var/organ_path in user.dna.species.mutant_organs)
		if (user.get_organ_by_type(organ_path))
			continue

		return new organ_path
