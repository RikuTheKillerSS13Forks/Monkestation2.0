/datum/antagonist/vampire
	var/masquerade_enabled = TRUE

/datum/antagonist/vampire/proc/enable_masquerade(forced = FALSE)
	if (masquerade_enabled && !forced)
		return

	masquerade_enabled = TRUE
	user.add_traits(masquerade_traits, REF(src))
	user.remove_traits(visible_traits, REF(src))

/datum/antagonist/vampire/proc/disable_masquerade(forced = FALSE)
	if (!masquerade_enabled && !forced)
		return

	masquerade_enabled = FALSE
	user.add_traits(visible_traits, REF(src))
	user.remove_traits(masquerade_traits, REF(src))
