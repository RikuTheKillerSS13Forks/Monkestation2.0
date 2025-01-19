/datum/antagonist/vampire
	var/masquerade_enabled = TRUE

/datum/antagonist/vampire/proc/set_masquerade(state, forced = FALSE)
	if (masquerade_enabled == state && !forced)
		return

	masquerade_enabled = state

	if (masquerade_enabled)
		user.add_traits(masquerade_traits, REF(src))
		user.remove_traits(visible_traits, REF(src))
		user.RemoveElement(/datum/element/cult_eyes, initial_delay = 0)
		user.RemoveElement(/datum/element/vampire_skin)
	else
		user.add_traits(visible_traits, REF(src))
		user.remove_traits(masquerade_traits, REF(src))
		user.AddElement(/datum/element/cult_eyes, initial_delay = 0)
		user.AddElement(/datum/element/vampire_skin)

	SEND_SIGNAL(src, COMSIG_VAMPIRE_MASQUERADE)
