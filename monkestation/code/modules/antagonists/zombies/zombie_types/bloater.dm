//UNIMPLEMENTED
//explodes on death, blinding(and damaging?) nearby non zombies
/datum/species/zombie/infectious/bloater
	name = "Bloater Zombie"
	bodypart_overlay_icon_states = list(BODY_ZONE_CHEST = "bloater-chest")
	granted_action_types = list(
		/datum/action/cooldown/zombie/feast,
		/datum/action/cooldown/zombie/melt_wall,
		/datum/action/cooldown/zombie/explode,
	)

/datum/species/zombie/infectious/bloater/on_species_gain(mob/living/carbon/C, datum/species/old_species)
	. = ..()
	RegisterSignal(C, COMSIG_LIVING_DEATH, PROC_REF(on_death))

/datum/species/zombie/infectious/bloater/on_species_loss(mob/living/carbon/human/C, datum/species/new_species, pref_load)
	. = ..()
	UnregisterSignal(C, COMSIG_LIVING_DEATH)

/datum/species/zombie/infectious/bloater/proc/on_death(mob/living/carbon/user, gibbed)
	SIGNAL_HANDLER

	if(gibbed || QDELETED(user)) // Congratulations, you've defused the bomb.
		return

	user.visible_message(
		message = span_danger("[user] bursts apart into a violent shower of infectious gibs!"),
		self_message = span_userdanger("You burst apart!"),
		blind_message = span_hear("You hear squelching and tearing as your eardrums are assaulted by noise!"),
	)

	var/infects = 0

	for(var/mob/living/carbon/infectee in oview(4, user))
		to_chat(infectee, span_userdanger("Some of the gibs flew onto you!"))

		var/datum/client_colour/colour = infectee.add_client_colour(/datum/client_colour/bloodlust)
		QDEL_IN(colour, 1.1 SECONDS)

		if(!prob(20 + 80 / get_dist(user, infectee))) // A minimum of a 40% chance to infect.
			return

		var/obj/item/organ/internal/zombie_infection/infection
		infection = infectee.get_organ_slot(ORGAN_SLOT_ZOMBIE)
		if(!infection)
			infection = new()
			infection.Insert(infectee)

		infects++

	to_chat(user, span_alien("In your final moments, you managed to infect [infects] people."))

	user.gib(no_brain = TRUE, no_organs = TRUE, no_bodyparts = TRUE, safe_gib = FALSE)

	explosion(user, devastation_range = 1, heavy_impact_range = 2, light_impact_range = 4)

/datum/action/cooldown/zombie/melt_wall/corrosion
	name = "Stomach Acid"
	desc = "Drench an object in stomach acid, destroying it over time."
	button_icon_state = "alien_acid"
	background_icon_state = "bg_zombie"
	overlay_icon_state = "bg_zombie_border"
	button_icon = 'icons/mob/actions/actions_xeno.dmi'
	cooldown_time = 10

/datum/action/cooldown/zombie/melt_wall/set_click_ability(mob/on_who)
	. = ..()
	if(!.)
		return

	to_chat(on_who, span_notice("You prepare to vomit. <b>Click a target to puke on it!</b>"))
	on_who.update_icons()

/datum/action/cooldown/zombie/melt_wall/unset_click_ability(mob/on_who, refund_cooldown = TRUE)
	. = ..()
	if(!.)
		return

	if(refund_cooldown)
		to_chat(on_who, span_notice("You empty your mouth."))
	on_who.update_icons()

/datum/action/cooldown/zombie/melt_wall/PreActivate(atom/target)
	if(get_dist(owner, target) > 1)
		return FALSE
	if(ismob(target)) //If it could corrode mobs, it would one-shot them.
		owner.balloon_alert(owner, "doesn't work on mobs!")
		return FALSE

	return ..()

/datum/action/cooldown/zombie/melt_wall/Activate(atom/target)
	if(!target.acid_act(200, 1000))
		to_chat(owner, span_notice("You cannot dissolve this object."))
		return FALSE

	owner.visible_message(
		span_alert("[owner] vomits globs of vile stuff all over [target]. It begins to sizzle and melt under the bubbling mess of acid!"),
		span_notice("You vomit globs of acid over [target]. It begins to sizzle and melt."),
	)
	return TRUE

/datum/action/cooldown/zombie/explode
	name = "Explode"
	desc = "Trigger the explosive cocktail residing in your body, causing a devastating explosion. Triggers automatically on death."
	check_flags = NONE

/datum/action/cooldown/zombie/explode/Activate(atom/target)
	. = ..()
	var/mob/living/user = owner
	user.death() // lol
