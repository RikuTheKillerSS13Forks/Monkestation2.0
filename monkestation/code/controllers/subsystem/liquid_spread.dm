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

/datum/controller/subsystem/liquid_spread/fire(resumed = FALSE)
	if (!resumed)
		spread_cache = GLOB.liquid_groups.Copy()
		combine_cache = GLOB.liquid_combine_queue.Copy()

		GLOB.liquid_combine_queue.Cut()

	while (length(spread_cache))
		var/datum/liquid_group/liquid_group = spread_cache[length(spread_cache)]
		spread_cache.len--
		if (!QDELETED(liquid_group))
			liquid_group.process_spread(wait * 0.1)
		if (MC_TICK_CHECK)
			return

	for (var/datum/liquid_group/recessive_group as anything in combine_cache)
		var/datum/liquid_group/dominant_group = combine_cache[recessive_group]
		combine_cache -= recessive_group
		if (!QDELETED(recessive_group) && !QDELETED(dominant_group))
			combine_liquid_groups(dominant_group, recessive_group)
		if (MC_TICK_CHECK)
			return

/// As the name implies, combines two separate liquid groups into one.
/// More importantly, don't call this outside of SSliquid_spread. I will find you.
/datum/controller/subsystem/liquid_spread/proc/combine_liquid_groups(datum/liquid_group/dominant_group, datum/liquid_group/recessive_group)
	dominant_group.turfs += recessive_group.turfs
	dominant_group.edge_turfs += recessive_group.edge_turfs
	dominant_group.edge_turf_spread_directions += recessive_group.edge_turf_spread_directions

	dominant_group.reagents.maximum_volume += recessive_group.reagents.maximum_volume
	recessive_group.reagents.copy_to(dominant_group.reagents, recessive_group.reagents.total_volume, preserve_data = TRUE, no_react = TRUE)

	for (var/turf/recessive_group_turf as anything in recessive_group.turfs)
		recessive_group_turf.liquid_group = dominant_group // Get stolen bitchass. Also prevents recessive_group.Destroy() from cleaning up liquid effects.

	qdel(recessive_group)
