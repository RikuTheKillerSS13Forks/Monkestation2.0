/turf/closed/archmetal // Not actually a wall because those have a bunch of additional functionality we don't want like deconstruction.
	name = "archmetal wall"
	desc = "The ultimate defense. Solid ether lines its inner workings, powering its impenetrable surface for eons to come."

	icon = 'monkestation/icons/turf/walls/archmetal_wall.dmi'
	icon_state = "archmetal_wall-0"
	base_icon_state = "archmetal_wall"

	turf_flags = IS_SOLID | NOJAUNT | NO_RUST
	thermal_conductivity = 0
	explosive_resistance = INFINITY
	rad_insulation = RAD_FULL_INSULATION

	smoothing_flags = SMOOTH_BITMASK
	smoothing_groups = SMOOTH_GROUP_WALLS + SMOOTH_GROUP_CLOSED_TURFS
	canSmoothWith = SMOOTH_GROUP_AIRLOCK + SMOOTH_GROUP_WINDOW_FULLTILE + SMOOTH_GROUP_WALLS
	smooth_adapters = SMOOTH_ADAPTERS_WALLS_FOR_WALLS

	baseturfs = /turf/open/floor/plating
