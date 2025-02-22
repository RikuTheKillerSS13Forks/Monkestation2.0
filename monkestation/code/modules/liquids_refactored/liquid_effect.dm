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

/obj/effect/abstract/liquid/Initialize(mapload, datum/liquid_group/liquid_group)
	. = ..()
	src.liquid_group = liquid_group

	QUEUE_SMOOTH(src)
	QUEUE_SMOOTH_NEIGHBORS(src)

/obj/effect/abstract/liquid/Destroy(force)
	liquid_group = null
	return ..()
