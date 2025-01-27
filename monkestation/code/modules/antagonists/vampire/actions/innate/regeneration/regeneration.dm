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
	reset_accumulation()
	RegisterSignal(user, COMSIG_LIVING_LIFE, PROC_REF(on_life))

/datum/action/cooldown/vampire/regeneration/toggle_off()
	. = ..()
	UnregisterSignal(user, COMSIG_LIVING_LIFE)

/datum/action/cooldown/vampire/regeneration/proc/on_life(datum/source, seconds_per_tick, times_fired)
	SIGNAL_HANDLER

	if (antag_datum.masquerade_enabled || antag_datum.current_lifeforce <= 0)
		reset_accumulation()
		return

	var/regen_rate = DELTA_WORLD_TIME(SSmobs)

	if (!regen_rate) // How would this happen? Coderkind will never know.
		return

	if (IS_THRALL(user))
		regen_rate *= 0.5

	var/total_cost = 0
	total_cost += handle_limb_regen(regen_rate)
	total_cost += handle_limb_regrowth(regen_rate)
	total_cost += handle_organ_regen(regen_rate)
	total_cost += handle_organ_regrowth(regen_rate)

	if (total_cost)
		antag_datum.adjust_lifeforce(-total_cost)

	// Vampirism is caused by a flesh bud in the brain, so you get brain trauma immunity.
	// It's also an excuse cause I don't want to bother factoring it into the calcs.
	user.cure_trauma_type(/datum/brain_trauma, TRAUMA_RESILIENCE_LOBOTOMY)

	// Beating their immortality with a fucking lighter is not very good lmao.
	// If you want to make a vampire campfire, use phlogiston or lava instead.
	user.adjust_fire_stacks(-1)

/datum/action/cooldown/vampire/regeneration/on_masquerade(datum/source, new_state, old_state)
	if (new_state)
		reset_accumulation()

/datum/action/cooldown/vampire/regeneration/on_lifeforce_changed(datum/source, new_amount, old_amount)
	if (new_amount <= 0)
		reset_accumulation()

/datum/action/cooldown/vampire/regeneration/proc/reset_accumulation()
	limb_regrowth_accumulation = 0
	organ_regrowth_accumulation = 0
