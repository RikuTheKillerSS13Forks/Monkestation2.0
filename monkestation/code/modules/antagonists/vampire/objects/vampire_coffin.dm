/obj/structure/closet/crate/coffin
	breakout_time = 10 SECONDS // A weld isn't going to hold the vamp in very reliably.

/obj/structure/closet/crate/coffin/examine(mob/user)
	. = ..()
	if (IS_VAMPIRE(user))
		. += span_cult("A fitting place of rest. You can recover far faster within.")
		. += span_cultbold("However, you will be vulnerable while asleep.")
