// This subsystem is meant to handle anything related or tied to liquids spreading.
// Keep in mind that means practically anything that needs to keep up pace with that. (like liquid states and reagent colors)

SUBSYSTEM_DEF(liquid_spread)
	name = "Liquid Spread"
	priority = FIRE_PRIORITY_LIQUID_SPREAD
	flags = SS_KEEP_TIMING | SS_NO_INIT
	runlevels = RUNLEVEL_GAME | RUNLEVEL_POSTGAME
	wait = 0.2 SECONDS

	/// List of liquid groups for process_spread() to process, persists across resumed fire() calls.
	/// Required to keep liquid group spreading from going out of sync between groups.
	/// Kinda dangerous, as qdeleted liquid groups will not be deleted from this.
	var/list/spread_cache = list()

	/// Associative list of liquid groups to combine, persists across resumed fire() calls.
	/// Required to allow recessive liquid groups to process_spread() before merging.
	/// Kinda dangerous, as qdeleted liquid groups will not be deleted from this.
	/// The format is "combine_cache[recessive_group] = dominant_group"
	var/list/combine_cache = list()

	/// Associative list of liquid groups to split, persists across resumed fire() calls.
	/// Required to allow literally anything ever to stay coherent at all, operation order is CRITICAL HERE.
	/// Kinda dangerous, as qdeleted liquid groups will not be deleted from this.
	/// The format is "split_cache[splitting_group] = TRUE"
	var/list/split_cache = list()

/datum/controller/subsystem/liquid_spread/fire(resumed = FALSE)
	if (!length(GLOB.liquid_groups)) // Someone can implement can_fire later if they want to. This does the job just fine for now.
		return

	if (!resumed)
		spread_cache = GLOB.liquid_groups.Copy()
		combine_cache = GLOB.liquid_combine_queue.Copy()
		split_cache = GLOB.liquid_split_queue.Copy()

		GLOB.liquid_combine_queue = list()
		GLOB.liquid_split_queue = list()

	if (length(spread_cache))
		process_spread(wait * 0.1)

	while (length(combine_cache))
		var/turf/turf_to_check = combine_cache[length(combine_cache)]
		combine_cache -= turf_to_check
		if (QDELETED(turf_to_check) || !turf_to_check.liquid_group)
			continue

		for (var/direction in GLOB.cardinals)
			var/turf/adjacent_turf = get_step(turf_to_check, direction)
			if (adjacent_turf.liquid_group && adjacent_turf.liquid_group != turf_to_check.liquid_group && TURFS_CAN_SHARE(turf_to_check, adjacent_turf))
				combine_liquid_groups(turf_to_check.liquid_group, adjacent_turf.liquid_group)

		if (MC_TICK_CHECK)
			return

	while (length(split_cache))
		var/datum/liquid_group/splitting_group = split_cache[length(split_cache)]
		split_cache.len--
		if (!QDELETED(splitting_group))
			split_liquid_group(splitting_group)
		if (MC_TICK_CHECK)
			return

/datum/controller/subsystem/liquid_spread/proc/process_spread(seconds_per_tick)
	while (length(spread_cache))
		var/datum/liquid_group/group = spread_cache[length(spread_cache)]
		spread_cache.len--
		if (QDELETED(group))
			continue

		// ACTUAL SPREAD PROCESSING START //

		if (!length(group.turfs) || group.reagents.total_volume <= 0) // Basically group.check_should_exist() but inlined.
			qdel(group)
			continue

		var/did_something = FALSE // Used for optimizing out check_should_exist() after spread processing if we did nothing

		if (LIQUID_GET_VOLUME_PER_TURF(group) >= LIQUID_SPREAD_VOLUME_THRESHOLD)
			if (length(group.edge_turf_spread_directions)) // Micro-optimization. (spread proc overhead)
				group.spread(seconds_per_tick)
				did_something = TRUE
		else if (group.reagents.total_volume <= LIQUID_SPREAD_VOLUME_THRESHOLD * (length(group.turfs) - group.get_evaporation_turf_count()))
			group.evaporate_edges() // Make sure we don't have enough liquid volume to spread after this. And use multiplication to avoid a division-by-zero at 1 turf.
			did_something = TRUE

		if (!did_something || group.check_should_exist()) // We want to update state even if we did fuckall. SSliquid_processing is too slow for this. (and instant costs seven kidneys)
			if (group.have_reagents_updated || LIQUID_TEMPERATURE_NEEDS_REAGENT_UPDATE(group)) // Micro-optimization. (update_reagent_state proc overhead)
				group.update_reagent_state()
			else if (group.last_liquid_state_turf_count != length(group.turfs)) // Micro-optimization. (update_liquid_state proc overhead)
				group.update_liquid_state()

		// ACTUAL SPREAD PROCESSING END //

		if (MC_TICK_CHECK)
			return

