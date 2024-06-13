/mob/living/basic/skeleton_gem
	name = "Skeleton Gem"
	desc = "An ancient artifact, your bones shiver from even glancing at it."

	icon = 'monkestation/icons/obj/skeleton_gem.dmi'
	icon_state = "gem"
	icon_living = "gem"
	icon_dead = "gem"

	mob_size = MOB_SIZE_HUGE // no, you cannot put it in a closet, sorry

	status_flags = GODMODE

	maxHealth = INFINITY
	health = INFINITY

	speed = 0.5

	mob_biotypes = BIO_INORGANIC

	unsuitable_atmos_damage = 0
	minimum_survivable_temperature = 0
	maximum_survivable_temperature = INFINITY

	obj_damage = INFINITY // NOTHING CAN STOP ME!!
	move_force = INFINITY
	pull_force = INFINITY
	pressure_resistance = INFINITY // accidentally widening a breach 5 times is bad

	lighting_cutoff_red = 50 // of course it has night vision
	lighting_cutoff_green = 30
	lighting_cutoff_blue = 30

	damage_coeff = list(BRUTE = 0, BURN = 0, TOX = 0, CLONE = 0, STAMINA = 0, OXY = 0)

/mob/living/basic/skeleton_gem/Initialize(mapload)
	. = ..()

	AddComponent(/datum/component/unobserved_actor, unobserved_flags = NO_OBSERVED_MOVEMENT)
	AddComponent(/datum/component/stationloving, FALSE, TRUE)

	AddElement(/datum/element/forced_gravity, TRUE)
	AddElement(/datum/element/simple_flying)

	ADD_TRAIT(src, TRAIT_UNOBSERVANT, INNATE_TRAIT)
	ADD_TRAIT(src, TRAIT_FREE_HYPERSPACE_MOVEMENT, INNATE_TRAIT)

	set_light(
		l_outer_range = 5,
		l_power = 2,
		l_color = COLOR_VOID_PURPLE
	)

/mob/living/basic/skeleton_gem/examine(mob/user)
	. = ..()
	if(!isskeleton(user))
		. += span_bolddanger("You might want to keep this out of the skeleton's hands...")
	else if(!IS_WIZARD(user))
		. += span_boldnotice("You're so close! Just a touch away from ascension!")
	else
		. += span_boldnotice("[p_they()] [p_have()] acknowledged you.")

/mob/living/basic/skeleton_gem/resolve_unarmed_attack(atom/attack_target, list/modifiers)

/mob/living/basic/skeleton_gem/attack_hand(mob/living/carbon/human/user, list/modifiers)
	if(!isskeleton(user))
		user.visible_message(
			message = span_danger("\The [src] flashes a bright purple as [user] is thrown away!"),
			self_message = span_userdanger("\The [src] rejects you!"),
			blind_message = span_hear("You hear a pop!")
		)
		user.adjustBruteLoss(50)
		playsound(src, 'sound/effects/pop_expl.ogg', 100, TRUE)
		var/atom/throw_target = get_edge_target_turf(user, get_dir(user, get_step_away(user, src)))
		user.throw_at(throw_target, 10, 3) // THE CANNON
		return

	if(IS_WIZARD(user))
		balloon_alert(user, "already ascended!")
		return

	user.visible_message(
		message = span_danger("[user] puts [user.p_their()] hand on \the [src]!"),
		self_message = span_boldnotice("You put your hand on \the [src] and it's power begins flowing into you!"),
		blind_message = span_hear("You hear something ominous.")
	)

	playsound(src, 'sound/effects/curse3.ogg', 100, TRUE)

	if(!do_after(user, 3 SECONDS, src, timed_action_flags = IGNORE_SLOWDOWNS))
		return

	if(IS_WIZARD(user)) // sanity my beloved
		return

	user.mind.set_assigned_role(SSjob.GetJobType(/datum/job/space_wizard))
	user.mind.special_role = ROLE_WIZARD
	var/datum/antagonist/wizard/wizard = user.mind.add_antag_datum(/datum/antagonist/wizard/gem)
	if(!wizard)
		return

	user.visible_message(
		message = span_danger("\The [src] flashes a bright purple as [user] dissipates into a fine mist!"),
		self_message = span_boldnotice("\The [src] acknowledges you!"),
		blind_message = span_hear("You hear a whoosh.")
	)

	AddComponent(/datum/component/phylactery/gem, user.mind, 1 MINUTE, 0, 0, COLOR_WHITE)
	name = initial(name) // phylactery causes us to become "ensouled" and we don't want that

	user.set_species(/datum/species/skeleton)

	var/obj/item/organ/internal/brain/lich_brain = user.get_organ_slot(ORGAN_SLOT_BRAIN)
	if(lich_brain)
		lich_brain.organ_flags &= ~ORGAN_VITAL
		lich_brain.decoy_override = TRUE

	qdel(user.w_uniform)
	qdel(user.wear_suit)
	qdel(user.head)

	user.equip_to_slot_or_del(new /obj/item/clothing/suit/wizrobe/black(user), ITEM_SLOT_OCLOTHING)
	user.equip_to_slot_or_del(new /obj/item/clothing/head/wizard/black(user), ITEM_SLOT_HEAD)
	user.equip_to_slot_or_del(new /obj/item/clothing/under/color/black(user), ITEM_SLOT_ICLOTHING)

	ADD_TRAIT(user, TRAIT_NO_SOUL, LICH_TRAIT)

/datum/component/phylactery/gem
	dupe_mode = COMPONENT_DUPE_ALLOWED

/datum/component/phylactery/gem/on_examine(datum/source, mob/user, list/examine_list)
	return

/datum/antagonist/wizard/gem
	antag_moodlet = /datum/mood_event/gem
	allow_rename = FALSE

/datum/antagonist/wizard/gem/create_objectives()
	var/datum/objective/gem/objective = new()
	objectives += objective

/datum/antagonist/wizard/gem/assign_ritual()

/datum/objective/gem
	name = "skeleton gem"
	completed = TRUE // if you don't complete this, you get erased

/datum/objective/gem/update_explanation_text()
	return "Protect the almighty Skeleton Gem and wreak havoc upon the fleshbags!"
