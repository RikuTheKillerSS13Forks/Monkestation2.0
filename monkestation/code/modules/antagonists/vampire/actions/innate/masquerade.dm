/datum/action/cooldown/vampire/masquerade
	name = "Masquerade"
	desc = "Hide your undead presence from the mortals."
	button_icon_state = "power_human"
	cooldown_time = 5 SECONDS
	is_toggleable = TRUE
	vampire_check_flags = VAMPIRE_AC_FRENZY

/datum/action/cooldown/vampire/masquerade/New(Target, original)
	. = ..()
	update_active_state()

/datum/action/cooldown/vampire/masquerade/Destroy()
	UnregisterSignal(antag_datum, COMSIG_VAMPIRE_MASQUERADE)
	return ..()

/datum/action/cooldown/vampire/masquerade/toggle_on()
	antag_datum.set_masquerade(TRUE)

/datum/action/cooldown/vampire/masquerade/toggle_off()
	antag_datum.set_masquerade(FALSE)

/datum/action/cooldown/vampire/masquerade/on_masquerade(datum/source, new_state, old_state)
	update_active_state()

/datum/action/cooldown/vampire/masquerade/proc/update_active_state()
	SIGNAL_HANDLER
	is_active = antag_datum.masquerade_enabled
	build_all_button_icons(UPDATE_BUTTON_BACKGROUND)
	check_flags = is_active ? NONE : AB_CHECK_CONSCIOUS // You can turn it off while unconscious or even dead.
