/datum/vampire_ability/efficient
	name = "Efficient"
	desc = "You do things a lot faster.<br> \
		Scales with Brutality."
	stat_reqs = list(VAMPIRE_STAT_BRUTALITY = 10)

/datum/vampire_ability/efficient/on_grant()
	RegisterSignal(owner, COMSIG_VAMPIRE_STAT_CHANGED, PROC_REF(on_stat_changed))

/datum/vampire_ability/efficient/on_grant_mob()
	update_modifier()

/datum/vampire_ability/efficient/on_remove()
	UnregisterSignal(owner, COMSIG_VAMPIRE_STAT_CHANGED)

/datum/vampire_ability/efficient/on_remove_mob()
	user.remove_actionspeed_modifier(/datum/actionspeed_modifier/vampire_brutality)

/datum/vampire_ability/efficient/proc/on_stat_changed(datum/source, stat)
	SIGNAL_HANDLER
	if(stat != VAMPIRE_STAT_BRUTALITY)
		return
	update_modifier()

/datum/vampire_ability/efficient/proc/update_modifier()
	user.add_or_update_variable_actionspeed_modifier(/datum/actionspeed_modifier/vampire_brutality, multiplicative_slowdown = owner.get_stat_modified(VAMPIRE_STAT_BRUTALITY) / VAMPIRE_SP_MAXIMUM)

/datum/actionspeed_modifier/vampire_brutality
	variable = TRUE
