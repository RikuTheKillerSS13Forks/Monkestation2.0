SUBSYSTEM_DEF(liquid_exposure)
	name = "Liquid Exposure"
	priority = FIRE_PRIORITY_LIQUID_EXPOSURE // Exposure can get very expensive and is rarely critical for gameplay. And most of its cost comes from atmos, so it gets to share a bracket with it.
	flags = SS_BACKGROUND | SS_KEEP_TIMING | SS_NO_INIT
	runlevels = RUNLEVEL_GAME | RUNLEVEL_POSTGAME
	wait = 1 SECOND

	/// List of liquid groups to handle exposure for, persists across resumed fire() calls.
	/// Kinda dangerous, as qdeleted liquid groups will not be deleted from this.
	var/list/exposure_group_cache = list()

	/// List of turfs to handle exposure for, persists across resumed fire() calls.
	/// Kinda dangerous, as qdeleted turfs will not be deleted from this.
	var/list/exposure_turf_cache = list()

/datum/controller/subsystem/liquid_exposure/fire(resumed)
	if (!length(GLOB.liquid_groups)) // Someone can implement can_fire later if they want to. This does the job just fine for now.
		return

	if (!resumed)
		exposure_group_cache = GLOB.liquid_groups.Copy()

	while (length(exposure_group_cache))
		var/datum/liquid_group/group = exposure_group_cache[length(exposure_group_cache)]

		if (QDELETED(group) || LIQUID_GET_VOLUME_PER_TURF(group) < LIQUID_EXPOSURE_VOLUME_THRESHOLD)
			exposure_turf_cache = list()
			exposure_group_cache.len--
			continue

		if (!length(exposure_turf_cache))
			exposure_turf_cache = group.turfs.Copy()

		var/list/turf_reagents = list()
		for (var/datum/reagent/reagent as anything in group.reagents.reagent_list)
			if (reagent.turf_exposure && reagent.volume >= LIQUID_EXPOSURE_VOLUME_THRESHOLD)
				turf_reagents += reagent

		if (!length(turf_reagents))
			exposure_turf_cache = list()
			exposure_group_cache.len--
			continue

		while (length(exposure_turf_cache))
			var/turf/turf = exposure_turf_cache[length(exposure_turf_cache)]
			exposure_turf_cache.len--
			for (var/datum/reagent/reagent as anything in turf_reagents)
				reagent.expose_turf(turf, LIQUID_EXPOSURE_TURF_VOLUME) // Turfs are always exposed to the same amount of liquid. (the surface area between the floor and the liquid doesn't change based on volume)
			if (MC_TICK_CHECK)
				return

		exposure_group_cache.len--
