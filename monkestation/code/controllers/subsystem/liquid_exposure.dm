SUBSYSTEM_DEF(liquid_exposure)
	name = "Liquid Exposure"
	priority = FIRE_PRIORITY_LIQUIDS
	flags = SS_KEEP_TIMING | SS_NO_INIT
	runlevels = RUNLEVEL_GAME | RUNLEVEL_POSTGAME
	wait = 1 SECOND

	/// List of liquid groups to call process_liquid() on, persists across resumed fire() calls.
	/// Kinda dangerous, as qdeleted liquid groups will not be deleted from this.
	var/list/exposure_cache = list()

/datum/controller/subsystem/liquid_exposure/fire(resumed)
	if (!length(GLOB.liquid_groups)) // Someone can implement can_fire later if they want to. This does the job just fine for now.
		return

	if (!resumed)
		exposure_cache = GLOB.liquid_groups.Copy()

	var/delta_time = DELTA_WORLD_TIME(src)
	while (length(exposure_cache))
		var/datum/liquid_group/group = exposure_cache[length(exposure_cache)]
		exposure_cache.len--
		if (QDELETED(group))
			return

		// ACTUAL LIQUID EXPOSURE START //



		// ACTUAL LIQUID EXPOSURE END //

		if (MC_TICK_CHECK)
			return
