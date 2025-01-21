/datum/action/cooldown/vampire
	name = "Vampire Action"
	desc = "How the fuck did you get this?"
	cooldown_time = 0.5 SECONDS
	check_flags = AB_CHECK_CONSCIOUS

	button_icon = 'monkestation/icons/vampires/vampire_actions.dmi'
	background_icon = 'monkestation/icons/vampires/vampire_actions.dmi'
	background_icon_state = "vamp_power_off"
	base_background_icon_state = "vamp_power_off"
	active_background_icon_state = "vamp_power_on"
	buttontooltipstyle = "cult"
	transparent_when_unavailable = TRUE

	var/mob/living/carbon/human/user
	var/datum/antagonist/vampire/antag_datum

	var/is_toggleable = FALSE
	var/is_active = FALSE

	/// These are defined in 'code/_DEFINES/monkestation~/vampires.dm'
	var/vampire_check_flags = VAMPIRE_AC_LIFEFORCE | VAMPIRE_AC_FRENZY | VAMPIRE_AC_MASQUERADE

	/// The amount of lifeforce this costs to activate.
	var/lifeforce_cost = 0

/datum/action/cooldown/vampire/New(Target, original)
	. = ..()
	antag_datum = Target
	RegisterSignal(antag_datum, COMSIG_VAMPIRE_MASQUERADE, PROC_REF(on_masquerade))
	RegisterSignal(antag_datum, COMSIG_VAMPIRE_LIFEFORCE_CHANGED, PROC_REF(on_lifeforce_changed))

/datum/action/cooldown/vampire/Destroy()
	UnregisterSignal(antag_datum, list(COMSIG_VAMPIRE_MASQUERADE, COMSIG_VAMPIRE_LIFEFORCE_CHANGED))
	antag_datum = null
	return ..()

/datum/action/cooldown/vampire/Grant(mob/granted_to)
	. = ..()
	user = granted_to
	if (is_active)
		toggle_on()

/datum/action/cooldown/vampire/Remove(mob/removed_from)
	if (is_active)
		toggle_off()
	. = ..()
	user = null

/datum/action/cooldown/vampire/IsAvailable(feedback)
	. = ..()
	if (!.)
		return
	if (is_toggleable && is_active)
		return TRUE
	if ((vampire_check_flags & VAMPIRE_AC_LIFEFORCE) && lifeforce_cost > antag_datum.current_lifeforce)
		if (feedback)
			user.balloon_alert(user, "not enough lifeforce!")
		return FALSE
	if ((vampire_check_flags & VAMPIRE_AC_MASQUERADE) && antag_datum.masquerade_enabled)
		if (feedback)
			user.balloon_alert(user, "not while in masquerade!")
		return FALSE
	if ((vampire_check_flags & VAMPIRE_AC_FRENZY) && antag_datum.current_lifeforce <= 0)
		if (feedback)
			user.balloon_alert(user, "not while in a frenzy!")
		return FALSE

/datum/action/cooldown/vampire/Activate(atom/target)
	. = ..()
	if (lifeforce_cost && !(is_toggleable && is_active)) // Toggling off abilities doesn't cost any lifeforce.
		antag_datum.adjust_lifeforce(-lifeforce_cost)
	if (is_toggleable)
		if (is_active)
			toggle_off()
		else
			toggle_on()

/datum/action/cooldown/vampire/proc/toggle_on()
	is_active = TRUE
	build_all_button_icons(UPDATE_BUTTON_BACKGROUND)

/datum/action/cooldown/vampire/proc/toggle_off()
	is_active = FALSE
	build_all_button_icons(UPDATE_BUTTON_BACKGROUND)

/datum/action/cooldown/vampire/is_action_active(atom/movable/screen/movable/action_button/current_button)
	return ..() || is_active

/datum/action/cooldown/vampire/proc/on_masquerade()
	SIGNAL_HANDLER
	if ((vampire_check_flags & VAMPIRE_AC_MASQUERADE) && is_toggleable && is_active)
		toggle_off()
	if ((vampire_check_flags & VAMPIRE_AC_MASQUERADE))
		build_all_button_icons(UPDATE_BUTTON_STATUS)

/datum/action/cooldown/vampire/proc/on_lifeforce_changed(datum/source, new_amount, old_amount)
	SIGNAL_HANDLER
	if ((vampire_check_flags & VAMPIRE_AC_FRENZY) && is_toggleable && is_active)
		toggle_off()
	if ((vampire_check_flags & (VAMPIRE_AC_LIFEFORCE | VAMPIRE_AC_FRENZY)))
		build_all_button_icons(UPDATE_BUTTON_STATUS)
