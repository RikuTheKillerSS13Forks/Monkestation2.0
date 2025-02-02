/obj/structure/closet/crate/coffin
	breakout_time = 30 SECONDS

	/// The time it takes to pry this open with a crowbar.
	var/pry_lid_time = 20 SECONDS

/obj/structure/closet/crate/coffin/examine(mob/user)
	. = ..()
	if (locked)
		. += span_notice("It can be <b>pried</b> open.")
	if (IS_VAMPIRE(user))
		. += span_cult("A fitting place of rest. You can recover far faster within.")
		. += span_cult("However, you are vulnerable while asleep.")
		if (!anchored)
			. += span_cult("Anchoring it would be a fine choice.")

/obj/structure/closet/crate/coffin/close(mob/living/user)
	. = ..()
	if (!locked && (user in src) && IS_VAMPIRE(user))
		to_chat(user, span_notice("You flip a secret latch and lock yourself inside \the [src]."))
		locked = TRUE

/obj/structure/closet/crate/coffin/can_open(mob/living/user)
	if (!IS_VAMPIRE(user))
		return ..()

	if (locked)
		to_chat(user, span_notice("You flip a secret latch and unlock \the [src]."))

	if (welded)
		visible_message(
			message = span_danger("The weld on \the [src] breaks apart!"),
			self_message = span_warning("You bust open the weld on \the [src]!"),
			blind_message = span_hear("You hear a loud clang!"),
		)
		playsound(src, 'sound/effects/meteorimpact.ogg', vol = 60, vary = TRUE)

	return TRUE // OPEN SESAME DAMNIT!!

/obj/structure/closet/crate/coffin/crowbar_act(mob/living/user, obj/item/tool)
	if (user.istate & ISTATE_HARM)
		return FALSE
	if (!locked || welded) // You can't pry open the lid of a welded coffin.
		return FALSE

	user.visible_message(
		message = span_notice("[user] tries to pry the lid off of \the [src] with \the [tool]."),
		self_message = span_notice("You begin prying the lid off of \the [src] with \the [tool]. This should take about [DisplayTimeText(pry_lid_time)]."),
		blind_message = span_hear("You hear creaking.")
	)
	playsound(src, 'sound/machines/airlock_alien_prying.ogg', vol = 20, vary = TRUE)

	if(!tool.use_tool(src, user, pry_lid_time))
		return TRUE
	bust_open()

	user.visible_message(
		message = span_notice("[user] snaps the door of \the [src] wide open."),
		self_message = span_notice("The door of \the [src] snaps open."),
		blind_message = span_hear("You hear a clink."),
	)

	return TRUE

/obj/structure/closet/crate/coffin/bust_open()
	. = ..()
	broken = FALSE

/obj/structure/closet/crate/coffin/blackcoffin
	name = "black coffin"
	desc = "For those departed who are not so dear."
	icon_state = "coffin"
	icon = 'monkestation/icons/vampires/vampire_obj.dmi'
	open_sound = 'monkestation/sound/vampires/coffin_open.ogg'
	close_sound = 'monkestation/sound/vampires/coffin_close.ogg'
	resistance_flags = NONE
	armor_type = /datum/armor/blackcoffin

/datum/armor/blackcoffin
	melee = 30
	bullet = 20
	laser = 20
	bomb = 50
	fire = 70
	acid = 70

/obj/structure/closet/crate/coffin/meatcoffin
	name = "meat coffin"
	desc = "When you're ready to meat your maker, the steaks can never be too high."
	icon_state = "meatcoffin"
	icon = 'monkestation/icons/vampires/vampire_obj.dmi'
	resistance_flags = FIRE_PROOF
	open_sound = 'sound/effects/footstep/slime1.ogg'
	close_sound = 'sound/effects/footstep/slime1.ogg'
	material_drop = /obj/item/food/meat/slab/human
	material_drop_amount = 3
	armor_type = /datum/armor/meatcoffin

/datum/armor/meatcoffin
	melee = 50
	bullet = 30
	laser = 30
	bomb = 70
	fire = 70
	acid = 70

/obj/structure/closet/crate/coffin/metalcoffin
	name = "metal coffin"
	desc = "A big metal sardine can inside of another big metal sardine can, in space."
	icon_state = "metalcoffin"
	icon = 'monkestation/icons/vampires/vampire_obj.dmi'
	resistance_flags = FIRE_PROOF
	open_sound = 'sound/effects/pressureplate.ogg'
	close_sound = 'sound/effects/pressureplate.ogg'
	pry_lid_time = 30 SECONDS
	material_drop = /obj/item/stack/sheet/iron
	material_drop_amount = 4
	armor_type = /datum/armor/metalcoffin

/datum/armor/metalcoffin
	melee = 40
	bullet = 40
	laser = 40
	bomb = 70
	fire = 70
	acid = 70

/obj/structure/closet/crate/coffin/securecoffin
	name = "secure coffin"
	desc = "For those too scared of having their place of rest disturbed."
	icon_state = "securecoffin"
	icon = 'monkestation/icons/vampires/vampire_obj.dmi'
	open_sound = 'monkestation/sound/vampires/coffin_open.ogg'
	close_sound = 'monkestation/sound/vampires/coffin_close.ogg'
	pry_lid_time = 40 SECONDS
	resistance_flags = FIRE_PROOF | LAVA_PROOF | ACID_PROOF
	material_drop = /obj/item/stack/sheet/plasteel
	material_drop_amount = 5
	armor_type = /datum/armor/securecoffin

/datum/armor/securecoffin
	melee = 70
	bullet = 50
	laser = 50
	bomb = 100
	fire = 100
	acid = 100
