/datum/vampire_ability/mend
	name = "Mend"
	desc = "Undoes major wounds on your body from dislocations to broken bones. \
		The process is loud and clearly visible. \
		Cost scales with wound count."
	stat_reqs = list(VAMPIRE_STAT_RECOVERY = 30)
	granted_action = /datum/action/cooldown/vampire/mend
