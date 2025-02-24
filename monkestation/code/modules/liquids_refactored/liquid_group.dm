/datum/liquid_group
	/// Associative list of all turfs in this liquid group.
	/// Format is "turfs[turf] = TRUE"
	var/list/turfs = list()

	/// Associative list of all edge turfs, including ones that can't spread anywhere. (turf = TRUE)
	/// Separate from the directions list so process_spread() doesn't do a 10000-unit for-each loop.
	/// Necessary for splitting turfs and such.
	var/list/edge_turfs = list()

	/// Associative list of all edge turfs in this liquid group. (turf = list of spread directions)
	/// From tests I've ran, this is currently the fastest way to handle liquid spread by far.
	var/list/edge_turf_spread_directions = list()

	/// Holder for all reagents in this liquid group.
	var/datum/reagents/reagents

	/// How much maximum volume this liquid group gets per turf.
	/// This is a cached value of LIQUID_GET_TURF_MAXIMUM_VOLUME(initial_turf)
	var/maximum_volume_per_turf = 0

/datum/liquid_group/New(turf/initial_turf)
	reagents = new(0)
	reagents.flags |= NO_REACT // We handle reactions ourselves once every 2 seconds.

	if (initial_turf)
		maximum_volume_per_turf = LIQUID_GET_TURF_MAXIMUM_VOLUME(initial_turf)
		add_turf(initial_turf)

	GLOB.liquid_groups += src

/datum/liquid_group/Destroy(force)
	GLOB.liquid_groups -= src
	GLOB.liquid_combine_queue -= src
	QDEL_NULL(reagents)
	remove_all_turfs()
	return ..()

/// Adds a turf to the liquid group. Does barely any sanity checks.
/datum/liquid_group/proc/add_turf(turf/target_turf)
	if (target_turf.liquid_group)
		CRASH("A liquid group tried to add a turf that is already in a liquid group.")

	turfs[target_turf] = TRUE

	target_turf.liquid_group = src
	target_turf.liquid_effect ||= new(target_turf) // This is the only place that should be creating liquid effects.

	update_edges(target_turf) // Has to happen immediately or else spreading/receding will break, splitting will break, etc...
	LIQUID_UPDATE_ADJACENT_EDGES(target_turf) // Same here.

	LIQUID_UPDATE_MAXIMUM_VOLUME(src)

/// Removes a turf from the liquid group. Does barely any sanity checks.
/// Only use this when you intend to remove turfs without destroying the whole group.
/// If you want to destroy the whole group, then just qdel it instead. (it's way faster)
/datum/liquid_group/proc/remove_turf(turf/target_turf)
	if (!turfs[target_turf])
		CRASH("A liquid group tried to remove a turf that isn't even in it.")

	check_split(target_turf) // Has to happen first, before we update edges or get removed from the turf lists.

	turfs -= target_turf
	edge_turfs -= target_turf
	edge_turf_spread_directions -= target_turf

	target_turf.liquid_group = null

	QUEUE_SMOOTH_NEIGHBORS(target_turf.liquid_effect)
	QDEL_NULL(target_turf.liquid_effect) // This is the only place that should be deleting liquid effects.

	LIQUID_UPDATE_ADJACENT_EDGES(target_turf) // Has to happen immediately or else spreading/receding will break, splitting will break, etc...

	LIQUID_UPDATE_MAXIMUM_VOLUME(src)

	if (reagents.total_volume > reagents.maximum_volume) // Total volume should never exceed maximum volume.
		reagents.remove_all(reagents.total_volume - reagents.maximum_volume) // So we obliterate the excess.

/// Removes all turfs from the liquid group.
/datum/liquid_group/proc/remove_all_turfs()
	for (var/turf/target_turf as anything in turfs)
		QDEL_NULL(target_turf.liquid_effect)

	turfs = list()
	edge_turfs = list()
	edge_turf_spread_directions = list()

