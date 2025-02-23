/datum/liquid_group
	/// Simple list of all turfs in this liquid group.
	var/list/turfs = list()

	/// Simple list of all edge turfs, including ones that can't spread anywhere.
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

/datum/liquid_group/New(turf/open/initial_turf)
	maximum_volume_per_turf = LIQUID_GET_TURF_MAXIMUM_VOLUME(initial_turf)
	reagents = new(0)
	add_turf(initial_turf)
	GLOB.liquid_groups += src

/datum/liquid_group/Destroy(force)
	GLOB.liquid_groups -= src
	GLOB.liquid_combine_queue -= src
	QDEL_NULL(reagents)
	remove_all_turfs()
	return ..()

/// Adds a turf to the liquid group. Does barely any sanity checks.
/datum/liquid_group/proc/add_turf(turf/open/target_turf)
	if (target_turf.liquid_group)
		CRASH("A liquid group tried to add a turf that is already in a liquid group.")

	turfs += target_turf

	target_turf.liquid_group = src
	target_turf.liquid_effect ||= new(target_turf) // This is the only place that should be creating liquid effects.

	update_edges(target_turf) // Has to happen immediately or else spreading/receding will break, splitting will break, etc...
	LIQUID_UPDATE_ADJACENT_EDGES(target_turf) // Same here.

	reagents.maximum_volume += maximum_volume_per_turf

/// Removes a turf from the liquid group. Does barely any sanity checks.
/// Only use this when you intend to remove turfs without destroying the whole group.
/// If you want to destroy the whole group, then just qdel it instead. (it's way faster)
/datum/liquid_group/proc/remove_turf(turf/open/target_turf)
	if (target_turf.liquid_group != src)
		CRASH("A liquid group tried to remove a turf that isn't even in it.")

	turfs -= target_turf
	edge_turfs -= target_turf
	edge_turf_spread_directions -= target_turf

	target_turf.liquid_group = null

	QUEUE_SMOOTH_NEIGHBORS(target_turf.liquid_effect)
	QDEL_NULL(target_turf.liquid_effect) // This is the only place that should be deleting liquid effects.

	LIQUID_UPDATE_ADJACENT_EDGES(target_turf) // Has to happen immediately or else spreading/receding will break, splitting will break, etc...

	reagents.maximum_volume -= maximum_volume_per_turf

	if (reagents.total_volume > reagents.maximum_volume) // Total volume should never exceed maximum volume.
		reagents.remove_all(reagents.total_volume - reagents.maximum_volume) // So we obliterate the excess.

/// Removes all turfs from the liquid group.
/datum/liquid_group/proc/remove_all_turfs()
	for (var/turf/open/target_turf as anything in turfs)
		if (target_turf.liquid_group == src) // In case of SSliquid_spread.combine_liquid_groups()
			target_turf.liquid_group = null
			QDEL_NULL(target_turf.liquid_effect)

	turfs.Cut()
	edge_turfs.Cut()
	edge_turf_spread_directions.Cut()

/// Updates edge_turfs for the given turf.
/datum/liquid_group/proc/update_edges(turf/open/target_turf)
	var/list/spread_directions = list()
	var/is_edge_turf = FALSE // Exists because splitting uses edge turfs as well. (and needs non-spreading edge turfs marked as well!)

	for (var/direction in GLOB.cardinals)
		var/turf/open/adjacent_turf = get_step(target_turf, direction)

		if (QDELETED(adjacent_turf) || !TURFS_CAN_SHARE(target_turf, adjacent_turf))
			is_edge_turf = TRUE
			continue
		else if (!adjacent_turf.liquid_group)
			spread_directions += direction
			is_edge_turf = TRUE
		else if (adjacent_turf.liquid_group != src)
			LIQUID_QUEUE_COMBINE(src, adjacent_turf.liquid_group) // Combines us with them (we are recessive), not the other way around.

	if (length(spread_directions))
		edge_turf_spread_directions[target_turf] = spread_directions
	else
		edge_turf_spread_directions -= target_turf

	if (is_edge_turf)
		edge_turfs[target_turf] = TRUE
	else
		edge_turfs -= target_turf

/// Called by SSliquid_processing to handle self-processing for liquids groups.
/datum/liquid_group/process(seconds_per_tick)
	return

/// Called by SSliquid_spread to handle spreading liquid groups.
/// This proc is pretty hot. I optimized it really well, profile shit if you change it.
/datum/liquid_group/proc/process_spread(seconds_per_tick)
	for (var/turf/open/edge_turf as anything in edge_turf_spread_directions)
		for (var/direction in edge_turf_spread_directions[edge_turf])
			add_turf(get_step(edge_turf, direction))
