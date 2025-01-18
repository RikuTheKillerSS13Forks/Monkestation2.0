/datum/antagonist/vampire/process(seconds_per_tick)
	if (user && current_lifeforce <= 0 && user.stat != DEAD && !HAS_TRAIT(user, TRAIT_NODEATH))
		user.death(gibbed = FALSE, cause_of_death = "vampiric malnutrition")

	adjust_lifeforce(lifeforce_per_second * seconds_per_tick)

	// Vampires, as abominations borne from a flesh bud in the brain, are practically impervious to brain trauma.
	user.cure_trauma_type(/datum/brain_trauma, TRAUMA_RESILIENCE_LOBOTOMY)
	user.adjustOrganLoss(ORGAN_SLOT_BRAIN, -10 * seconds_per_tick)
