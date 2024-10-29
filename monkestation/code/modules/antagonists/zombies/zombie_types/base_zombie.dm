//I would like to convert these to their own datum type but I have like 2 hours so this is what we are getting
/datum/species/zombie/infectious
	///the path of mutant hands to give this zombie
	var/obj/item/mutant_hand/zombie/hand_path = /obj/item/mutant_hand/zombie
	///How much flesh have we consumed, we need 200 to evolve
	var/consumed_flesh = 0
	///the list of action types to give on gain
	var/list/granted_action_types = list(/datum/action/innate/zombie/feast)
	///the list of action instances we have actually granted
	var/list/granted_actions = list()

/datum/action/innate/zombie
	name = "Zombie Action"
	desc = "You should not be seeing this."
	check_flags = AB_CHECK_IMMOBILE|AB_CHECK_CONSCIOUS
	click_action = TRUE

/datum/action/innate/zombie/do_ability(mob/living/user, atom/clicked_on)
	if(!iszombie(user))
		unset_ranged_ability(user)
		CRASH("[src.type] being used by a non zombie, something has broken.")
	return TRUE

/datum/action/innate/zombie/feast
	name = "Feast"
	desc = "Feast on a corpse's flesh."
	button_icon = 'icons/effects/blood.dmi'
	button_icon_state = "bloodhand_left"

/datum/action/innate/zombie/feast/do_ability(mob/living/user, atom/clicked_on)
	. = ..()
	if(!.)
		return

	var/mob/living/living_clicked_on = clicked_on
	if(!istype(living_clicked_on))
		return FALSE

	if(living_clicked_on.stat != DEAD)
		to_chat(user, span_notice("[living_clicked_on] is not dead!"))
		return FALSE

	if(!HAS_TRAIT(living_clicked_on, TRAIT_ZOMBIE_CONSUMED))
		to_chat(user, span_notice("[living_clicked_on] has already had their flesh consumed."))
		return FALSE

	ADD_TRAIT(living_clicked_on, TRAIT_ZOMBIE_CONSUMED, ZOMBIE_TRAIT)
	var/hp_gained = living_clicked_on.maxHealth
	user.adjustBruteLoss(-hp_gained, 0)
	user.adjustToxLoss(-hp_gained, 0)
	user.adjustFireLoss(-hp_gained, 0)
	user.adjustCloneLoss(-hp_gained, 0)
	user.updatehealth()
	user.adjustOrganLoss(ORGAN_SLOT_BRAIN, -hp_gained)
	user.set_nutrition(min(user.nutrition + hp_gained, NUTRITION_LEVEL_FULL))
	if(iscarbon(user))
		var/mob/living/carbon/carbon_user = user
		var/datum/species/zombie/infectious/zombie_datum = carbon_user.dna.species
		zombie_datum.consumed_flesh += hp_gained

//UNIMPLEMENTED
///evolve into a special zombie, needs at least 200 total consumed flesh
/datum/action/innate/zombie/evolve
	click_action = FALSE
