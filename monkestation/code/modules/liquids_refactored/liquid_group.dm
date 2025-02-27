/datum/liquid_group
	/// Associative list of all turfs in this liquid group.
	/// Format is "turfs[turf] = TRUE"
	var/list/turfs = list()

	/// Associative list of all cardinal edge turfs, including ones that can't spread anywhere. (turf = TRUE)
	/// Separate from the directions list so process_spread() doesn't do a 10000-unit for-each loop.
	/// Necessary for splitting turfs and such.
	var/list/edge_turfs = list()

	/// Associative list of all edge turfs in this liquid group. (turf = list of spread directions)
	/// From tests I've ran, this is currently the fastest way to handle liquid spread by far.
	var/list/edge_turf_spread_directions = list()

	/// If we hit a space turf while spreading, increment this.
	/// Used in process_late_spread() for consistent reagent amounts.
	var/queued_space_spreads = 0

	/// List of turfs we're trying to multi-z spread to.
	/// Used in process_late_spread() for consistent reagent amounts.
	var/queued_multiz_spreads = list()

	/// Holder for all reagents in this liquid group.
	var/datum/reagents/reagents

	var/static/list/reagent_signals = list(
		COMSIG_REAGENTS_NEW_REAGENT,
		COMSIG_REAGENTS_ADD_REAGENT,
		COMSIG_REAGENTS_DEL_REAGENT,
		COMSIG_REAGENTS_REM_REAGENT,
	)

	/// Used for seeing if the reagent holder has changed contents.
	/// Set back to FALSE in update_reagent_state() if it's TRUE.
	var/have_reagents_updated = FALSE

	/// How much maximum volume this liquid group gets per turf.
	/// This is a cached value of LIQUID_GET_TURF_MAXIMUM_VOLUME(initial_turf)
	var/maximum_volume_per_turf = 0

	/// Current liquid state (height level), refer to liquid_defines.dm for details.
	var/liquid_state = LIQUID_STATE_PUDDLE

	/// The precomputed color of the entire liquid group. Does not update immediately.
	var/liquid_color = "#FFFFFF"

/datum/liquid_group/New(turf/initial_turf) // I'm going to trust YOU to not create empty liquid groups. It's useful in some cases, as long as you're filling out the new one with turfs manually.
	reagents = new(0)
	reagents.flags |= NO_REACT // We handle reactions ourselves once every 2 seconds.

	RegisterSignals(reagents, reagent_signals, PROC_REF(on_reagents_updated))

	if (initial_turf)
		maximum_volume_per_turf = LIQUID_GET_TURF_MAXIMUM_VOLUME(initial_turf)
		add_turf(initial_turf)

	GLOB.liquid_groups += src

/datum/liquid_group/Destroy(force)
	GLOB.liquid_groups -= src
	GLOB.liquid_combine_queue -= src
	GLOB.liquid_split_queue -= src

	remove_all_turfs()

	UnregisterSignal(reagents, reagent_signals)
	QDEL_NULL(reagents)

	return ..()

/// Adds a turf to the liquid group. Does barely any sanity checks.
/datum/liquid_group/proc/add_turf(turf/target_turf)
	if (!LIQUID_CAN_ENTER_TURF_TYPE(target_turf))
		return
	if (target_turf.liquid_group)
		CRASH("A liquid group tried to add a turf that is already in a liquid group.")
	if (try_spread_multiz(target_turf)) // Has to be before actually adding the turf. (NEVER LET LIQUID SPREAD ON OPENSPACE IT OPENS PANDORA'S BOX)
		return

	turfs[target_turf] = TRUE

	target_turf.liquid_group = src
	target_turf.liquid_effect ||= new(target_turf, src) // This is the only place that should be creating liquid effects.

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

