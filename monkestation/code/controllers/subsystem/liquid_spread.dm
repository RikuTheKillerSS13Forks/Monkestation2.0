SUBSYSTEM_DEF(liquid_spread)
	name = "Liquid Spread"
	wait = 0.2 SECONDS
	flags = SS_KEEP_TIMING | SS_NO_INIT
	runlevels = RUNLEVEL_GAME | RUNLEVEL_POSTGAME

	/// List of liquid groups to call process_spread() on, persists across resumed fire() calls.
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

	/// List of liquid groups to call process_late_spread() on, persists across resumed fire() calls.
	/// Required to keep liquid group spreading from going out of sync between groups.
	/// Kinda dangerous, as qdeleted liquid groups will not be deleted from this.
	var/list/late_spread_cache = list()

/datum/controller/subsystem/liquid_spread/fire(resumed = FALSE)
	if (!length(GLOB.liquid_groups)) // Someone can implement can_fire later if they want to. This does the job just fine for now.
		return

	if (!resumed)
		spread_cache = GLOB.liquid_groups.Copy()
		combine_cache = GLOB.liquid_combine_queue.Copy()
		split_cache = GLOB.liquid_split_queue.Copy()
		late_spread_cache = GLOB.liquid_groups.Copy()

		GLOB.liquid_combine_queue = list()
		GLOB.liquid_split_queue = list()

	while (length(spread_cache))
		var/datum/liquid_group/liquid_group = spread_cache[length(spread_cache)]
		spread_cache.len--
		if (!QDELETED(liquid_group))
			liquid_group.process_spread(wait * 0.1)
		if (MC_TICK_CHECK)
			return

	for (var/datum/liquid_group/recessive_group as anything in combine_cache) // Has to be front-to-back or else shit breaks. And I mean REALLY breaks. This is due to the order in which combine_cache is built.
		var/datum/liquid_group/dominant_group = combine_cache[recessive_group]
		combine_cache -= recessive_group
		if (!QDELETED(recessive_group) && !QDELETED(dominant_group))
			combine_liquid_groups(dominant_group, recessive_group)
		if (MC_TICK_CHECK)
			return

	while (length(split_cache))
		var/datum/liquid_group/splitting_group = split_cache[length(split_cache)]
		split_cache.len--
		if (!QDELETED(splitting_group))
			split_liquid_group(splitting_group)
		if (MC_TICK_CHECK)
			return

	while (length(late_spread_cache))
		var/datum/liquid_group/liquid_group = late_spread_cache[length(late_spread_cache)]
		late_spread_cache.len--
		if (!QDELETED(liquid_group))
			liquid_group.process_late_spread(wait * 0.1)
		if (MC_TICK_CHECK)
			return

/// As the name implies, combines two separate liquid groups into one.
/// More importantly, don't call this outside of SSliquid_spread. I will find you.
/datum/controller/subsystem/liquid_spread/proc/combine_liquid_groups(datum/liquid_group/dominant_group, datum/liquid_group/recessive_group)
	dominant_group.turfs += recessive_group.turfs
	dominant_group.edge_turfs += recessive_group.edge_turfs
	dominant_group.edge_turf_spread_directions += recessive_group.edge_turf_spread_directions

	LIQUID_UPDATE_MAXIMUM_VOLUME(dominant_group)
	recessive_group.copy_reagents_to(dominant_group)

	for (var/turf/recessive_group_turf as anything in recessive_group.turfs)
		recessive_group_turf.liquid_group = dominant_group // Get stolen, bitchass.

	recessive_group.turfs = list() // Clear it early so that recessive_group.Destroy() doesn't delete liquid effects.
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

				if (splitting_group_turf_cache[adjacent_turf]) // Serves a dual purpose of checking if the turf is in the splitting group and if it's been visited.
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

		splitting_group.copy_reagents_to(new_group, splitting_group.reagents.total_volume * (length(new_group_turfs) / length(splitting_group.turfs)))

		for (var/turf/old_edge_turf as anything in splitting_group.edge_turfs) // Transferring edge turfs is important, recalculating all of them would be a performance NIGHTMARE.
			if (new_group_turfs[old_edge_turf])
				new_group.edge_turfs[old_edge_turf] = TRUE
				new_group.edge_turf_spread_directions[old_edge_turf] = splitting_group.edge_turf_spread_directions[old_edge_turf]

		for (var/turf/new_group_turf as anything in new_group_turfs)
			new_group_turf.liquid_group = new_group // Get stolen, bitchass.

	splitting_group.turfs = list() // Clear it early so that splitting_group.Destroy() doesn't delete liquid effects.
	qdel(splitting_group)
