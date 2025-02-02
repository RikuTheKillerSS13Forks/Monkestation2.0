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
	RegisterSignal(user, COMSIG_MOVABLE_MOVED, PROC_REF(on_moved))
	check_can_heal()

/datum/action/cooldown/vampire/regeneration/toggle_off()
	. = ..()
	UnregisterSignal(user, list(COMSIG_LIVING_LIFE, COMSIG_MOVABLE_MOVED))
	end_torpor()

/datum/action/cooldown/vampire/regeneration/proc/on_life(datum/source, seconds_per_tick, times_fired)
	SIGNAL_HANDLER

	if (!check_can_heal(can_start_torpor = FALSE)) // If this could start torpor you'd be stunlocked.
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
	check_can_heal()

/datum/action/cooldown/vampire/regeneration/on_lifeforce_changed(datum/source, new_amount, old_amount)
	check_can_heal(can_start_torpor = FALSE) // The argument is a "just in case" thing in case you keep bouncing between 0 and some other value.

/datum/action/cooldown/vampire/regeneration/proc/on_moved()
	SIGNAL_HANDLER
	check_can_heal()

/datum/action/cooldown/vampire/regeneration/proc/check_can_heal(can_start_torpor = TRUE)
	if (!user) // I had 'end_torpor()' get called without an user, probably has to do with removing the action? Anyway, this should fix that.
		return
	var/can_heal = can_heal()
	if (!can_heal)
		reset()
		end_torpor()
	else if (can_start_torpor && istype(user.loc, /obj/structure/closet/crate/coffin))
		start_torpor()
	return can_heal

/datum/action/cooldown/vampire/regeneration/proc/can_heal()
	return !antag_datum.masquerade_enabled && antag_datum.current_lifeforce > 0

/datum/action/cooldown/vampire/regeneration/proc/reset()
	limb_regrowth_accumulation = 0
	organ_regrowth_accumulation = 0
	wound_regen_accumulation = 0
	is_reviving = FALSE

/datum/action/cooldown/vampire/regeneration/proc/start_torpor()
	user.apply_status_effect(/datum/status_effect/vampire/torpor)

/datum/action/cooldown/vampire/regeneration/proc/end_torpor()
	user.remove_status_effect(/datum/status_effect/vampire/torpor)
