/datum/liquid_group
	/// List of all turfs in this liquid group.
	var/list/turf_cache = list()

	/// Holder for all reagents in this liquid group.
	var/datum/reagents/reagents

/datum/liquid_group/New(turf/open/initial_turf)
	reagents = new(0)
	if (initial_turf)
		add_turf(initial_turf)

/datum/liquid_group/Destroy(force)
	for (var/turf/open/target_turf in turf_cache)
		target_turf.liquid_group = null
		QDEL_NULL(target_turf.liquid_effect)
	turf_cache.Cut()

	QDEL_NULL(reagents)
	return ..()

/// Adds a turf to the liquid group. Does barely any sanity checks.
/datum/liquid_group/proc/add_turf(turf/open/target_turf)
	if (target_turf.liquid_group)
		CRASH("A liquid group tried to add a turf that is already in a liquid group.")

	turf_cache += target_turf
	target_turf.liquid_group = src

	target_turf.liquid_effect = new(target_turf, src) // This is practically the only place that should initialize liquid effects.

	reagents.maximum_volume += LIQUID_GET_TURF_MAXIMUM_VOLUME(target_turf)

/// Removes a turf from the liquid group. Does barely any sanity checks.
/// Only use this when you intend to remove turfs without destroying the whole group.
/// If you want to destroy the whole group, then just qdel it instead. (it's way faster)
/datum/liquid_group/proc/remove_turf(turf/open/target_turf)
	if (target_turf.liquid_group != src)
		CRASH("A liquid group tried to remove a turf that isn't even in it.")

	turf_cache -= target_turf
	target_turf.liquid_group = null

	QUEUE_SMOOTH_NEIGHBORS(target_turf.liquid_effect)
	QDEL_NULL(target_turf.liquid_effect)

	reagents.maximum_volume -= LIQUID_GET_TURF_MAXIMUM_VOLUME(target_turf)

	if (reagents.total_volume > reagents.maximum_volume) // Total volume should never exceed maximum volume.
		reagents.remove_all(reagents.total_volume - reagents.maximum_volume) // So we obliterate the excess.
