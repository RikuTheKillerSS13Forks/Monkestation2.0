/datum/vampire_ability/strong_grip
	name = "Strong Grip"
	desc = "Being in combat mode makes your grabs a lot stronger. \
		Also makes neck feeding strangle your victim."
	stat_reqs = list(VAMPIRE_STAT_BRUTALITY = 40)

/datum/vampire_ability/strong_grip/on_grant_mob()
	RegisterSignal(user, COMSIG_LIVING_TRY_PULL, PROC_REF(on_grab))

/datum/vampire_ability/strong_grip/on_remove_mob()
	UnregisterSignal(user, COMSIG_LIVING_TRY_PULL)
	REMOVE_TRAIT(user, TRAIT_STRONG_GRABBER, REF(src))

/datum/vampire_ability/strong_grip/proc/on_grab()
	SIGNAL_HANDLER
	if (user.istate & ISTATE_HARM)
		ADD_TRAIT(user, TRAIT_STRONG_GRABBER, REF(src))
	else
		REMOVE_TRAIT(user, TRAIT_STRONG_GRABBER, REF(src))
