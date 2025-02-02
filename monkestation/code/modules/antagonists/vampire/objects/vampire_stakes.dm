/obj/item/stake
	name = "wooden stake"
	desc = "A simple wooden stake carved to a sharp point."

	icon = 'monkestation/icons/vampires/stakes.dmi'
	icon_state = "wood"

	inhand_icon_state = "wood"
	lefthand_file = 'monkestation/icons/vampires/vampire_leftinhand.dmi'
	righthand_file = 'monkestation/icons/vampires/vampire_rightinhand.dmi'

	w_class = WEIGHT_CLASS_NORMAL

	hitsound = 'sound/weapons/bladeslice.ogg'
	attack_verb_continuous = list("staked", "stabbed", "tore into")
	attack_verb_simple = list("stake", "stab", "tear into")

	sharpness = SHARP_POINTY
	embedding = list("embed_chance" = 20)

	force = 6
	throwforce = 10

	max_integrity = 30
	resistance_flags = FLAMMABLE

	/// The time it takes to embed the stake into someone's head.
	var/stake_time = 12 SECONDS

/obj/item/stake/examine(mob/user)
	. = ..()
	. += span_notice("If driven into the brain of a vampire, they will die permanently.")
	. += span_notice("The vampire must be immobilized in some way before you can put it in.")
	. += span_notice("To apply, target the correct limb, disable combat mode and click on them.")
	. += span_notice("Can also be applied to disembodied heads and even brains. Doing so is faster.")

/obj/item/stake/pre_attack(atom/A, mob/living/user, params)
	if (HAS_TRAIT(user, TRAIT_PACIFISM))
		return ..()
	if (user.istate & ISTATE_HARM) // So you can still hit with it normally. There are no ill effects to inverting this one, but it's consistent this way.
		return ..()
	if (!try_stake_alt(A, user))
		return ..()
	return TRUE

/obj/item/stake/attack(mob/living/target, mob/living/user, params)
	if (HAS_TRAIT(user, TRAIT_PACIFISM))
		return ..()
	if (user.istate & ISTATE_HARM) // So you can still hit with it normally, inverting this causes throat slicing to trigger if you try to neck grab and target head.
		return ..()
	if (target == user)
		return ..()
	if (!iscarbon(target))
		return ..()
	if (DOING_INTERACTION_WITH_TARGET(user, target)) // Don't spam please.
		return

	var/target_zone = check_zone(user.zone_selected)
	if (target_zone != BODY_ZONE_HEAD && target_zone != BODY_ZONE_CHEST)
		return

	var/obj/item/bodypart/target_bodypart = target.get_bodypart(target_zone)
	if (!target_bodypart)
		return ..()

	var/target_zone_name = target_bodypart.plaintext_zone

	if (target.mobility_flags & MOBILITY_MOVE) // There was a pierce immunity check here, but you could metagame the trait by decapping and then staking, so I removed it. It was also dumb to begin with.
		target.balloon_alert(user, "moving too much!")
		return

	target.balloon_alert(user, "staking...")
	user.visible_message(
		message = span_danger("[user] puts all [user.p_their()] weight into driving \the [src] into [target]'s [target_zone_name]!"),
		self_message = span_warning("You put all your weight into driving \the [src] into [target]'s [target_zone_name]!"),
		blind_message = span_hear("You hear sickening crunching!"),
		ignored_mobs = list(target),
	)
	target.show_message(
		msg = span_userdanger("[user] is trying to stake you in the [target_zone_name]!"), type = MSG_VISUAL,
		alt_msg = span_userdanger("You feel a sharp, agonizing pain in your [target_zone_name]!"),
	)
	playsound(target, 'sound/magic/demon_consume.ogg', vol = 50, vary = TRUE)

	if (!do_after(user, stake_time, target, extra_checks = CALLBACK(target, TYPE_PROC_REF(/mob/living/carbon, can_be_staked))))
		target.balloon_alert(user, "interrupted!")
		return

	target_bodypart = target.get_bodypart(target_zone)
	if (!target_bodypart)
		return

	user.visible_message(
		message = span_danger("[user] drives \the [src] into [target]'s [target_zone_name]!"),
		self_message = span_warning("You drive \the [src] into [target]'s [target_zone_name]!"),
		blind_message = span_hear("You hear a disgusting, wet splatter!"),
		ignored_mobs = list(target),
	)
	target.show_message(
		msg = span_userdanger("[user] stakes you in the [target_zone_name]!"), type = MSG_VISUAL,
		alt_msg = span_userdanger("The pain in your [target_zone_name] hits a breaking point!"),
	)
	playsound(get_turf(target), 'sound/effects/splat.ogg', vol = 40, vary = TRUE) // Use turf because the target might be about to go bye bye.

	if (tryEmbed(target_bodypart, forced = TRUE) != COMPONENT_EMBED_SUCCESS)
		return

	target.apply_damage(force * 10, BRUTE, target_zone, wound_bonus = 100, sharpness = sharpness, attack_direction = get_dir(user, target)) // YEOWCH

	var/obj/item/organ/target_brain = target.get_organ_slot(ORGAN_SLOT_BRAIN)
	if (!target_brain || check_zone(target_brain.zone) != target_zone)
		to_chat(user, span_warning("There was a lack of resistance in [target.p_their()] [target_zone_name]... wait, there was no brain inside!"))
		return // You really just staked someone in a non-vital spot. Congrats!

	if (!IS_VAMPIRE(target))
		target_brain.apply_organ_damage(target_brain.maxHealth) // You're shoving a giant, sharpened wooden stick into their brain.
		return

	target.visible_message(
		message = span_bolddanger("[target]'s body withers away! [target.p_Theyre()] gone for good!"),
		self_message = span_userdanger("NO! NO! NO! NO! NO!"),
		blind_message = span_hear("You hear a soft rustling."),
	)
	playsound(get_turf(target), 'sound/effects/whirthunk.ogg', vol = 30, vary = TRUE) // Use turf because the target is about to go bye bye.

	target.dust(just_ash = TRUE, drop_items = TRUE, force = TRUE) // Past this point, the vampire is ghosted. Sending self messages is useless.

	if (!QDELETED(target_bodypart) && !target_bodypart.owner) // If staking the vampire's head also dismembered it, then delete it.
		target.visible_message(span_bolddanger("[target]'s [target_zone_name] bursts into a shower of viscera from the sheer force of \the [src]!"))
		qdel(target_bodypart)

