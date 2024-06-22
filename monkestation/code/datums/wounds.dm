/datum/wound
	/// Extremely simple. If it reaches the value of "severity", the wound gets qdel'd.
	var/heal_progress

/// Heals the wound by the given amount. Works differently on bleeding wounds.
/datum/wound/proc/heal(amount)
	heal_progress += amount
	if(heal_progress >= severity)
		to_chat(victim, span_green("The [name] in your [limb.plaintext_zone] [limb.p_have()] healed up!"))
		qdel(src)
	return

/datum/wound/slash/flesh/heal(amount)
	adjust_blood_flow(min(0, minimum_flow - initial_flow) * amount)
	check_demote()

/datum/wound/slash/flesh/proc/check_demote()
	if(blood_flow < minimum_flow)
		demote()

/datum/wound/slash/flesh/proc/demote()
	if(demotes_to)
		replace_wound(new demotes_to)
	else
		to_chat(victim, span_green("The cut on your [limb.plaintext_zone] has [!limb.can_bleed() ? "healed up" : "stopped bleeding"]!"))
		qdel(src)
