/// Updates the current state of masquerade.
/datum/antagonist/vampire/proc/update_masquerade()
	if(masquerade_enabled)
		owner.current.remove_traits(visible_traits, VAMPIRE_TRAIT)
		owner.current.add_traits(masquerade_traits, VAMPIRE_TRAIT)
		set_lifeforce_change(LIFEFORCE_CHANGE_MASQUERADE, LIFEFORCE_DRAIN_BASE) // doubled drain rate
	else
		owner.current.add_traits(visible_traits, VAMPIRE_TRAIT)
		owner.current.remove_traits(masquerade_traits, VAMPIRE_TRAIT)
		clear_lifeforce_change(LIFEFORCE_CHANGE_MASQUERADE)

/// Enables or disables masquerade.
/datum/antagonist/vampire/proc/set_masquerade(enabled)
	if(enabled == masquerade_enabled)
		return
	masquerade_enabled = enabled
	update_masquerade()