/// Can this mob be staked? Used as an extra check in the do_after for staking someone.
/mob/living/carbon/proc/can_be_staked()
	return !(mobility_flags & MOBILITY_MOVE) || stat != CONSCIOUS

/obj/item/stake/proc/try_stake_alt(atom/target, mob/living/user)
	var/is_brain = istype(target, /obj/item/organ/internal/brain)
	if (!istype(target, /obj/item/bodypart/head) && !is_brain)
		return FALSE
	. = TRUE // Anything past this point will stop 'attack()' from running.

	if (DOING_INTERACTION_WITH_TARGET(user, target)) // Don't spam please.
		return

	user.visible_message(
		message = span_danger("[user] starts driving \the [src] into [target]!"),
		self_message = span_warning("You start driving \the [src] into [target]!"),
		blind_message = span_hear("You hear sickening crunching!"),
	)
	playsound(target, 'sound/magic/demon_consume.ogg', vol = 50, vary = TRUE)

	if (!do_after(user, stake_time * (is_brain ? 0.5 : 0.75), target)) // For a normal stake, normal is 12s, head is 9s and brain is 6s.
		target.balloon_alert(user, "interrupted!")
		return

	user.visible_message(
		message = span_danger("[user] drives \the [src] into [target]!"),
		self_message = span_warning("You drive \the [src] into [target]!"),
		blind_message = span_hear("You hear a disgusting, wet splatter!"),
	)
	playsound(get_turf(target), 'sound/effects/splat.ogg', vol = 40, vary = TRUE) // Use turf because the target might be about to go bye bye.

	if (is_brain ? !try_dust_brain(target) : !try_dust_head(target, user))
		return

	target.visible_message(
		message = span_bolddanger("[target] withers away!"),
		blind_message = span_hear("You hear a soft rustling."),
	)
	playsound(get_turf(target), 'sound/effects/whirthunk.ogg', vol = 30, vary = TRUE) // Use turf because the target is about to go bye bye.

	new /obj/effect/decal/cleanable/ash(target.loc)
	qdel(target)

/obj/item/stake/proc/try_dust_head(obj/item/bodypart/head/head, mob/living/user)
	if (!istype(head))
		return FALSE

	var/brain_found = FALSE
	for (var/obj/item/organ/internal/brain/brain in head)
		. |= try_dust_brain(brain)
		brain_found = TRUE

	if (!.)
		head.receive_damage(brute = force * 10, wound_bonus = 100, sharpness = sharpness)

	if (!brain_found)
		to_chat(user, span_warning("There was a lack of resistance in [head]... wait, there was no brain inside!"))

/obj/item/stake/proc/try_dust_brain(obj/item/organ/internal/brain/brain)
	if (!istype(brain))
		return FALSE
	. = IS_VAMPIRE(brain.brainmob)
	if (!.)
		brain.apply_organ_damage(brain.maxHealth) // You're shoving a giant, sharpened wooden stick into their brain.

/// Created by heat treating a simple stake with a welder.
/obj/item/stake/hardened
	name = "hardened stake"
	desc = "A wooden stake carved to a sharp point and hardened by fire."
	icon_state = "hardened"

	force = 8
	throwforce = 12
	armour_penetration = 10

	embedding = list("embed_chance" = 35)
	wound_bonus = 5
	bare_wound_bonus = 5

	stake_time = 8 SECONDS

/// Created by coating a hardened stake with a layer of silver.
/obj/item/stake/silver
	name = "silver stake"
	desc = "Polished and sharp at the end. For when some mofo is always trying to iceskate uphill."
	icon_state = "silver"
	inhand_icon_state = "silver"

	force = 10
	throwforce = 15
	armour_penetration = 25

	embedding = list("embed_chance" = 65)
	wound_bonus = 10

	stake_time = 6 SECONDS
