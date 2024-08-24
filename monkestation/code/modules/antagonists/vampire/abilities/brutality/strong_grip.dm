/datum/vampire_ability/strong_grip
	name = "Strong Grip"
	desc = "Strengthen your grip, making your grabs stronger.\n\
		Also causes neck feeding to strangle the victim."
	stat_reqs = list(VAMPIRE_STAT_BRUTALITY = 40)
	granted_action = /datum/action/cooldown/vampire/strong_grip
