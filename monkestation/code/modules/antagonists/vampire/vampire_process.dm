/datum/antagonist/vampire/process(seconds_per_tick)
	if(!user || user.stat == DEAD)
		return

	if (current_lifeforce <= 0 && !HAS_TRAIT(user, TRAIT_NODEATH))
		user.death(gibbed = FALSE, cause_of_death = "vampiric malnutrition") // Replace this with frenzy later.
		return

	adjust_lifeforce(lifeforce_per_second * DELTA_WORLD_TIME(SSprocessing)) // Even a 5% difference could make your lifeforce last several minutes more or less.

	// Vampires, as abominations borne from a flesh bud in the brain, are practically impervious to brain trauma.
	user.cure_trauma_type(/datum/brain_trauma, TRAUMA_RESILIENCE_LOBOTOMY)
	user.adjustOrganLoss(ORGAN_SLOT_BRAIN, -10 * seconds_per_tick)
