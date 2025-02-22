/turf/open
	/// The liquid group on the turf, contains the actual reagents in the liquid and handles all the spreading and such.
	/// You can do almost anything related to liquids through this.
	var/datum/liquid_group/liquid_group

	/// The liquid effect on the turf, caches some turf-specific liquid information (like fire) but is mostly for visuals.
	/// Try to bind as little functionality as possible to this.
	var/obj/effect/abstract/liquid/liquid_effect

	/// The height of the turf, with 100 being the ceiling and -100 being the floor down below.
	/// Used for liquids, different heights have different liquid groups and maximum units per turf.
	var/turf_height = 0

/// Tries to add the given amount of liquid to the turf and returns the amount added, if any.
/turf/open/proc/add_liquid(reagent_id, amount, no_react = TRUE)
	if (!reagent_id || !isnum(amount) || amount <= 0)
		return 0
	if (!LIQUID_CAN_ENTER_TURF(src))
		return 0

	if (!liquid_group)
		new /datum/liquid_group(src) // This sets 'liquid_group' on init.

	return liquid_group.reagents.add_reagent(reagent_id, amount, no_react = no_react)

/// Tries to remove the given amount of liquid from the turf and returns the amount removed, if any.
/turf/open/proc/remove_liquid(amount)
	if (!liquid_group || !isnum(amount) || amount <= 0)
		return 0

	return liquid_group.reagents.remove_all(amount)
