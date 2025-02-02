/datum/antagonist/vampire
	name = "\improper Vampire"
	roundend_category = "vampires"
	antagpanel_category = ANTAG_GROUP_VAMPIRES
	job_rank = ROLE_VAMPIRE
	show_to_ghosts = FALSE
	antag_moodlet = /datum/mood_event/focused

	/// A reference to our current mob. Can be null.
	var/mob/living/carbon/human/user = null

/datum/antagonist/vampire/greet()
	. = ..()
	owner.current?.playsound_local(get_turf(owner.current), 'monkestation/sound/vampires/vampire_alert.ogg', vol = 100, vary = FALSE)

/datum/antagonist/vampire/on_gain()
	for (var/action_type in current_abilities)
		grant_ability(action_type) // This will initialize the actions.
	. = ..()
	teach_recipes()

/datum/antagonist/vampire/on_removal()
	forget_recipes()
	return ..()

/datum/antagonist/vampire/apply_innate_effects(mob/living/mob_override)
	. = ..()
	var/mob/living/target = mob_override || owner.current

	if (!ishuman(target))
		return

	user = target

	set_lifeforce(user.blood_volume * BLOOD_TO_LIFEFORCE) // Just in case, do this before we add TRAIT_NOBLOOD to our mob.

	user.add_traits(innate_traits, REF(src))

	set_masquerade(masquerade_enabled, forced = TRUE, silent = masquerade_enabled)

	START_PROCESSING(SSprocessing, src)

	if (user.hud_used)
		create_hud()
	else
		RegisterSignal(user, COMSIG_MOB_HUD_CREATED, PROC_REF(create_hud))

	grant_abilities()

/datum/antagonist/vampire/remove_innate_effects(mob/living/mob_override)
	. = ..()
	if (!user)
		return

	remove_abilities()

	set_masquerade(TRUE) // This removes the elements added by not being in masquerade, leaving only traits.
	REMOVE_TRAITS_IN(user, REF(src)) // And this then clears the traits. This should also be after removing actions.

	user.blood_volume = current_lifeforce * LIFEFORCE_TO_BLOOD // This has to be after we've removed TRAIT_NOBLOOD from our mob.

	STOP_PROCESSING(SSprocessing, src)

	delete_hud()

	user = null

/// Turns the given target into a thrall subservient to us.
/datum/antagonist/vampire/proc/enthrall(mob/living/carbon/human/target)
	if (!istype(target) || !target.mind)
		return

	var/obj/item/organ/internal/flesh_bud/flesh_bud = new()

	flesh_bud.master_vampire = src
	flesh_bud.Insert(target, special = TRUE, drop_if_replaced = FALSE)
