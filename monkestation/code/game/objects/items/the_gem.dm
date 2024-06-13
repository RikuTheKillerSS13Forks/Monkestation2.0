/mob/living/basic/the_gem
	name = "\proper Skeleton Gem"
	desc = "An ancient artifact, your bones shiver from even glancing at it. Rumors say it disappears when you least expect it..."

	icon = 'monkestation/icons/obj/skeleton_gem.dmi'
	icon_state = "gem"

	maxHealth = INFINITY
	health = INFINITY

	mob_biotypes = BIO_INORGANIC

	unsuitable_atmos_damage = 0
	minimum_survivable_temperature = 0
	maximum_survivable_temperature = INFINITY

	move_force = MOVE_FORCE_OVERPOWERING // NOTHING CAN STOP ME!!
	pull_force = MOVE_FORCE_OVERPOWERING

	lighting_cutoff_red = 50 // of course it has night vision
	lighting_cutoff_green = 30
	lighting_cutoff_blue = 30

	damage_coeff = list(BRUTE = 0, BURN = 0, TOX = 0, CLONE = 0, STAMINA = 0, OXY = 0)

/mob/living/the_gem/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/unobserved_actor, unobserved_flags = NO_OBSERVED_MOVEMENT)
	ADD_TRAIT(src, TRAIT_UNOBSERVANT, INNATE_TRAIT)

/mob/living/the_gem/examine(mob/user)
	. = ..()
	if(!isskeleton(user))
		. += span_bolddanger("You might want to keep this out of the skeleton's hands...")
	else if(!IS_WIZARD(user))
		. += span_boldnotice("You're so close! Touch the gem to ascend!")

/mob/living/the_gem/attack_hand(mob/living/carbon/human/user, list/modifiers)
	. = ..()

	if(!isskeleton(user))
		user.visible_message(
			message = span_danger("\The [src] flashes a bright purple as [user] is thrown away!"),
			self_message = span_userdanger("\The [src] rejects you!"),
			blind_message = span_hear("You hear a crash!")
		)
		user.adjustBruteLoss(50)
		user.reagents.add_reagent(/datum/reagent/toxin/bonehurtingjuice, 10)
		playsound(src, 'sound/effects/pop_expl.ogg', 100, TRUE)
		var/atom/throw_target = get_edge_target_turf(user, get_dir(user, get_step_away(user, src)))
		user.throw_at(throw_target, 5, 2)
		return

	if(IS_WIZARD(user))
		balloon_alert(user, "already ascended!")
		return

	user.visible_message(
		message = span_danger("[user] puts [user.p_their()] hand on \the [src]!"),
		self_message = span_boldnotice("You put your hand on \the [src] and it's starts flowing into you!"),
		blind_message = span_hear("You hear something ominous.")
	)

	playsound(src, 'sound/effects/curse3.ogg', 100, TRUE)

	if(!do_after(user, 3 SECONDS, src, timed_action_flags = IGNORE_SLOWDOWNS))
		return
