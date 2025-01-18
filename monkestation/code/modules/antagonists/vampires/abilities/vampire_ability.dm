/datum/action/cooldown/vampire
	name = "Vampire Action"
	desc = "How the fuck did you get this?"

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