/// Removes all turfs from the liquid group. Very very fast.
/// Not perfect and will break smoothing for adjacent liquid groups.
/// But that is the price we pay for faster group combination and splitting.
/// This is guaranteed to destroy the liquid group by the way. So keep that in mind.
/datum/liquid_group/proc/remove_all_turfs()
	for (var/turf/target_turf as anything in turfs)
		QDEL_NULL(target_turf.liquid_effect)
		target_turf.liquid_group = null

	turfs = list()
	edge_turfs = list()
	edge_turf_spread_directions = list()

	if (!QDELING(src))
		qdel(src)

/// Updates all edge lists for the given turf.
/// Can also initiate a combination, so be careful.
/datum/liquid_group/proc/update_edges(turf/target_turf)
	var/list/spread_directions = list() // Only used for marking edge turfs that can spread and where they can spread.
	var/is_edge_turf = FALSE // Exists because splitting uses edge turfs as well. (and needs non-spreading edge turfs marked as well!)

	for (var/direction in GLOB.cardinals)
		var/turf/adjacent_turf = get_step(target_turf, direction)

		if (turfs[adjacent_turf])
			continue
		if (QDELETED(adjacent_turf) || !TURFS_CAN_SHARE(target_turf, adjacent_turf))
			is_edge_turf = TRUE
		else if (!adjacent_turf.liquid_group)
			spread_directions += direction
			is_edge_turf = TRUE
		else // We don't set this as an edge when combining. This is because combination does not update edges and happens instantly after this. (so act as if we already combined)
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
		var/is_adjacent_to_edge = FALSE // Don't try to cache this into diagonal_edge_turfs or whatever, I tried. And the game HARD CRASHED FOR INEXPLICABLE REASONS. IT'S CURSED.
		for (var/direction in GLOB.cardinals)
			if (edge_turfs[get_step(target_turf, direction)]) // If the target turf is not a cardinal edge, but it's adjacent to one, then it's a diagonal edge.
				is_adjacent_to_edge = TRUE
				break
		if (!is_adjacent_to_edge) // If it's not a cardinal or diagonal edge, then it can't possibly split the group.
			return

	// Okay, this could cause a split, but we're not going to give up that easily.
	// Instead of immediately queuing a full DFT, we're going to do a localized DFS first.
	// This is to check if all turfs in this liquid group cardinally adjacent to us remain connected to each other.
	// Because if they don't, then we're going to have to resort to a full DFT. But we're gonna try to stave it off.

	var/list/cardinal_liquid_turfs = list() // Associative list of all turfs in this liquid group that are cardinally adjacent to us, used for the DFT checks. (adjacent_liquid_turfs[turf] = has_not_been_visited)

	for (var/direction in GLOB.cardinals) // First the cardinals, for the upcoming check.
		var/turf/adjacent_turf = get_step(target_turf, direction)
		if (turfs[adjacent_turf])
			cardinal_liquid_turfs[adjacent_turf] = TRUE // TRUE = has not been visited

	if (length(cardinal_liquid_turfs) <= 1) // If we only have one adjacent cardinal, then removing us can't cause a split. (nothing is depending on us for a connection)
		return

	var/list/diagonal_liquid_turfs = list() // Associative list of all turfs in this liquid group that are diagonally adjacent to us, used for the DFT checks. (adjacent_liquid_turfs[turf] = has_not_been_visited)

	for (var/direction in GLOB.diagonals) // And now the diagonals get to join in.
		var/turf/adjacent_turf = get_step(target_turf, direction)
		if (turfs[adjacent_turf])
			diagonal_liquid_turfs[adjacent_turf] = TRUE // TRUE = has not been visited

	var/list/turf_stack = list(cardinal_liquid_turfs[1]) // List of turfs to propagate from on the next DFS (Depth-First Search) iteration. Start from a cardinal.
	var/total_cardinals_visited = 0

	while (length(turf_stack))
		var/turf/current_turf = turf_stack[length(turf_stack)]
		turf_stack.len--

		for (var/direction in GLOB.cardinals)
			var/turf/adjacent_turf = get_step(current_turf, direction)

			if (cardinal_liquid_turfs[adjacent_turf]) // Serves a dual purpose, making sure the turf is an adjacent liquid turf and that it hasn't been visited.
				cardinal_liquid_turfs[adjacent_turf] = FALSE // FALSE = has been visited
				turf_stack += adjacent_turf
				total_cardinals_visited++

				if (total_cardinals_visited >= length(cardinal_liquid_turfs))
					return // All cardinals visited, removing us can't cause a split.
			else if (diagonal_liquid_turfs[adjacent_turf])
				diagonal_liquid_turfs[adjacent_turf] = FALSE
				turf_stack += adjacent_turf

	LIQUID_QUEUE_SPLIT(src) // Welp, we have to eat the full cost of a group-wide DFT.

