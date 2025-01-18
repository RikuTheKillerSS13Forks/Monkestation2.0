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

/datum/action/cooldown/vampire/New(Target, original)
	. = ..()
	antag_datum = Target

/datum/action/cooldown/vampire/Grant(mob/granted_to)
	. = ..()
	user = granted_to

/datum/action/cooldown/vampire/Remove(mob/removed_from)
	. = ..()
	user = null