/// Updates edge_turfs for the given turf.
/datum/liquid_group/proc/update_edges(turf/target_turf)
	var/list/spread_directions = list()
	var/is_edge_turf = FALSE // Exists because splitting uses edge turfs as well. (and needs non-spreading edge turfs marked as well!)

	for (var/direction in GLOB.cardinals)
		var/turf/adjacent_turf = get_step(target_turf, direction)

		if (turfs[adjacent_turf])
			continue
		if (QDELETED(adjacent_turf) || !TURFS_CAN_SHARE(target_turf, adjacent_turf))
			is_edge_turf = TRUE
			continue
		else if (!adjacent_turf.liquid_group)
			spread_directions += direction
			is_edge_turf = TRUE
		else
			LIQUID_QUEUE_COMBINE(src, adjacent_turf.liquid_group) // Combines us with them (we are recessive), not the other way around.

	if (length(spread_directions))
		edge_turf_spread_directions[target_turf] = spread_directions
	else
		edge_turf_spread_directions -= target_turf

	if (is_edge_turf)
		edge_turfs[target_turf] = TRUE
	else
		edge_turfs -= target_turf

/// Checks whether removing the given turf could cause a split.
/// If so, queues a full split for SSliquid_spread to handle.
/datum/liquid_group/proc/check_split(turf/target_turf)
	if (!edge_turfs[target_turf])
		var/is_adjacent_to_edge = FALSE
		for (var/direction in GLOB.cardinals)
			if (edge_turfs[get_step(target_turf, direction)]) // If the target turf is not a cardinal edge, but it's adjacent to one, then it's a diagonal edge.
				is_adjacent_to_edge = TRUE
				break
		if (!is_adjacent_to_edge) // If it's not a cardinal or diagonal edge, then it can't possibly split the group.
			return

	// Okay, this could cause a split, but we're not going to give up that easily.
	// Instead of immediately queuing a full BFT, we're going to do a localized BFT first.
	// This is to check if all turfs in this liquid group adjacent to us remain connected to each other.
	// Because if they don't, then we're going to have to resort to a full BFT. But we're gonna try to stave it off.

	var/list/adjacent_liquid_turfs = list() // Associative list of all turfs in this liquid group that are adjacent to us, used for the BFT checks. (adjacent_liquid_turfs[turf] = has_not_been_visited)

	for (var/direction in GLOB.cardinals) // First the cardinals, for the upcoming check.
		var/turf/adjacent_turf = get_step(target_turf, direction)
		if (turfs[adjacent_turf])
			adjacent_liquid_turfs[adjacent_turf] = TRUE // TRUE = has not been visited

	if (length(adjacent_liquid_turfs) <= 1) // If we only have one adjacent cardinal, then removing us can't cause a split. (nothing is depending on us for a connection)
		return

	for (var/direction in GLOB.diagonals) // And now the diagonals get to join in.
		var/turf/adjacent_turf = get_step(target_turf, direction)
		if (turfs[adjacent_turf])
			adjacent_liquid_turfs[adjacent_turf] = TRUE // TRUE = has not been visited

	var/list/turf_stack = list(adjacent_liquid_turfs[1]) // List of turfs to propagate from on the next BFT (Breadth-First Traversal) iteration.
	var/total_adjacents_visited = 0

	while (length(turf_stack))
		var/turf/current_turf = turf_stack[length(turf_stack)]
		turf_stack.len--

		for (var/direction in GLOB.cardinals)
			var/turf/adjacent_turf = get_step(current_turf, direction)
			if (adjacent_liquid_turfs[adjacent_turf]) // Serves a dual purpose, making sure the turf is an adjacent liquid turf and that it hasn't been visited.
				adjacent_liquid_turfs[adjacent_turf] = FALSE // FALSE = has been visited
				turf_stack += adjacent_turf
				total_adjacents_visited++

		if (total_adjacents_visited >= length(adjacent_liquid_turfs))
			return

	LIQUID_QUEUE_SPLIT(src) // Welp, we have to eat the full cost of a group-wide BFT.

/// Called by SSliquid_processing to handle self-processing for liquid groups.
/datum/liquid_group/process(seconds_per_tick)
	return

/// Called by SSliquid_spread to handle spreading liquid groups.
/// This proc is pretty hot. I optimized it really well, profile shit if you change it.
/datum/liquid_group/proc/process_spread(seconds_per_tick)
	for (var/turf/edge_turf as anything in edge_turf_spread_directions)
		for (var/direction in edge_turf_spread_directions[edge_turf])
			add_turf(get_step(edge_turf, direction))
