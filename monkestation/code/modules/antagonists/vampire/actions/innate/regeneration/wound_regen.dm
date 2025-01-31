/datum/action/cooldown/vampire/regeneration
	var/wound_regen_accumulation = 0

/datum/action/cooldown/vampire/regeneration/proc/handle_wound_regen(regen_rate)
	if (!user.all_wounds)
		wound_regen_accumulation = 0
		return

	wound_regen_accumulation += regen_rate / 6
	if (wound_regen_accumulation < 1)
		return

	wound_regen_accumulation %= 1

	var/datum/wound/target_wound = pick(user.all_wounds)

	var/heal_or_heals = target_wound.a_or_from == "a" ? "heals" : "heal" // This is stupid.
	user.visible_message(
		message = span_danger("The [lowertext(target_wound.name)] on [user]'s [target_wound.limb.plaintext_zone] [heal_or_heals] up with unnatural haste!"),
		self_message = span_green("The [lowertext(target_wound.name)] on your [target_wound.limb.plaintext_zone] [heal_or_heals] up!"),
	)

	playsound(user, 'sound/effects/wounds/sizzle2.ogg', vol = 20, vary = TRUE)

	qdel(target_wound)

	return 0.05
