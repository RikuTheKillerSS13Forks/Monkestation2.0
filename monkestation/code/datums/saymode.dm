/datum/saymode
	/// Makes this saymode bypass say() modifications. All but the most basic message processing is on you now.
	var/bypass_modification = FALSE

/datum/saymode/bond
	mode = MODE_BOND
	key = MODE_KEY_BOND
	bypass_modification = TRUE

/datum/saymode/bond/handle_message(mob/living/user, message, datum/language/language)
	var/datum/antagonist/brother/bond = user.mind?.has_antag_datum(/datum/antagonist/brother)
	var/datum/team/brother_team/team = bond.get_team()
	if(QDELETED(team) || !(user.mind in team.members))
		return
	if(length(team.members) < 2)
		user.balloon_alert(user, "no brothers to communicate with!")
		return
	bond.communicate(message) // same thing the comms action does, just pass in the original message with no processing
