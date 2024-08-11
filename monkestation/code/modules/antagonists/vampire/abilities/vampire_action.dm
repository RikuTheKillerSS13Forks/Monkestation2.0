/datum/action/cooldown/vampire
	name = "Please ahelp"
	desc = "If you see this ahelp IMMEDIATELY"
	var/life_cost = 0

/datum/action/cooldown/vampire/proc/can_use(mob/living/carbon/owner)
	var/datum/antagonist/vampire/vampire = owner.mind.has_antag_datum(/datum/antagonist/vampire)
	if(vampire.life_force < life_cost)
		owner.balloon_alert(owner, "needs [life_cost] lifeforce!")
		return FALSE

