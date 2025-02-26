/turf
	/// The liquid group on the turf, contains the actual reagents in the liquid and handles all the spreading and such.
	/// You can do almost anything related to liquids through this.
	var/datum/liquid_group/liquid_group

	/// The liquid effect on the turf, caches some turf-specific liquid information (like fire) but is mostly for visuals.
	/// Try to bind as little functionality as possible to this.
	var/obj/effect/abstract/liquid/liquid_effect

	/// The height of the turf, with 100 being the ceiling and -100 being the floor down below.
	/// Used for liquids, different heights have different liquid groups and maximum units per turf.
	var/turf_height = 0

/turf/open/Destroy(force)
	clear_liquid()
	return ..()

/turf/open/ChangeTurf(path, list/new_baseturfs, flags)
	if ((flags & CHANGETURF_INHERIT_AIR) && liquid_group)
		var/datum/liquid_group/cached_liquid_group = liquid_group
		. = ..()
		cached_liquid_group.add_turf(.)
	else
		return ..()

/turf/open/copyTurf(turf/open/copy_to_turf, copy_air)
	. = ..()
	if (copy_air)
		copy_to_turf.clear_liquid()
		if (liquid_group)
			new /datum/liquid_group(copy_to_turf)
			liquid_group.copy_reagents_to(copy_to_turf.liquid_group, LIQUID_GET_VOLUME_PER_TURF(liquid_group))

/// Tries to add the given amount of liquid to the turf and returns the amount added, if any.
/turf/proc/add_liquid(reagent_id, amount, no_react = TRUE)
	if (!reagent_id || !isnum(amount) || amount <= 0)
		return 0

	if (!liquid_group)
		new /datum/liquid_group(src) // This sets our liquid group on init.

	return liquid_group?.reagents.add_reagent(reagent_id, amount, no_react = no_react)

/// Tries to remove the given amount of liquid from the turf and returns the amount removed, if any.
/// This will not clear the liquids from the turf.
/turf/proc/remove_liquid(amount)
	if (!isnum(amount) || amount <= 0)
		return 0

	return liquid_group?.reagents.remove_all(amount)

/// Removes all liquid from the turf and returns the amount removed, if any.
/// This will clear the liquids from the turf.
/turf/proc/remove_all_liquid()
	. = liquid_group?.reagents.remove_all(liquid_group.reagents.total_volume / length(liquid_group.turfs))
	clear_liquid()

/// Clears all liquid from the turf, if there is any.
/// This pushes the reagents to other turfs in the same liquid group.
/turf/proc/clear_liquid()
	liquid_group?.remove_turf(src)
