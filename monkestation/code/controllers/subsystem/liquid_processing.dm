SUBSYSTEM_DEF(liquid_processing)
	name = "Liquid Processing"
	priority = FIRE_PRIORITY_LIQUID_PROCESSING
	flags = SS_BACKGROUND | SS_POST_FIRE_TIMING | SS_NO_INIT
	runlevels = RUNLEVEL_GAME | RUNLEVEL_POSTGAME
	wait = 2 SECONDS

	/// List of liquid groups to handle processing on, persists across resumed fire() calls.
	/// Kinda dangerous, as qdeleted liquid groups will not be deleted from this.
	var/list/process_cache = list()

	/// The last time fire() was called with 'resumed = FALSE'
	var/fire_start_time = 0

/datum/controller/subsystem/liquid_processing/fire(resumed)
	if (!length(GLOB.liquid_groups)) // Someone can implement can_fire later if they want to. This does the job just fine for now.
		return

	if (!resumed)
		process_cache = GLOB.liquid_groups.Copy()
		fire_start_time = world.time

	var/delta_time = (fire_start_time - last_fire) * 0.1 // This way delta time stays consistent across paused runs.
	var/evaporation_rate = LIQUID_BASE_EVAPORATION_RATE * delta_time

	while (length(process_cache))
		var/datum/liquid_group/group = process_cache[length(process_cache)]
		process_cache.len--
		if (QDELETED(group))
			continue

		// ACTUAL LIQUID PROCESSING START //

		group.reagents.remove_all(length(group.turfs) * evaporation_rate) // Evaporation rate is based on surface area, i.e. how many turfs are in the liquid group.

		if (group.handle_reactions_next_process)
			group.handle_reactions_next_process = FALSE
			group.reagents.flags &= ~NO_REACT
			group.reagents.handle_reactions()
			group.reagents.flags |= NO_REACT

		// ACTUAL LIQUID PROCESSING END //

		if (MC_TICK_CHECK)
			return
