/datum/wound_pregen_data/vampire_bite_mark
	wound_path_to_generate = /datum/wound/vampire_bite_mark
	can_be_randomly_generated = FALSE
	required_limb_biostate = BIO_FLESH
	required_wounding_types = list(WOUND_ALL)

/datum/wound/vampire_bite_mark
	name = "Vampiric Bite Wound"
	undiagnosed_name = "Bite Wound"

	desc = "Patient's skin has been pierced in 4 locations, in the pattern of a vampire's bite."
	treat_text = "Wait it out, apply gauze, suture it closed or cauterize it."
	examine_desc = "has a bite mark on it"

	treatable_by = list(/obj/item/stack/medical/suture, /obj/item/stack/medical/gauze)
	treatable_by_grabbed = list(/obj/item/gun/energy/laser)
	treatable_tools = list(TOOL_CAUTERY)
	base_treat_time = 1 SECOND

	severity = WOUND_SEVERITY_TRIVIAL
	wound_flags = NONE
	can_scar = FALSE
	processes = TRUE
	causes_pain = FALSE
	blood_flow = 0.5

	var/time_until_cured = 60

/datum/wound/vampire_bite_mark/get_bleed_rate_of_change()
	return BLOOD_FLOW_STEADY

/datum/wound/vampire_bite_mark/handle_process(seconds_per_tick, times_fired)
	. = ..()
	if (!victim || HAS_TRAIT(victim, TRAIT_STASIS) || victim.stat == DEAD || QDELETED(src))
		return

	time_until_cured -= seconds_per_tick
	if (time_until_cured <= 0)
		to_chat(victim, span_green("The bite wound on your [limb.plaintext_zone] has healed up."))
		qdel(src)

/datum/wound/slash/flesh/check_grab_treatments(obj/item/I, mob/user)
	if(istype(I, /obj/item/gun/energy/laser))
		return TRUE
	if(I.get_temperature()) // Makes sure we don't try to treat wounds instead of attacking with our esword.
		return TRUE

/datum/wound/vampire_bite_mark/treat(obj/item/I, mob/user)
	if (istype(I, /obj/item/stack/medical/gauze))
		handle_gauze(I, user)
	if (istype(I, /obj/item/stack/medical/suture))
		handle_suture(I, user)
	if (istype(I, /obj/item/gun/energy/laser))
		handle_laser(I, user)
	if (I.tool_behaviour == TOOL_CAUTERY || I.get_temperature())
		handle_cautery(I, user)
	return TRUE

/datum/wound/vampire_bite_mark/proc/handle_gauze(obj/item/I, mob/user)
	user.visible_message(
		message = span_notice("[user] starts placing a patch of gauze over the bite mark on [victim]'s [limb.plaintext_zone]."),
		self_message = span_notice("You start placing a patch of gauze over the bite mark on [user == victim ? "your" : "[victim]'s"] [limb.plaintext_zone]."),
	)

	if (!do_after(user, base_treat_time, victim, extra_checks = CALLBACK(src, PROC_REF(still_exists))))
		return

	I.use(1)
	user.visible_message(
		message = span_notice("[user] finishes placing a patch of gauze over the bite mark on [victim]'s [limb.plaintext_zone]."),
		self_message = span_notice("You finish placing a patch of gauze over the bite mark on [user == victim ? "your" : "[victim]'s"] [limb.plaintext_zone]."),
	)

	qdel(src)

/datum/wound/vampire_bite_mark/proc/handle_suture(obj/item/I, mob/user)
	user.visible_message(
		message = span_notice("[user] starts suturing the bite mark on [victim]'s [limb.plaintext_zone]."),
		self_message = span_notice("You start suturing the bite mark on [user == victim ? "your" : "[victim]'s"] [limb.plaintext_zone]."),
	)

	if (!do_after(user, base_treat_time, victim, extra_checks = CALLBACK(src, PROC_REF(still_exists))))
		return

	I.use(1)
	user.visible_message(
		message = span_notice("[user] finishes suturing the bite mark on [victim]'s [limb.plaintext_zone]."),
		self_message = span_notice("You finish suturing the bite mark on [user == victim ? "your" : "[victim]'s"] [limb.plaintext_zone]."),
	)

	qdel(src)

/datum/wound/vampire_bite_mark/proc/handle_laser(obj/item/gun/energy/laser/laser, mob/user)
	user.visible_message(
		message = span_warning("[user] starts aiming [laser] directly at the bite mark on [victim]'s [limb.plaintext_zone]."),
		self_message = span_userdanger("You start aiming [laser] directly at the bite mark on [user == victim ? "your" : "[victim]'s"] [limb.plaintext_zone]."),
	)

	if (!do_after(user, base_treat_time, victim, extra_checks = CALLBACK(src, PROC_REF(still_exists))))
		return

	laser.chambered?.loaded_projectile?.wound_bonus -= 30
	if(!laser.process_fire(victim, user, zone_override = limb.body_zone))
		return

	user.emote("scream")
	victim.visible_message(
		message = span_warning("The bite mark on [victim]'s [limb.plaintext_zone] scars over!"),
		self_message = span_warning("The bite mark on your [limb.plaintext_zone] scars over!"),
	)

	qdel(src)

/datum/wound/vampire_bite_mark/proc/handle_cautery(obj/item/I, mob/user)
	user.visible_message(
		message = span_notice("[user] starts cauterizing the bite mark on [victim]'s [limb.plaintext_zone]."),
		self_message = span_notice("You start cauterizing the bite mark on [user == victim ? "your" : "[victim]'s"] [limb.plaintext_zone]."),
	)

	if (!do_after(user, base_treat_time, victim, extra_checks = CALLBACK(src, PROC_REF(still_exists))))
		return

	limb.receive_damage(burn = 2, wound_bonus = CANT_WOUND)
	user.visible_message(
		message = span_notice("[user] finishes cauterizing the bite mark on [victim]'s [limb.plaintext_zone]."),
		self_message = span_notice("You finish cauterizing the bite mark on [user == victim ? "your" : "[victim]'s"] [limb.plaintext_zone]."),
	)

	if(prob(30))
		victim.emote("scream")

	qdel(src)
