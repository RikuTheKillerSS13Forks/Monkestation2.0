#define ZOMBIE_FLESH_MAXIMUM 500

/datum/antagonist/zombie
	name = "\improper Zombie"
	roundend_category = "zombies"
	antagpanel_category = ANTAG_GROUP_BIOHAZARDS
	job_rank = ROLE_ZOMBIE
	//antag_hud_name = "zombie"
	antag_moodlet = /datum/mood_event/zombie
	suicide_cry = "BRRRAAAAINZZ!!"
	show_to_ghosts = TRUE

	/// Typepath for the species our mob should become.
	var/species_type = /datum/species/zombie/infectious

	/// Typepath for the species our mob was before they were zombified.
	var/old_species_type = null

	/// Typepath for the mutant hands to grant our mob.
	var/mutant_hand_type = /obj/item/mutant_hand/zombie

	/// List of action types to grant during init and instances of those actions during runtime.
	var/list/granted_actions = list(
		/datum/action/cooldown/zombie/feast,
		/datum/action/cooldown/zombie/evolve,
	)

	/// How much flesh we've consumed. Used for abilities. Don't modify directly.
	var/consumed_flesh = 0

/datum/antagonist/zombie/on_gain()
	var/list/granted_action_types = granted_actions.Copy()
	granted_actions.Cut() // No reason to use list removal if we can clear it instead.

	for(var/action_type as anything in granted_action_types)
		granted_actions += new action_type(src) // Passing ourselves to the action links it to us, making it self-destruct if the antag datum is lost for any reason.

	return ..() // Call order is important here as apply_innate_effects has to run after the actions are created.

/datum/antagonist/zombie/on_removal()
	. = ..() // Ditto for remove_innate_effects since it removes the actions.
	granted_actions = null

/datum/antagonist/zombie/apply_innate_effects(mob/living/mob_override)
	var/mob/living/carbon/user = mob_override || owner.current

	if(!istype(user)) // Zombies don't change anything about non-carbon mobs.
		return

	old_species_type = user.dna.species.type

	if(!is_species(user, species_type))
		user.set_species(species_type)

	for(var/datum/action/action as anything in granted_actions)
		action.Grant(user)

	RegisterSignal(user, COMSIG_SPECIES_LOSS, PROC_REF(on_species_loss))

/datum/antagonist/zombie/remove_innate_effects(mob/living/mob_override)
	var/mob/living/carbon/user = mob_override || owner.current

	if(!istype(user)) // Zombies don't change anything about non-carbon mobs.
		return

	if(old_species_type && !QDELETED(user) && is_species(user, species_type))
		user.set_species(old_species_type)

	for(var/datum/action/action as anything in granted_actions)
		action.Remove(user)

	UnregisterSignal(user, COMSIG_SPECIES_LOSS)

/datum/antagonist/zombie/proc/on_species_loss()
	SIGNAL_HANDLER
	qdel(src) // Keep in mind, this does not delete the zombie infection organ, so you'll be reinfected shortly.

/datum/antagonist/zombie/proc/set_consumed_flesh(amount)
	var/old_amount = consumed_flesh
	consumed_flesh = clamp(amount, 0, ZOMBIE_FLESH_MAXIMUM)

	if(consumed_flesh != old_amount)
		update_consumed_flesh(old_amount)

/datum/antagonist/zombie/proc/adjust_consumed_flesh(amount)
	set_consumed_flesh(consumed_flesh + amount)

/datum/antagonist/zombie/proc/update_consumed_flesh(old_amount)
	SEND_SIGNAL(owner.current, COMSIG_ZOMBIE_FLESH_CHANGED, old_amount, consumed_flesh)

/datum/action/cooldown/zombie
	name = "Zombie Action"
	desc = "You should not be seeing this."
	background_icon = 'monkestation/icons/mob/actions/actions_zombie.dmi'
	button_icon = 'monkestation/icons/mob/actions/actions_zombie.dmi'
	background_icon_state = "bg_zombie"
	check_flags = AB_CHECK_IMMOBILE|AB_CHECK_CONSCIOUS

/datum/action/cooldown/zombie/IsAvailable(feedback)
	if(!iszombie(owner))
		CRASH("A non-zombie tried to use a zombie action, it seems the game has taken too much LSD today. (report this shit)")
	return ..()

/datum/action/cooldown/zombie/PreActivate(atom/target)
	// Parent calls Activate(), so if parent returns TRUE,
	// it means the activation happened successfuly by this point
	. = ..()
	if(!.)
		return FALSE
	// Xeno actions like "evolve" may result in our action (or our alien) being deleted
	// In that case, we can just exit now as a "success"
	if(QDELETED(src) || QDELETED(owner))
		return TRUE


/datum/action/cooldown/zombie/proc/update_button()
	SIGNAL_HANDLER
	build_all_button_icons(UPDATE_BUTTON_STATUS)

