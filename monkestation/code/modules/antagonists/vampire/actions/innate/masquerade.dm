/datum/action/cooldown/vampire/masquerade
	name = "Masquerade"
	desc = "Hide your undead presence from the mortals."
	button_icon_state = "power_human"
	cooldown_time = 5 SECONDS
	is_toggleable = TRUE
	vampire_check_flags = VAMPIRE_AC_FRENZY

/datum/action/cooldown/vampire/masquerade/Grant(mob/granted_to)
	check_flags = AB_CHECK_CONSCIOUS // This is so that the signals register properly.
	. = ..()
	update_active_state()

/datum/action/cooldown/vampire/masquerade/Remove(mob/removed_from)
	is_active = FALSE // Avoids 'toggle_off()', as this can only ever be removed if the antag datum is removed. And the process of removing the antag datum enables masquerade.
	return ..()

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
	check_flags = is_active ? NONE : AB_CHECK_CONSCIOUS // You can turn it off while unconscious or even dead.
	build_all_button_icons(UPDATE_BUTTON_BACKGROUND)
