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

	var/regen_rate = seconds_per_tick

	if (IS_THRALL(user))
		regen_rate *= 0.5

	var/brute_healing = min(user.getBruteLoss(), regen_rate * 0.5)
	if (brute_healing)
		user.adjustBruteLoss(-brute_healing, updating_health = FALSE)

	var/burn_healing = min(user.getFireLoss(), regen_rate * 0.5)
	if (burn_healing)
		user.adjustFireLoss(-burn_healing, updating_health = FALSE)

	var/toxin_healing = min(user.getToxLoss(), regen_rate * 0.2)
	if (toxin_healing)
		user.adjustToxLoss(-toxin_healing, updating_health = FALSE)

	var/total_healing = brute_healing + burn_healing + toxin_healing
	if (total_healing)
		user.updatehealth()
		antag_datum.adjust_lifeforce(total_healing * -0.3)
