/atom/movable/screen/alert/status_effect/vampire/torpor
	name = "Torpor"
	desc = "You lay in your chosen place of immortal rest. A renewed will acts to restore your form."
	icon_state = "torpor"
	clickable_glow = TRUE

/atom/movable/screen/alert/status_effect/vampire/torpor/Click(location, control, params)
	. = ..()
	if (!.)
		qdel(attached_effect)

/datum/status_effect/vampire/torpor
	id = "vampire_torpor"
	tick_interval = STATUS_EFFECT_NO_TICK
	alert_type = /atom/movable/screen/alert/status_effect/vampire/torpor

/datum/status_effect/vampire/torpor/on_apply()
	. = ..()
	if (!.)
		ADD_TRAIT(user, TRAIT_KNOCKEDOUT, TRAIT_STATUS_EFFECT(id))

/datum/status_effect/vampire/torpor/on_remove()
	REMOVE_TRAITS_IN(user, TRAIT_STATUS_EFFECT(id))
	user.Sleeping(5 SECONDS)