/// As the name implies, combines two separate liquid groups into one.
/// More importantly, don't call this outside of SSliquid_spread. I will find you.
/datum/controller/subsystem/liquid_spread/proc/combine_liquid_groups(datum/liquid_group/dominant_group, datum/liquid_group/recessive_group)
	dominant_group.turfs += recessive_group.turfs
	dominant_group.edge_turfs += recessive_group.edge_turfs
	dominant_group.edge_turf_spread_directions += recessive_group.edge_turf_spread_directions
	dominant_group.next_spread_count += recessive_group.next_spread_count
	dominant_group.exposed_atoms += recessive_group.exposed_atoms
	dominant_group.heat_capacity += recessive_group.heat_capacity

	LIQUID_UPDATE_MAXIMUM_VOLUME(dominant_group)
	recessive_group.copy_reagents_to(dominant_group)

	for (var/turf/recessive_group_turf as anything in recessive_group.turfs)
		recessive_group_turf.liquid_group = dominant_group
		recessive_group_turf.liquid_effect.liquid_group = dominant_group

	// If you don't check whether they're equal, shit will just flash white for some reason.
	// And I don't want to do a string check 2 quadrillion times, so this is what you get.
	if (recessive_group.liquid_color != dominant_group.liquid_color)
		for (var/turf/recessive_group_turf as anything in recessive_group.turfs)
			recessive_group_turf.liquid_effect.color = dominant_group.liquid_color

	for (var/atom/recessive_group_atom as anything in recessive_group.exposed_atoms)
		recessive_group.UnregisterSignal(recessive_group_atom, COMSIG_QDELETING)
		dominant_group.RegisterSignal(recessive_group_atom, COMSIG_QDELETING, TYPE_PROC_REF(/datum/liquid_group, remove_atom))

	recessive_group.turfs = list() // Clear it early so that recessive_group.Destroy() doesn't delete liquid effects.
	recessive_group.exposed_atoms = list() // Ditto, but for liquid immersion effects.
	qdel(recessive_group)

