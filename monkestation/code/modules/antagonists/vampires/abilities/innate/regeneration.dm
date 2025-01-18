/datum/action/cooldown/vampire/regeneration
	name = "Regeneration"
	desc = "Greatly increase your rate of recovery."
	is_toggleable = TRUE
	is_active = TRUE

/datum/action/cooldown/vampire/regeneration/toggle_on()
	. = ..()
	START_PROCESSING(SSprocessing, src)

/datum/action/cooldown/vampire/regeneration/toggle_off()
	. = ..()
	STOP_PROCESSING(SSprocessing, src)

/datum/action/cooldown/vampire/regeneration/process(seconds_per_tick)
	if (antag_datum.masquerade_enabled)
		return

	var/regen_rate = seconds_per_tick

	if (IS_THRALL(user))
		regen_rate *= 0.5

	var/damage_change = 0

	damage_change += user.adjustBruteLoss(regen_rate * -0.5, updating_health = FALSE)
	damage_change += user.adjustFireLoss(regen_rate * -0.5, updating_health = FALSE)
	damage_change += user.adjustToxLoss(regen_rate * -0.2, updating_health = FALSE, forced = TRUE)

	if (damage_change)
		user.updatehealth()
		antag_datum.adjust_lifeforce(damage_change * 0.5) // Damage change is negative, so we just halve it to get the lifeforce cost.
