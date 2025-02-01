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
	reset()
	RegisterSignal(user, COMSIG_LIVING_LIFE, PROC_REF(on_life))
	RegisterSignal(user, COMSIG_MOVABLE_MOVED, PROC_REF(check_torpor))
	check_torpor()

/datum/action/cooldown/vampire/regeneration/toggle_off()
	. = ..()
	UnregisterSignal(user, list(COMSIG_LIVING_LIFE, COMSIG_MOVABLE_MOVED))
	end_torpor()

/datum/action/cooldown/vampire/regeneration/proc/on_life(datum/source, seconds_per_tick, times_fired)
	SIGNAL_HANDLER

	if (antag_datum.masquerade_enabled || antag_datum.current_lifeforce <= 0)
		reset()
		return

	var/regen_rate = DELTA_WORLD_TIME(SSmobs)

	if (!regen_rate) // How would this happen? Coderkind will never know.
		return

	if (IS_THRALL(user))
		regen_rate *= 0.5

	var/is_in_torpor = user.has_status_effect(/datum/status_effect/vampire/torpor)
	if (is_in_torpor)
		regen_rate *= 2

	var/total_cost = 0
	total_cost += handle_limb_regen(regen_rate)
	total_cost += handle_limb_regrowth(regen_rate)
	total_cost += handle_organ_regen(regen_rate)
	total_cost += handle_organ_regrowth(regen_rate)
	total_cost += handle_wound_regen(regen_rate)

	if (is_in_torpor)
		total_cost *= 0.5

	if (total_cost)
		antag_datum.adjust_lifeforce(-total_cost)

	// Vampirism is caused by a flesh bud in the brain, so you get brain trauma immunity.
	// It's also an excuse cause I don't want to bother factoring it into the calcs.
	user.cure_trauma_type(/datum/brain_trauma, TRAUMA_RESILIENCE_LOBOTOMY)

	// Beating their immortality with a fucking lighter is not very good lmao.
	// If you want to make a vampire campfire, use phlogiston or lava instead.
	user.adjust_fire_stacks(-1)

	handle_revival()

/datum/action/cooldown/vampire/regeneration/on_masquerade(datum/source, new_state, old_state)
	if (new_state)
		reset()

/datum/action/cooldown/vampire/regeneration/on_lifeforce_changed(datum/source, new_amount, old_amount)
	if (new_amount <= 0)
		reset()

/datum/action/cooldown/vampire/regeneration/proc/reset()
	limb_regrowth_accumulation = 0
	organ_regrowth_accumulation = 0
	wound_regen_accumulation = 0
	is_reviving = FALSE

/datum/action/cooldown/vampire/regeneration/proc/check_torpor()
	SIGNAL_HANDLER
	if (istype(user.loc, /obj/structure/closet/crate/coffin))
		start_torpor()
	else
		end_torpor()

/datum/action/cooldown/vampire/regeneration/proc/start_torpor()
	user.apply_status_effect(/datum/status_effect/vampire/torpor)

/datum/action/cooldown/vampire/regeneration/proc/end_torpor()
	user.remove_status_effect(/datum/status_effect/vampire/torpor)