/// Does a full DFT (Depth-First Traversal) for a liquid group and splits it into several if needed.
/// A full DFT is incredibly expensive, costing about 100ms (estimate from my 250ms or so) on live for all of Box station in one group. (all doors open)
/// In reality they only take about 10ms on live even in the worst case, but this remains extremely hot anyway.
/// I am literally incapable of optimizing this further even after hours of profiling and testing shit.
/datum/controller/subsystem/liquid_spread/proc/split_liquid_group(datum/liquid_group/splitting_group)
	var/list/splitting_group_turf_cache = splitting_group.turfs.Copy() // Associative list of turfs we have left to find. Has to be a copy in case we abort the split. (turf = TRUE)
	var/list/new_group_turf_lists = list() // A list containing associative lists of turfs for the new groups after the split. (turf = TRUE)

	while (length(splitting_group_turf_cache))
		var/turf/starting_turf = pick(splitting_group_turf_cache)
		splitting_group_turf_cache -= starting_turf

		var/list/turf_stack = list(starting_turf) // List of turfs to propagate from on the next DFT iteration.
		var/list/visited_turfs = list() // Associative list of turfs that we have visited. (turf = TRUE)
		visited_turfs[starting_turf] = TRUE // Putting list(starting_turf = TRUE) as the initial value of visited_turfs just makes ("starting_turf" = 1), god I love DM.

		while (length(turf_stack)) // Ever wanted a loop that could theoretically run 20000 times in one tick? Then it's your lucky day.
			var/turf/current_turf = turf_stack[length(turf_stack)]
			turf_stack.len--

			for (var/direction in GLOB.cardinals) // And here's one that could run 80000 times in one tick. (PROFILE ANY CHANGES)
				var/turf/adjacent_turf = get_step(current_turf, direction) // Using get_step() 4 times is faster than caching a turf list with a locate() macro.

				if (splitting_group_turf_cache[adjacent_turf] && TURFS_CAN_SHARE(current_turf, adjacent_turf)) // The first part serves a dual purpose of checking if the turf is in the splitting group and if it's been visited.
					splitting_group_turf_cache -= adjacent_turf // Removing from the list is faster than setting the index to false.
					visited_turfs[adjacent_turf] = TRUE // Having to reconstruct this into an assoc list later outweighs the benefits of making it a normal list.
					turf_stack += adjacent_turf

		if (!length(new_group_turf_lists) && !length(splitting_group_turf_cache))
			return // We found all turfs on the first attempt. The group remains intact.

		new_group_turf_lists += list(visited_turfs) // Nope, there's gonna be more than one group after this. It's confirmed, WE NEED TO SPLIT!!

	for (var/list/new_group_turfs in new_group_turf_lists)
		var/datum/liquid_group/new_group = new()

		new_group.turfs = new_group_turfs // This does not need to be a copy, a ref is fine.

		new_group.maximum_volume_per_turf = splitting_group.maximum_volume_per_turf
		LIQUID_UPDATE_MAXIMUM_VOLUME(new_group)

		var/turf_ratio = length(new_group_turfs) / length(splitting_group.turfs)

		new_group.heat_capacity = splitting_group.heat_capacity * turf_ratio
		splitting_group.copy_reagents_to(new_group, splitting_group.reagents.total_volume * turf_ratio)

		for (var/turf/old_edge_turf as anything in splitting_group.edge_turfs) // Transferring edge turfs is important, recalculating all of them would be a performance NIGHTMARE.
			if (new_group_turfs[old_edge_turf])
				new_group.edge_turfs[old_edge_turf] = TRUE

		for (var/turf/old_edge_turf as anything in splitting_group.edge_turf_spread_directions)
			if (new_group_turfs[old_edge_turf])
				new_group.next_spread_count += length(splitting_group.edge_turf_spread_directions[old_edge_turf])
				new_group.edge_turf_spread_directions[old_edge_turf] = splitting_group.edge_turf_spread_directions[old_edge_turf]

		for (var/turf/new_group_turf as anything in new_group_turfs)
			new_group_turf.liquid_group = new_group
			new_group_turf.liquid_effect.liquid_group = new_group

		for (var/atom/movable/old_exposed_atom as anything in splitting_group.exposed_atoms)
			if (!new_group_turfs[old_exposed_atom.loc])
				continue

			new_group.exposed_atoms[old_exposed_atom] = splitting_group.exposed_atoms[old_exposed_atom]
			splitting_group.UnregisterSignal(old_exposed_atom, COMSIG_QDELETING)
			new_group.RegisterSignal(old_exposed_atom, COMSIG_QDELETING, TYPE_PROC_REF(/datum/liquid_group, remove_atom))

	splitting_group.turfs = list() // Clear it early so that splitting_group.Destroy() doesn't delete liquid effects.
	splitting_group.exposed_atoms = list() // Ditto, but for liquid immersion effects.
	qdel(splitting_group)
