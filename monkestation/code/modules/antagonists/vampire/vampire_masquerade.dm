/// Updates the current state of masquerade.
/datum/antagonist/vampire/update_masquerade()
	if(masquerade_enabled)
		owner.current.add_traits(visible_traits, VAMPIRE_TRAIT)
		ADD_TRAIT(owner.current, TRAIT_MASQUERADE, VAMPIRE_TRAIT)
		set_lifeforce_change(LIFEFORCE_CHANGE_MASQUERADE, LIFEFORCE_DRAIN_BASE) // doubled drain rate
	else
		owner.current.remove_traits(visible_traits, VAMPIRE_TRAIT)
		REMOVE_TRAIT(owner.current, TRAIT_MASQUERADE, VAMPIRE_TRAIT)
		clear_lifeforce_change(LIFEFORCE_CHANGE_MASQUERADE)

/// Enables or disables masquerade.
/datum/antagonist/vampire/set_masquerade(enabled)
	if(enabled == masquerade_enabled)
		return
	masquerade_enabled = enabled
	update_masquerade()
