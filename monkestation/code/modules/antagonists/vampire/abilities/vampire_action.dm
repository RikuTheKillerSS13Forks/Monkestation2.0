/datum/action/cooldown/vampire
	name = "Please ahelp"
	desc = "If you see this ahelp IMMEDIATELY"

	/// How much lifeforce it costs to use this action.
	var/life_cost = 0

	var/mob/living/carbon/human/user
	var/datum/antagonist/vampire/vampire

/datum/action/cooldown/vampire/Grant(mob/granted_to)
	. = ..()

	if(!ishuman(granted_to))
		CRASH("Vampire action granted to non-human mob.")
	user = granted_to

	vampire = granted_to?.mind?.has_antag_datum(/datum/antagonist/vampire)
	if(!vampire)
		CRASH("Vampire action granted to non-vampire mob.")

/datum/action/cooldown/vampire/Remove(mob/removed_from)
	. = ..()

	if(user == removed_from)
		user = null

/datum/action/cooldown/vampire/IsAvailable(feedback)
	if(!..())
		return FALSE

	if(vampire.lifeforce < life_cost)
		if(feedback)
			owner.balloon_alert(owner, "needs [life_cost] lifeforce!")
		return FALSE

	return TRUE

/datum/action/cooldown/vampire/Destroy() // assumes that the action target is always the vampire antag datum, so this should be called if vampire is qdel'd
	vampire = null
	return ..()
