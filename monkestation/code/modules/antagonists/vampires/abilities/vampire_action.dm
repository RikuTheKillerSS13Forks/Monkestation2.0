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

/datum/action/cooldown/vampire/New(Target, original)
	. = ..()
	antag_datum = Target

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

/datum/action/cooldown/vampire/Activate(atom/target)
	. = ..()
	if (is_toggleable)
		if (is_active)
			toggle_off()
		else
			toggle_on()

/datum/action/cooldown/vampire/proc/toggle_on()
	SHOULD_CALL_PARENT(TRUE)

	is_active = TRUE
	build_all_button_icons(UPDATE_BUTTON_STATUS)

/datum/action/cooldown/vampire/proc/toggle_off()
	SHOULD_CALL_PARENT(TRUE)

	is_active = FALSE
	build_all_button_icons(UPDATE_BUTTON_STATUS)

/datum/action/cooldown/vampire/is_action_active(atom/movable/screen/movable/action_button/current_button)
	return ..() && is_active