/datum/action/cooldown/zombie/feast
	name = "Feast"
	desc = "Consume the flesh of the fallen ones."
	button_icon_state = "feast"
	ranged_mousepointer = 'monkestation/icons/effects/mouse_pointers/feast.dmi'
	click_to_activate = TRUE
	cooldown_time = 5 SECONDS

/datum/action/cooldown/zombie/feast/Activate(mob/living/target)
	if(target == owner) // Don't eat yourself, dumbass.
		return TRUE

	if(!istype(target))
		return TRUE

	if(!owner.Adjacent(target))
		owner.balloon_alert(owner, "get closer!")
		return TRUE

	if(target.stat != DEAD)
		owner.balloon_alert(owner, "[target.p_they()] [target.p_are()] alive!")
		return TRUE

	if(HAS_TRAIT(target, TRAIT_ZOMBIE_CONSUMED))
		owner.balloon_alert(owner, "already consumed!")
		return TRUE

	for(var/i in 1 to 4)
		if(!do_after(owner, 0.5 SECONDS, target, timed_action_flags = IGNORE_HELD_ITEM | IGNORE_SLOWDOWNS))
			owner.balloon_alert(owner, "interrupted!")
			return TRUE
		playsound(owner, 'sound/items/eatfood.ogg', vol = 80, vary = TRUE) // Om nom nom, good flesh.

		if(iscarbon(target))
			var/mob/living/carbon/carbon_target = target
			carbon_target.apply_damage(25, BRUTE, pick(carbon_target.bodyparts), forced = TRUE, wound_bonus = 10, sharpness = SHARP_EDGED, attack_direction = get_dir(owner, target))
		else
			playsound(target, 'sound/effects/wounds/blood2.ogg', vol = 50, vary = TRUE)
			target.adjustBruteLoss(25)

	ADD_TRAIT(target, TRAIT_ZOMBIE_CONSUMED, ZOMBIE_TRAIT)

	var/mob/living/carbon/user = owner

	var/healing = target.maxHealth // Bigger kills give more health, most simple mobs will be worth far less than a carbon.
	var/needs_update = FALSE // Optimization, if nothing changes then don't update our owner's health.
	needs_update += user.adjustBruteLoss(-healing, updating_health = FALSE)
	needs_update += user.adjustFireLoss(-healing, updating_health = FALSE)
	needs_update += user.adjustToxLoss(-healing, updating_health = FALSE)
	needs_update += user.adjustOxyLoss(-healing, updating_health = FALSE)

	if(needs_update)
		user.updatehealth()

	user.adjustOrganLoss(ORGAN_SLOT_BRAIN, -healing)
	user.set_nutrition(min(user.nutrition + healing, NUTRITION_LEVEL_FULL)) // Doesn't use adjust_nutrition since that would make the zombies fat.

	var/datum/species/zombie/infectious/zombie_datum = user.dna.species
	zombie_datum.consumed_flesh += healing

	..()

	return TRUE

/// Evolve into a special zombie, needs at least FLESH_REQUIRED_TO_EVOLVE consumed flesh.
/datum/action/cooldown/zombie/evolve
	name = "Evolve"
	desc = "Mutate into something even more grotesque and powerful. You must consume the flesh of the dead beforehand."
	button_icon_state = "evolve"

/datum/action/cooldown/zombie/evolve/Grant(mob/granted_to)
	. = ..()
	RegisterSignal(granted_to, COMSIG_ZOMBIE_FLESH_CHANGED, PROC_REF(update_button))

/datum/action/cooldown/zombie/evolve/Remove(mob/removed_from)
	. = ..()
	UnregisterSignal(removed_from, COMSIG_ZOMBIE_FLESH_CHANGED)

/datum/action/cooldown/zombie/evolve/IsAvailable(feedback)
	if(!..())
		return FALSE

	var/mob/living/carbon/user = owner
	var/datum/species/zombie/infectious/zombie_datum = user.dna.species

	if(zombie_datum.consumed_flesh < 200)
		if(feedback)
			user.balloon_alert(user, "needs [ceil(200 - zombie_datum.consumed_flesh)] more flesh!")
		return FALSE

	return TRUE

/datum/action/cooldown/zombie/evolve/Activate(atom/target)
	. = ..()

	var/mob/living/carbon/user = owner

	var/datum/species/picked = show_radial_menu(user, user, subtypesof(/datum/species/zombie/infectious))

	if(!picked)
		return

	user.set_species(picked)

	user.visible_message(
		message = span_danger("[user]'s flesh shifts, tears and changes, giving way to something even more dangerous!"),
		self_message = span_alien("Your flesh shifts, tears and changes as you transform into a [lowertext(initial(picked.name))]!"),
		blind_message = span_hear("You hear a grotesque cacophony of flesh shifting and tearing!"),
	)

	playsound(user, 'sound/effects/blobattack.ogg', vol = 80, vary = TRUE)
