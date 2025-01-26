/datum/action/cooldown/vampire/regeneration/proc/handle_limb_regen(regen_rate)
	var/total_organ_damage = 0
	regen_rate *= -10 // Just a minor optimization.
	for (var/obj/item/organ/organ in user.organs)
		total_organ_damage += organ.damage
	for (var/obj/item/organ/organ in user.organs)
		if (organ.damage > 0)
			organ.apply_organ_damage(regen_rate * (organ.damage / total_organ_damage))
