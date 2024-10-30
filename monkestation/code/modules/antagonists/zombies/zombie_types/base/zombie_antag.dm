#define ZOMBIE_FLESH_MAXIMUM 500

/// This is a very temporary antag datum for infectious zombies and you should never store any state in it.
/datum/antagonist/zombie
	name = "\improper Zombie"
	roundend_category = "zombies"
	antagpanel_category = ANTAG_GROUP_BIOHAZARDS
	job_rank = ROLE_ZOMBIE
	//antag_hud_name = "zombie"
	antag_moodlet = /datum/mood_event/zombie
	suicide_cry = "BRRRAAAAINZZ!!"
	show_to_ghosts = TRUE

/datum/antagonist/zombie/apply_innate_effects(mob/living/mob_override)
	var/mob/living/carbon/user = mob_override || owner.current

	if(!istype(user)) // Zombies don't change anything about non-carbon mobs.
		return

	if(!isinfectious(user))
		user.set_species(/datum/species/zombie/infectious)

	RegisterSignal(user, COMSIG_SPECIES_LOSS, PROC_REF(self_destruct))
	RegisterSignal(owner, COMSIG_MIND_TRANSFERRED, PROC_REF(self_destruct))

/datum/antagonist/zombie/remove_innate_effects(mob/living/mob_override)
	var/mob/living/carbon/user = mob_override || owner.current

	if(!istype(user)) // Zombies don't change anything about non-carbon mobs.
		return

	UnregisterSignal(user, COMSIG_SPECIES_LOSS)
	UnregisterSignal(owner, COMSIG_MIND_TRANSFERRED)

/// The essential proc to call when our owner is no longer controlling a zombie.
/datum/antagonist/zombie/proc/self_destruct()
	SIGNAL_HANDLER
	qdel(src)

/datum/action/cooldown/zombie
	name = "Zombie Action"
	desc = "You should not be seeing this."
	background_icon = 'monkestation/icons/mob/actions/actions_zombie.dmi'
	button_icon = 'monkestation/icons/mob/actions/actions_zombie.dmi'
	background_icon_state = "bg_zombie"
	check_flags = AB_CHECK_IMMOBILE | AB_CHECK_CONSCIOUS

	/// A reference to the zombie species datum. Automatically cleaned up.
	var/datum/species/zombie/infectious/zombie_datum

	/// The amount of flesh required to use this ability. You can custom code this if you want to due to its simplicity, just remember to register the update signal.
	/// Does not actually use up the consumed flesh on its own. Do that yourself in Activate() or wherever else you want to.
	var/flesh_cost = 0

/datum/action/cooldown/zombie/New(Target, original)
	if(!istype(Target, /datum/species/zombie/infectious))
		CRASH("A zombie action was not linked to a species datum. This should never happen, please report it.")
	zombie_datum = Target
	return ..()

/datum/action/cooldown/zombie/Destroy()
	zombie_datum = null
	return ..()

/datum/action/cooldown/zombie/Grant(mob/granted_to)
	if(flesh_cost > 0)
		RegisterSignal(zombie_datum, COMSIG_ZOMBIE_FLESH_CHANGED, PROC_REF(update_button))
	return ..()

/datum/action/cooldown/zombie/Remove(mob/removed_from)
	UnregisterSignal(zombie_datum, COMSIG_ZOMBIE_FLESH_CHANGED)
	return ..()

/datum/action/cooldown/zombie/IsAvailable(feedback)
	if(!..())
		return FALSE

	if(zombie_datum.consumed_flesh >= flesh_cost)
		if(feedback)
			owner.balloon_alert(owner, "needs [zombie_datum.consumed_flesh - flesh_cost] more flesh!")
		return FALSE

	return TRUE

/// Shortcut for "build_all_button_icons(UPDATE_BUTTON_STATUS)", used by signals.
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

	if(iszombie(target)) // Zombies can't cannibalize one another as their flesh is worthless.
		owner.balloon_alert(owner, "[target.p_they()] [target.p_are()] a zombie!")

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
			carbon_target.apply_damage(25, BRUTE, pick(carbon_target.bodyparts), forced = TRUE, wound_bonus = CANT_WOUND, sharpness = SHARP_EDGED, attack_direction = get_dir(owner, target))
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
