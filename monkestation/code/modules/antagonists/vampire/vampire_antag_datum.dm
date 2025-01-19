/datum/antagonist/vampire
	name = "\improper Vampire"
	roundend_category = "vampires"
	antagpanel_category = ANTAG_GROUP_VAMPIRES
	job_rank = ROLE_VAMPIRE
	show_to_ghosts = FALSE
	antag_moodlet = /datum/mood_event/focused

	/// A reference to our current mob. Can be null.
	var/mob/living/carbon/human/user = null

	/// Traits that vampires always have.
	var/static/list/innate_traits = list(
		TRAIT_NOBLOOD,
		TRAIT_NOBREATH,
		TRAIT_STABLEHEART,
		TRAIT_GENELESS,
		TRAIT_ANALGESIA,
		TRAIT_ABATES_SHOCK,
		TRAIT_NO_PAIN_EFFECTS,
		TRAIT_NO_SHOCK_BUILDUP,
		TRAIT_NOCRITDAMAGE,
		TRAIT_RESISTCOLD,
		TRAIT_NO_ORGAN_DECAY,
	)

	/// Traits that vampires only have while out of masquerade.
	var/static/list/visible_traits = list(
		TRAIT_NO_MIRROR_REFLECTION, // add cold blooded here later
	)

	/// Traits that vampires only have while in masquerade.
	var/static/list/masquerade_traits = list(
		// add fake blood and fake genes here later
	)

/datum/antagonist/vampire/greet()
	. = ..()
	owner.current?.playsound_local(get_turf(owner.current), 'monkestation/sound/vampires/vampire_alert.ogg', vol = 100, vary = FALSE)

/datum/antagonist/vampire/apply_innate_effects(mob/living/mob_override)
	. = ..()
	var/mob/living/target = mob_override || owner.current

	if (!ishuman(target))
		return

	user = target

	set_lifeforce(user.blood_volume * BLOOD_TO_LIFEFORCE) // Just in case, do this before we add TRAIT_NOBLOOD to our mob.

	user.add_traits(innate_traits, REF(src))

	set_masquerade(masquerade_enabled, forced = TRUE)

	START_PROCESSING(SSprocessing, src)

	// ACTION TESTING CODE, REPLACE LATER
	var/datum/action/cooldown/vampire/regeneration/regeneration_action = new(src)
	regeneration_action.Grant(user)
	var/datum/action/cooldown/vampire/masquerade/masquerade_action = new(src)
	masquerade_action.Grant(user)

/datum/antagonist/vampire/remove_innate_effects(mob/living/mob_override)
	. = ..()
	var/mob/living/target = mob_override || owner.current

	if (!ishuman(target))
		return

	user = null

	REMOVE_TRAITS_IN(target, REF(src))

	target.blood_volume = current_lifeforce * LIFEFORCE_TO_BLOOD // This has to be after we've removed TRAIT_NOBLOOD from our mob.

	STOP_PROCESSING(SSprocessing, src)

/// Turns the given target into a thrall subservient to us.
/datum/antagonist/vampire/proc/enthrall(mob/living/carbon/human/target)
	if (!istype(target) || !target.mind)
		return

	var/obj/item/organ/internal/flesh_bud/flesh_bud = new()

	flesh_bud.master_vampire = src
	flesh_bud.Insert(target, special = TRUE, drop_if_replaced = FALSE)
