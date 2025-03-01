SUBSYSTEM_DEF(liquid_exposure)
	name = "Liquid Exposure"
	priority = FIRE_PRIORITY_LIQUID_EXPOSURE // Exposure can get very expensive and is rarely critical for gameplay.
	flags = SS_BACKGROUND | SS_KEEP_TIMING | SS_NO_INIT
	runlevels = RUNLEVEL_GAME | RUNLEVEL_POSTGAME
	wait = 1 SECOND

	/// List of liquid groups to handle exposure for, persists across resumed fire() calls.
	/// Kinda dangerous, as qdeleted liquid groups will not be deleted from this.
	var/list/exposure_group_cache = list()

	/// List of atoms to handle exposure for, persists across resumed fire() calls.
	/// Kinda dangerous, as qdeleted atoms will not be deleted from this.
	var/list/exposure_atom_cache = list()

/datum/controller/subsystem/liquid_exposure/fire(resumed)
	if (!length(GLOB.liquid_groups)) // Someone can implement can_fire later if they want to. This does the job just fine for now.
		return

	if (!resumed)
		exposure_group_cache = GLOB.liquid_groups.Copy()

	while (length(exposure_group_cache))
		var/datum/liquid_group/group = exposure_group_cache[length(exposure_group_cache)]

		if (QDELETED(group) || !length(group.turfs))
			exposure_atom_cache = list()
			exposure_group_cache.len--
			continue

		var/exposure_volume_threshold = LIQUID_EXPOSURE_VOLUME_THRESHOLD * length(group.turfs)

		if (group.reagents.total_volume < exposure_volume_threshold)
			exposure_atom_cache = list()
			exposure_group_cache.len--
			continue

		if (!length(exposure_atom_cache))
			exposure_atom_cache = group.turfs + group.exposed_atoms

		var/exposure_multiplier = LIQUID_EXPOSURE_MULTIPLIER / length(group.turfs)

		var/list/reagents = list() // Associative list of reagent to exposure volume.
		for (var/datum/reagent/reagent as anything in group.reagents.reagent_list)
			if (reagent.volume >= exposure_volume_threshold)
				reagents[reagent] = reagent.volume * exposure_multiplier

		if (!length(reagents))
			exposure_atom_cache = list()
			exposure_group_cache.len--
			continue

		while (length(exposure_atom_cache))
			var/atom/movable/atom = exposure_atom_cache[length(exposure_atom_cache)]
			exposure_atom_cache.len--

			if (!QDELETED(atom))
				atom.expose_reagents(reagents, source = group.reagents, methods = TOUCH)
			if (MC_TICK_CHECK)
				return

		exposure_group_cache.len--

		if (MC_TICK_CHECK)
			return
