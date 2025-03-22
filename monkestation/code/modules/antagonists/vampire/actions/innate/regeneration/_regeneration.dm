/datum/action/cooldown/vampire/regeneration
	name = "Regeneration"
	desc = "Greatly increase your rate of recovery."
	button_icon_state = "power_recup"

	is_toggleable = TRUE
	is_active = TRUE

	check_flags = NONE
	vampire_check_flags = NONE // Regeneration is a special boy that doesn't toggle off even when you can't use it. (because I'd tear my hair out if I had to keep toggling it every time)

/datum/action/cooldown/vampire/regeneration/toggle_on()
	. = ..()
	RegisterSignal(user, COMSIG_LIVING_LIFE, PROC_REF(on_life))
	RegisterSignal(user, COMSIG_MOVABLE_MOVED, PROC_REF(on_moved))

	if (can_heal())
		start_torpor()

/datum/action/cooldown/vampire/regeneration/toggle_off()
	. = ..()
	UnregisterSignal(user, list(COMSIG_LIVING_LIFE, COMSIG_MOVABLE_MOVED))

	if (user) // I've had end_torpor() get called without an user before, this should fix that? Probably has to do with removing the action. Maybe look into this sometime.
		end_torpor()

	reset() // Don't carry regen accumulations across activations.

/datum/action/cooldown/vampire/regeneration/proc/on_life(datum/source, seconds_per_tick, times_fired)
	SIGNAL_HANDLER

	if (!can_heal())
		end_torpor()
		reset()
		return

	var/regen_rate = DELTA_WORLD_TIME(SSmobs)

	if (!regen_rate) // How would this happen? Coderkind will never know.
		return

	var/is_in_torpor = user.has_status_effect(/datum/status_effect/vampire/torpor)
	if (is_in_torpor)
		regen_rate *= 2

	if (IS_THRALL(user))
		regen_rate *= 0.5

	if (HAS_TRAIT(user, TRAIT_VAMPIRE_STARLIT))
		regen_rate *= 0.7 // Don't completely stop regen, otherwise vamps can be round removed without using stakes by just chucking them in space.

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

/datum/action/cooldown/vampire/regeneration/proc/can_heal()
	return !antag_datum.masquerade_enabled && antag_datum.current_lifeforce > 0

/datum/action/cooldown/vampire/regeneration/proc/reset()
	limb_regrowth_accumulation = 0
	organ_regrowth_accumulation = 0
	wound_regen_accumulation = 0
	is_reviving = FALSE

/datum/action/cooldown/vampire/regeneration/proc/start_torpor()
	user.apply_status_effect(/datum/status_effect/vampire/torpor) // If you ever add a trait for torpor, put a neat if check here for it and in end_torpor() as well.

/datum/action/cooldown/vampire/regeneration/proc/end_torpor()
	user.remove_status_effect(/datum/status_effect/vampire/torpor)

/datum/action/cooldown/vampire/regeneration/on_masquerade(datum/source, new_state, old_state)
	if (new_state)
		end_torpor()
		reset()
	else if (can_heal() && istype(user.loc, /obj/structure/closet/crate/coffin))
		start_torpor()

/datum/action/cooldown/vampire/regeneration/on_lifeforce_changed(datum/source, new_amount, old_amount)
	if (new_amount <= 0)
		end_torpor()
		reset()

/datum/action/cooldown/vampire/regeneration/proc/on_moved(datum/source, atom/old_loc, dir, forced, list/old_locs)
	SIGNAL_HANDLER

	if (can_heal() && istype(user.loc, /obj/structure/closet/crate/coffin))
		start_torpor()
	else
		end_torpor()
