/datum/action/cooldown/vampire/regeneration
	name = "Regeneration"
	desc = "Greatly increase your rate of recovery."
	button_icon_state = "power_recup"
	is_toggleable = TRUE
	is_active = TRUE

/datum/action/cooldown/vampire/regeneration/toggle_on()
	. = ..()
	RegisterSignal(user, COMSIG_LIVING_LIFE, PROC_REF(on_life))

/datum/action/cooldown/vampire/regeneration/toggle_off()
	. = ..()
	UnregisterSignal(user, COMSIG_LIVING_LIFE)

/datum/action/cooldown/vampire/regeneration/proc/on_life(datum/source, seconds_per_tick, times_fired)
	SIGNAL_HANDLER

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
