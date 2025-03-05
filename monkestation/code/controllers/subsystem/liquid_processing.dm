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
		if (QDELETED(group) || !length(group.turfs))
			continue

		// ACTUAL LIQUID PROCESSING START //

		group.reagents.remove_all(length(group.turfs) * evaporation_rate) // Evaporation rate is based on surface area, i.e. how many turfs are in the liquid group.

		if (group.handle_reactions_next_process)
			group.handle_reactions_next_process = FALSE
			group.reagents.flags &= ~NO_REACT
			group.reagents.handle_reactions()
			group.reagents.flags |= NO_REACT

		group.update_reagent_state()

		var/sample_count = 1 + length(group.turfs) / 50 // For every 50 turfs in the group, take another air sample.
		var/needs_equalization = FALSE // Only do this expensive ass atmos fuckery if it's actually necessary.

		for (var/i in 1 to sample_count)
			var/turf/open/air_turf = pick(group.turfs)
			if (air_turf.air && abs(group.reagents.chem_temp - air_turf.air.temperature) >= 5) // Only if the difference between the liquid group temp and air temp is bigger than 5 kelvin do we care.
				needs_equalization = TRUE
				break

		if (needs_equalization)
			equalize_temperature(group)

		// ACTUAL LIQUID PROCESSING END //

		if (MC_TICK_CHECK)
			return

/datum/controller/subsystem/liquid_processing/proc/equalize_temperature(datum/liquid_group/group)
	var/total_energy = group.reagents.chem_temp * group.heat_capacity
	var/total_heat_capacity = group.heat_capacity

	for (var/turf/open/air_turf as anything in group.turfs)
		if (air_turf.air)
			total_energy += air_turf.air.temperature * air_turf.air.heat_capacity()
			total_heat_capacity += air_turf.air.heat_capacity()

	var/final_temperature = total_energy / total_heat_capacity // conservation of energy nerd shit

	group.reagents.chem_temp = final_temperature
	for (var/turf/open/air_turf as anything in group.turfs)
		air_turf.air?.temperature = final_temperature
