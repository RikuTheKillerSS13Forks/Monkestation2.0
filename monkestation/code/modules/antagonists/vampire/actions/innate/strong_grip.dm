/datum/action/cooldown/vampire/strong_grip
	name = "Strong Grip"
	desc = "Strengthen your grip far beyond that of any mortal."
	button_icon_state = "power_strength"
	toggleable = TRUE

/datum/action/cooldown/vampire/strong_grip/Grant(mob/granted_to)
	. = ..()
	toggle_on()

/datum/action/cooldown/vampire/strong_grip/on_toggle_on()
	ADD_TRAIT(owner, TRAIT_STRONG_GRABBER, REF(src))

/datum/action/cooldown/vampire/strong_grip/on_toggle_off()
	REMOVE_TRAIT(owner, TRAIT_STRONG_GRABBER, REF(src))