/// Called by SSliquid_processing to handle self-processing for liquid groups.
/datum/liquid_group/proc/process_liquid(seconds_per_tick, delta_time)
	reagents.remove_all(length(turfs) * LIQUID_BASE_EVAPORATION_RATE * delta_time) // Evaporation rate is based on surface area, i.e. how many turfs are in the liquid group.

/// Called by SSliquid_spread to handle spreading liquid groups. The loops can get pretty hot. (Profile shit if you change anything in them.)
/datum/liquid_group/proc/process_spread(seconds_per_tick)
	if (!check_should_exist())
		return
	if (LIQUID_GET_VOLUME_PER_TURF(src) >= LIQUID_SPREAD_VOLUME_THRESHOLD)
		spread()
	else if (reagents.total_volume <= LIQUID_SPREAD_VOLUME_THRESHOLD * (length(turfs) - get_evaporation_turf_count()))
		evaporate_edges() // Make sure we don't have enough liquid volume to spread after this. And use multiplication to avoid a division-by-zero at 1 turf.

/// Spreads the liquid group out by one turf at its edges.
/datum/liquid_group/proc/spread()
	for (var/turf/edge_turf as anything in edge_turf_spread_directions)
		for (var/direction in edge_turf_spread_directions[edge_turf])
			var/turf/adjacent_turf = get_step(edge_turf, direction)

			if (isspaceturf(adjacent_turf))
				queued_space_spreads++
			else
				add_turf(adjacent_turf)

/// Returns the number of turfs that will be evaporated if evaporate_edges() is run right now.
/datum/liquid_group/proc/get_evaporation_turf_count()
	return ceil(length(edge_turfs) * 0.5) // Ceil here because we want to always evaporate at least 1 turf.

/// Returns the number of turfs that won't be evaporated if evaporate_edges() is run right now.
/// Exists because evaporate_edges() actually works backwards from a copy of edge_turfs.
/datum/liquid_group/proc/get_inverse_evaporation_turf_count()
	return floor(length(edge_turfs) * 0.5) // Floor here because get_evaporation_turf_count() uses ceil.

/// Evaporates half of the liquid group's edges.
/datum/liquid_group/proc/evaporate_edges()
	var/list/turfs_to_evaporate = edge_turfs.Copy()
	for (var/i in 1 to get_inverse_evaporation_turf_count())
		turfs_to_evaporate -= pick(turfs_to_evaporate) // Work backwards, gives equal chances to all turfs without producing duplicates.
	for (var/turf/turf_to_evaporate in turfs_to_evaporate)
		remove_turf(turf_to_evaporate)

/// Recedes the liquid group back by one turf at its edges.
/datum/liquid_group/proc/recede()
	for (var/turf/edge_turf as anything in edge_turfs)
		remove_turf(edge_turf)

/// Tries to spread us down depending on gravity and returns TRUE if we did so.
/datum/liquid_group/proc/try_spread_multiz(turf/target_turf)
	var/gravity = target_turf.has_gravity(target_turf)
	if (gravity < STANDARD_GRAVITY || !target_turf.zPassOut(DOWN))
		return

	var/turf/multiz_turf = GET_TURF_BELOW(target_turf)
	if (multiz_turf?.zPassIn(DOWN))
		queued_multiz_spreads += multiz_turf
		return TRUE

