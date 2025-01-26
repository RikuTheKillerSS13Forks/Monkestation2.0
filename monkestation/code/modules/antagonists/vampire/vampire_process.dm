/datum/antagonist/vampire/process(seconds_per_tick)
	if(QDELETED(user) || user.stat == DEAD)
		return

	if (current_lifeforce <= 0 && !HAS_TRAIT(user, TRAIT_NODEATH))
		user.death(gibbed = FALSE, cause_of_death = "vampiric malnutrition") // Replace this with frenzy later.
		return

	adjust_lifeforce(lifeforce_per_second * DELTA_WORLD_TIME(SSprocessing)) // Even a 5% difference could make your lifeforce last several minutes more or less.
