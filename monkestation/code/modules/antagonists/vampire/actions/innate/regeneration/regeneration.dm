/datum/action/cooldown/vampire/regeneration
	name = "Regeneration"
	desc = "Greatly increase your rate of recovery."
	button_icon_state = "power_recup"

	is_toggleable = TRUE
	is_active = TRUE

	check_flags = NONE
	vampire_check_flags = NONE

/datum/action/cooldown/vampire/regeneration/toggle_on()
	. = ..()
	RegisterSignal(user, COMSIG_LIVING_LIFE, PROC_REF(on_life))

/datum/action/cooldown/vampire/regeneration/toggle_off()
	. = ..()
	UnregisterSignal(user, COMSIG_LIVING_LIFE)

/datum/action/cooldown/vampire/regeneration/proc/on_life(datum/source, seconds_per_tick, times_fired)
	SIGNAL_HANDLER

	if (antag_datum.masquerade_enabled || antag_datum.current_lifeforce <= 0)
		return

	var/regen_rate = DELTA_WORLD_TIME(SSmobs)

	if (IS_THRALL(user))
		regen_rate *= 0.5

	var/brute_healing = min(user.getBruteLoss(), regen_rate * 2)
	if (brute_healing)
		user.adjustBruteLoss(-brute_healing, updating_health = FALSE)

	var/burn_healing = min(user.getFireLoss(), regen_rate * 2)
	if (burn_healing)
		user.adjustFireLoss(-burn_healing, updating_health = FALSE)

	var/toxin_healing = min(user.getToxLoss(), regen_rate)
	if (toxin_healing)
		user.adjustToxLoss(-toxin_healing, updating_health = FALSE, forced = TRUE)

	var/total_cost = (brute_healing + burn_healing + toxin_healing) * 0.02

	if (total_cost)
		user.updatehealth()

	total_cost += handle_limb_regrowth()
	total_cost += handle_organ_regrowth()

	if (total_cost)
		antag_datum.adjust_lifeforce(-total_cost)