/// Called by SSliquid_spread to handle operations that occur *after* normal spread operations are over.
/// This is stuff like pseudo-spreads where a liquid group spreads over an edge into another z level or into space.
/// Done because otherwise the reagent amounts used in such operations are dependent on *undefined ordering* and thats bad.
/datum/liquid_group/proc/process_late_spread(seconds_per_tick)
	process_pseudo_spreads()
	if (check_should_exist())
		update_liquid_state()
		update_reagent_state()

/datum/liquid_group/proc/process_pseudo_spreads()
	if (!queued_space_spreads && !length(queued_multiz_spreads))
		return

	// This is an estimate, we have no idea if the multiz turfs can actually contain all the liquid.
	// But actually figuring how much they can is a multi-step process that I'm just not willing to do.
	// So we're just going to count all of them as if we had actually spread to them, it's good enough.
	var/liquid_per_turf = reagents.total_volume / (length(turfs) + queued_space_spreads + length(queued_multiz_spreads))

	if (queued_space_spreads)
		reagents.remove_all(liquid_per_turf * queued_space_spreads)

	for (var/turf/multiz_turf as anything in queued_multiz_spreads)
		if (!QDELETED(multiz_turf))
			transfer_reagents_to(multiz_turf.liquid_group || new /datum/liquid_group(multiz_turf), liquid_per_turf)

	queued_space_spreads = 0
	queued_multiz_spreads = list()

/datum/liquid_group/proc/update_liquid_state()
	var/cached_liquid_state = liquid_state
	liquid_state = floor(LIQUID_GET_VOLUME_PER_TURF(src) / LIQUID_VOLUME_PER_STATE)

	if (cached_liquid_state == liquid_state)
		return

	if (cached_liquid_state == LIQUID_STATE_PUDDLE)
		for (var/turf/target_turf as anything in turfs)
			LIQUID_EFFECT_MAKE_FULLTILE(target_turf.liquid_effect)
	else if (liquid_state == LIQUID_STATE_PUDDLE)
		for (var/turf/target_turf as anything in turfs)
			LIQUID_EFFECT_MAKE_PUDDLE(target_turf.liquid_effect)
		for (var/turf/edge_turf as anything in edge_turfs)
			QUEUE_SMOOTH(edge_turf)
			QUEUE_SMOOTH_NEIGHBORS(edge_turf) // Look. It's not pretty. It's shit. But I can't cache diagonal edge turfs. THE GAME WONT LET ME. IT HARD CRASHES WHEN I TRY. WHAT THE FUCK.

/// Called whenever the reagent list of the reagent holder changes.
/datum/liquid_group/proc/on_reagents_updated()
	SIGNAL_HANDLER
	have_reagents_updated = TRUE

/// Updates things directly reliant on the reagent holder.
/datum/liquid_group/proc/update_reagent_state()
	if (!have_reagents_updated)
		return
	have_reagents_updated = FALSE

	var/new_liquid_color = mix_color_from_reagents(reagents.reagent_list)
	if (new_liquid_color != liquid_color)
		liquid_color = new_liquid_color
		for (var/turf/target_turf as anything in turfs)
			target_turf.liquid_effect.color = liquid_color

/datum/liquid_group/proc/copy_reagents_to(datum/liquid_group/other_liquid_group, amount = reagents.total_volume, no_react = TRUE)
	if (!other_liquid_group)
		return 0

	return reagents.copy_to(other_liquid_group.reagents, amount, no_react = no_react)

/datum/liquid_group/proc/transfer_reagents_to(datum/liquid_group/other_liquid_group, amount, no_react = TRUE)
	if (!other_liquid_group)
		return 0

	. = reagents.copy_to(other_liquid_group.reagents, amount, no_react = no_react)

	if (. > 0)
		reagents.remove_all(.)

/// Checks whether the liquid group should exist.
/// Returns whether it should and deletes it automatically if not.
/datum/liquid_group/proc/check_should_exist()
	if (QDELING(src))
		return FALSE
	. = length(turfs) && reagents.total_volume > 0
	if (!.)
		qdel(src)
