/datum/antagonist/vampire
	/// At or below this amount of lifeforce, we enter a frenzy.
	/// A frenzy is not lethal, it's almost purely a buff.
	/// However, you can't enter masquerade during a frenzy.
	/// If you modify this, do it additively.
	var/frenzy_lifeforce_threshold = 0

/datum/antagonist/vampire/process(seconds_per_tick)
	if(QDELETED(user))
		return PROCESS_KILL

	handle_starlight()

	if (user.stat == DEAD)
		return

	if (current_lifeforce <= frenzy_lifeforce_threshold)
		if (!HAS_TRAIT(user, TRAIT_VAMPIRE_FRENZY))
			user.apply_status_effect(/datum/status_effect/vampire/frenzy)
	else if (HAS_TRAIT(user, TRAIT_VAMPIRE_FRENZY))
		user.remove_status_effect(/datum/status_effect/vampire/frenzy)

	if (current_lifeforce <= 0)
		if (!HAS_TRAIT(user, TRAIT_VAMPIRE_THIRST))
			user.apply_status_effect(/datum/status_effect/vampire/thirst)
	else if (HAS_TRAIT(user, TRAIT_VAMPIRE_THIRST))
		user.remove_status_effect(/datum/status_effect/vampire/thirst)

	adjust_lifeforce(lifeforce_per_second * DELTA_WORLD_TIME(SSprocessing)) // Even a 5% difference could make your lifeforce last several minutes more or less, so we use delta time.
