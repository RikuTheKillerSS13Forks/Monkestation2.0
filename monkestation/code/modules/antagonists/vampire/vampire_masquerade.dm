/datum/antagonist/vampire
	var/masquerade_enabled = TRUE

/datum/antagonist/vampire/proc/set_masquerade(state, forced = FALSE)
	if (masquerade_enabled == state && !forced)
		return

	masquerade_enabled = state

	if (masquerade_enabled)
		user.add_traits(masquerade_traits, REF(src))
		user.remove_traits(visible_traits, REF(src))
	else
		user.add_traits(visible_traits, REF(src))
		user.remove_traits(masquerade_traits, REF(src))

	SEND_SIGNAL(src, COMSIG_VAMPIRE_MASQUERADE)
