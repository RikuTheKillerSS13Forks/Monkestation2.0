/datum/action/cooldown/vampire/regeneration/proc/handle_organ_regen(regen_rate)
	var/total_organ_damage = 0
	var/list/organs_to_heal = list()
	for (var/obj/item/organ/organ as anything in user.organs)
		if (organ.damage > 0 && (organ.status & ORGAN_ORGANIC))
			total_organ_damage += organ.damage
			organs_to_heal += organ

	regen_rate *= 10 // Just a minor optimization.
	for (var/obj/item/organ/organ as anything in organs_to_heal)
		var/organ_damage_to_heal = min(organ.damage, regen_rate * (organ.damage / total_organ_damage))
		organ.apply_organ_damage(-organ_damage_to_heal)
		. += organ_damage_to_heal * 0.02
