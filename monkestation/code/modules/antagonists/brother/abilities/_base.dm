/datum/action/cooldown/brother
	background_icon = 'monkestation/icons/mob/actions/backgrounds.dmi'
	background_icon_state = "bg_syndie"
	button_icon = 'monkestation/icons/mob/actions/actions_bb.dmi'
	check_flags = AB_CHECK_CONSCIOUS
	transparent_when_unavailable = TRUE

	var/datum/antagonist/brother/bond
	var/datum/team/brother_team/team

/datum/action/cooldown/brother/New(datum/antagonist/brother/target, original)
	if(!istype(target))
		CRASH("Attempted to create [type] without an associated antag datum!")
	bond = target
	team = target.get_team()
	return ..()

/datum/action/cooldown/brother/IsAvailable(feedback)
	if(QDELETED(bond) || bond.owner != owner.mind)
		return FALSE
	if(QDELETED(team) || !(owner.mind in team.members))
		return FALSE
	return ..()
