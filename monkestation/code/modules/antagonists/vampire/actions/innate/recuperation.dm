/datum/action/cooldown/vampire/recuperation
	name = "Recuperation"
	desc = "Greatly increase your recovery rate from physical injuries. Drains lifeforce when healing and doesn't work in masquerade."
	button_icon_state = "power_recup"
	toggleable = TRUE
	works_in_masquerade = TRUE // on_life still prevents it from working, but you can toggle it if you want

/datum/action/cooldown/vampire/recuperation/New(Target)
	. = ..()
	RegisterSignal(vampire, COMSIG_VAMPIRE_STAT_CHANGED_MOD, PROC_REF(on_stat_changed))
	update_recovery_scaling(vampire.get_stat_modified(VAMPIRE_STAT_RECOVERY))

/datum/action/cooldown/vampire/recuperation/Destroy()
	. = ..()
	UnregisterSignal(vampire, COMSIG_VAMPIRE_STAT_CHANGED_MOD)

/datum/action/cooldown/vampire/recuperation/Grant(mob/granted_to)
	. = ..()
	toggle_on()

/datum/action/cooldown/vampire/recuperation/on_toggle_on()
	RegisterSignal(owner, COMSIG_LIVING_LIFE, PROC_REF(on_life))

/datum/action/cooldown/vampire/recuperation/on_toggle_off()
	UnregisterSignal(owner, COMSIG_LIVING_LIFE)

/datum/action/cooldown/vampire/recuperation/proc/on_life(datum/source, seconds_per_tick, times_fired)
	SIGNAL_HANDLER

	if(vampire.masquerade_enabled)
		return

	var/brute = user.getBruteLoss()
	var/burn = user.getFireLoss()

	var/total_damage = brute + burn
	if(total_damage <= 0)
		return

	var/brute_ratio = brute / total_damage
	var/burn_ratio = burn / total_damage

	var/regen_rate = vampire.regen_rate_modifier.get_value()

	user.adjustBruteLoss(-regen_rate * brute_ratio * seconds_per_tick)
	user.adjustFireLoss(-regen_rate * burn_ratio * seconds_per_tick)

	vampire.adjust_lifeforce(-min(regen_rate, total_damage) * 0.2) // 1 lifeforce per 5 damage healed

/datum/action/cooldown/vampire/recuperation/proc/on_stat_changed(datum/source, stat, old_amount, new_amount)
	SIGNAL_HANDLER
	if(stat != VAMPIRE_STAT_RECOVERY)
		return
	update_recovery_scaling(new_amount)

/datum/action/cooldown/vampire/recuperation/proc/update_recovery_scaling(recovery)
	vampire.regen_rate_modifier.set_multiplicative(VAMPIRE_STAT_RECOVERY, 1 + recovery / VAMPIRE_SP_MAXIMUM * 2) // 3x regen rate at max recovery
