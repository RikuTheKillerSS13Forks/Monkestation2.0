// Handles the visual effects for turfs in liquid groups.
// Don't cache turf-specific data about liquid groups here, pulling from an assoc list is faster.'

/obj/effect/abstract/liquid
	name = "liquid"
	desc = "...wait, how are you examining this?"

	icon = 'monkestation/icons/obj/effects/liquid.dmi'
	icon_state = "water-0"
	base_icon_state = "water"

	color = "#DDF"
	alpha = 175

	smoothing_flags = SMOOTH_BITMASK | SMOOTH_OBJ
	smoothing_groups = SMOOTH_GROUP_WATER
	canSmoothWith = SMOOTH_GROUP_WATER + SMOOTH_GROUP_WINDOW_FULLTILE + SMOOTH_GROUP_WALLS

	anchored = TRUE
	mouse_opacity = FALSE
	plane = FLOOR_PLANE

	var/datum/liquid_group/liquid_group

	var/static/list/turf_enter_signals = list(
		COMSIG_ATOM_AFTER_SUCCESSFUL_INITIALIZED_ON,
		COMSIG_ATOM_ENTERED,
	)

	var/static/list/turf_signals = list(
		COMSIG_ATOM_AFTER_SUCCESSFUL_INITIALIZED_ON,
		COMSIG_ATOM_ENTERED,
		COMSIG_ATOM_EXITED,
	)

/obj/effect/abstract/liquid/Initialize(mapload, datum/liquid_group/liquid_group)
	. = ..()
	src.liquid_group = liquid_group

	if (liquid_group.liquid_state == LIQUID_STATE_PUDDLE)
		QUEUE_SMOOTH(src)
		QUEUE_SMOOTH_NEIGHBORS(src)
	else
		LIQUID_EFFECT_MAKE_FULLTILE(src)
		QUEUE_SMOOTH_NEIGHBORS(src) // There could be another liquid group nearby that's a puddle.

	color = liquid_group.liquid_color

	RegisterSignals(loc, turf_enter_signals, PROC_REF(on_entered))
	RegisterSignal(loc, COMSIG_ATOM_EXITED, PROC_REF(on_exited))

	for (var/atom/movable/existing_atom as anything in loc)
		on_entered(loc, existing_atom)

/obj/effect/abstract/liquid/Destroy(force)
	UnregisterSignal(loc, turf_signals)

	for (var/atom/movable/existing_atom as anything in loc)
		on_exited(loc, existing_atom)

	liquid_group = null
	return ..()

/obj/effect/abstract/liquid/bitmask_smooth()
	if (LIQUID_EFFECT_IS_PUDDLE(src))
		return ..()

/obj/effect/abstract/liquid/proc/on_entered(turf/source, atom/movable/exposed, atom/old_loc, list/old_locs)
	SIGNAL_HANDLER
	if (exposed == src || liquid_group.turfs[old_loc])
		return

/obj/effect/abstract/liquid/proc/on_exited(turf/source, atom/movable/exposed, direction)
	SIGNAL_HANDLER
	if (exposed == src || liquid_group.turfs[exposed.loc])
		return

/obj/effect/temp_visual/liquid_currents
	icon = 'monkestation/icons/obj/effects/splash.dmi'
	icon_state = "splash"
	layer = FLY_LAYER
	randomdir = FALSE

/obj/effect/temp_visual/liquid_currents/Initialize(mapload, color = "#FFFFFF")
	. = ..()
	src.color = color
