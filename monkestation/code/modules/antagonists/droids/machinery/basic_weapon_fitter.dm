/datum/looping_sound/basic_weapon_fitter
	mid_sounds = list('sound/items/welder.ogg' = 1, 'sound/items/welder2.ogg' = 1)
	mid_length = 0.5 SECONDS
	mid_length_vary = 0.1 SECONDS
	volume = 50
	vary = TRUE

/obj/machinery/basic_weapon_fitter
	name = "droid weapon fitter"
	desc = "Essentially a high-power industrial welding machine. A droid frame goes in and a death machine comes out."
	icon = 'monkestation/icons/obj/machines/droid_factory_machines.dmi'
	icon_state = "basic_weapon_fitter_off"
	flags_1 = NODECONSTRUCT_1
	density = TRUE
	subsystem_type = /datum/controller/subsystem/processing/fastprocess
	processing_flags = START_PROCESSING_MANUALLY

	var/datum/looping_sound/basic_weapon_fitter/sound_loop

	var/output_dir

	COOLDOWN_DECLARE(buzz_cooldown)

/obj/machinery/basic_weapon_fitter/Initialize(mapload)
	. = ..()
	sound_loop = new(src)

/obj/machinery/basic_weapon_fitter/update_icon_state()
	. = ..()
	icon_state = "basic_weapon_fitter_[is_operational ? "on" : "off"]"

/obj/machinery/basic_weapon_fitter/update_overlays()
	. = ..()
	if(occupant)
		. += list("working_window", "working_vents")

/obj/machinery/basic_weapon_fitter/Bumped(atom/movable/bumped_atom)
	. = ..()
	if(occupant || !isliving(bumped_atom))
		return

	var/is_droid = istype(bumped_atom, /mob/living/basic/droid)

	if(is_droid && type != /mob/living/basic/droid)
		if(COOLDOWN_FINISHED(src, buzz_cooldown))
			playsound(src, 'sound/machines/buzz-sigh.ogg', vol = 75, vary = FALSE)
			COOLDOWN_START(src, buzz_cooldown, 1 SECOND)
		return

	var/dir = get_dir(bumped_atom, src)
	if(dir != EAST && dir != WEST)
		return

	output_dir = dir

	set_occupant(bumped_atom)
	bumped_atom.forceMove(src)

	addtimer(CALLBACK(src, PROC_REF(release_occupant)), is_droid ? 10 SECONDS : 3 SECONDS, TIMER_DELETE_ME | TIMER_UNIQUE)

	if(is_droid)
		return

	begin_processing() // Oh you poor fucking soul.

	bumped_atom.visible_message(
		message = span_bolddanger("[bumped_atom] gets sucked into [src]!"),
		self_message = span_userdanger("You're sucked into [src]!"),
		blind_message = span_hear("You hear a clang!")
	)

/obj/machinery/basic_weapon_fitter/set_occupant(atom/movable/new_occupant)
	. = ..()
	if(new_occupant)
		sound_loop.start()
	else
		sound_loop.stop()
		end_processing()
	if(!QDELETED(src))
		update_appearance()

/obj/machinery/basic_weapon_fitter/process(seconds_per_tick)
	var/mob/living/victim = occupant
	victim.take_bodypart_damage(burn = 45 * seconds_per_tick, wound_bonus = 40)

/obj/machinery/basic_weapon_fitter/proc/release_occupant()
	occupant?.forceMove(get_step(get_turf(src), output_dir))
	set_occupant(null)
