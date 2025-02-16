/datum/action/cooldown/vampire/feed
	name = "Feed"
	desc = "Nourish yourself from the blood of a mortal or the lifeforce of your kin."
	button_icon_state = "power_feed"
	cooldown_time = 2 SECONDS
	is_toggleable = TRUE
	vampire_check_flags = NONE

	var/is_neck_feed = FALSE

	/// If we're feeding from a sentient mob. If the feed is bad, then it's limited to LIFEFORCE_REAGENT_LIMIT
	var/is_good_feed = FALSE

	/// A hard ref to whoever we're feeding from.
	var/mob/living/victim = null

	/// Whether we're enthralling someone right now.
	var/is_enthralling = FALSE

/datum/action/cooldown/vampire/feed/Grant(mob/granted_to)
	. = ..()
	RegisterSignals(user, list(COMSIG_MOVABLE_SET_GRAB_STATE, COMSIG_LIVING_START_PULL, COMSIG_ATOM_NO_LONGER_PULLING), PROC_REF(on_update_grab_state))

/datum/action/cooldown/vampire/feed/Remove(mob/removed_from)
	UnregisterSignal(user, list(COMSIG_MOVABLE_SET_GRAB_STATE, COMSIG_LIVING_START_PULL, COMSIG_ATOM_NO_LONGER_PULLING))
	return ..()

/datum/action/cooldown/vampire/feed/IsAvailable(feedback)
	. = ..()
	if (!.)
		return
	if (is_active)
		return TRUE
	if (!isliving(user.pulling))
		if (feedback)
			user.balloon_alert(user, "grab someone first!")
		return FALSE
	if (!can_feed(feedback))
		return FALSE

/datum/action/cooldown/vampire/feed/proc/can_feed(feedback)
	var/mob/living/target = user.pulling
	var/datum/antagonist/vampire/target_antag_datum = target.mind?.has_antag_datum(/datum/antagonist/vampire)

	if (HAS_TRAIT(target, TRAIT_FEED_PROTECTION))
		if (feedback)
			target.balloon_alert(user, "protected!")
		return FALSE
	if (user.is_mouth_covered() && !isplasmaman(user))
		if (feedback)
			user.balloon_alert(user, "mouth covered!")
		return FALSE
	if (target_antag_datum && target_antag_datum.current_lifeforce <= LIFEFORCE_REAGENT_LIMIT)
		if (feedback)
			target.balloon_alert(user, "lifeforce too weak!")
		return FALSE
	if (!target_antag_datum && (target.blood_volume <= 0 || HAS_TRAIT(target, TRAIT_NOBLOOD)))
		if (feedback)
			target.balloon_alert(user, "no blood!")
		return FALSE
	return TRUE

/datum/action/cooldown/vampire/feed/proc/start_feed_extra_checks(mob/living/target)
	if (user.pulling != target || user.grab_state < (is_neck_feed && iscarbon(target) ? GRAB_AGGRESSIVE : GRAB_PASSIVE))
		return FALSE
	return can_feed()

/datum/action/cooldown/vampire/feed/toggle_on()
	var/mob/living/target = user.pulling
	is_neck_feed = user.grab_state >= GRAB_AGGRESSIVE || !iscarbon(target) // Lifting up the wrist of a mouse would be pretty wack. Also you can't aggro grab them.

	if (is_neck_feed)
		target.show_message(span_userdanger("[user] opens [user.p_their()] mouth, revealing a pair of fangs that are closing in on your neck!"), MSG_VISUAL)
	else
		target.show_message(
			msg = span_danger("[user] starts to lift your wrist up to [user.p_their()] mouth."),
			alt_msg = span_danger("You feel something tugging at your wrist."),
			type = MSG_VISUAL
		)

	if (!do_after(user, 2 SECONDS, target, timed_action_flags = IGNORE_SLOWDOWNS, extra_checks = CALLBACK(src, PROC_REF(start_feed_extra_checks), target)))
		user.balloon_alert(user, "interrupted!")
		return

	if (is_neck_feed && iscarbon(target))
		user.setGrabState(GRAB_NECK) // This has to be before we set 'victim', otherwise 'on_update_grab_state()' has a seizure and tries to end the feed as it's starting.
		if (!target.buckled && !target.density)
			target.Move(user.loc) // GET OVER HERE!!

	victim = target
	. = ..()

	is_good_feed = is_good_feed()
	if (!is_good_feed)
		victim.balloon_alert(user, "stale")
		to_chat(user, span_warning("[victim]'s blood is stale. You'll only be able to reach [LIFEFORCE_REAGENT_LIMIT] lifeforce by feeding from [victim.p_them()]."))

	ADD_TRAIT(user, TRAIT_MUTE, REF(src))
	ADD_TRAIT(victim, TRAIT_NODEATH, REF(src))
	RegisterSignal(victim, COMSIG_QDELETING, PROC_REF(toggle_off))
	RegisterSignal(victim, COMSIG_LIVING_LIFE, PROC_REF(on_victim_life))

	if (is_neck_feed)
		user.visible_message(
			message = span_danger("[user] sinks [user.p_their()] fangs into [victim]'s neck!"),
			self_message = span_notice("You sink your fangs into [victim]'s neck."),
			ignored_mobs = list(victim),
		)
		victim.show_message(
			msg = span_userdanger("[user] sinks [user.p_their()] fangs into your neck!"), type = MSG_VISUAL,
			alt_msg = span_userdanger("You feel a sharp pain in your neck!"),
		)

		if (!HAS_TRAIT(victim, TRAIT_ANALGESIA))
			victim.emote("scream")
	else
		user.visible_message(
			message = span_notice("[user] gently sinks [user.p_their()] fangs into [victim]'s wrist."),
			self_message = span_notice("You gently sink your fangs into [victim]'s wrist."),
			ignored_mobs = list(victim),
		)
		victim.show_message(
			msg = span_danger("[user] gently sinks [user.p_their()] fangs into your wrist."), type = MSG_VISUAL,
			alt_msg = span_danger("You feel a slight, yet sharp pain in your wrist."),
		)

		if (!HAS_TRAIT(victim, TRAIT_ANALGESIA))
			victim.emote("flinch")

	playsound(victim, 'sound/effects/wounds/blood1.ogg', vol = 20, vary = TRUE, extrarange = SILENCED_SOUND_EXTRARANGE)

/datum/action/cooldown/vampire/feed/toggle_off(forced)
	. = ..()

	REMOVE_TRAIT(user, TRAIT_MUTE, REF(src))
	REMOVE_TRAIT(victim, TRAIT_NODEATH, REF(src))
	UnregisterSignal(victim, list(COMSIG_QDELETING, COMSIG_LIVING_LIFE))

	if (QDELETED(victim)) // Put side effects past this point.
		victim = null
		return

	var/feed_name = is_neck_feed ? "neck" : "wrist"
	var/feed_zone = BODY_ZONE_CHEST

	if (iscarbon(victim))
		var/list/eligible_zones = is_neck_feed ? list(BODY_ZONE_HEAD) : list(BODY_ZONE_L_ARM, BODY_ZONE_R_ARM)
		for (var/zone in eligible_zones)
			if (!victim.get_bodypart(zone))
				eligible_zones -= zone
		if (length(eligible_zones))
			feed_zone = pick(eligible_zones)

	if (forced)
		user.visible_message(
			message = span_danger("[user]'s fangs are torn from [victim]'s [feed_name]!"),
			self_message = span_warning("Your fangs are torn from [victim]'s [feed_name]!"),
			ignored_mobs = list(victim),
		)
		victim.show_message(
			msg = span_userdanger("[user]'s fangs are torn from your [feed_name]!"), type = MSG_VISUAL,
			alt_msg = span_userdanger("The sharp pain in your neck grows worse!")
		)
		playsound(victim, 'sound/effects/wounds/blood2.ogg', vol = 50, vary = TRUE, extrarange = MEDIUM_RANGE_SOUND_EXTRARANGE)

		victim.apply_damage(rand(8, 12), BRUTE, feed_zone, wound_bonus = CANT_WOUND) // This causes them to make a pain emote so there's no need to do custom logic.
	else
		user.visible_message(
			message = span_notice("[user] lifts [user.p_their()] fangs from [victim]'s [feed_name]."),
			self_message = span_notice("You lift your fangs from [victim]'s [feed_name]."),
			ignored_mobs = list(victim),
		)
		victim.show_message(
			msg = span_green("[user] lifts [user.p_their()] fangs from your [feed_name]."), type = MSG_VISUAL,
			alt_msg = span_green("The pain in your wrist disappears.")
		)

	if (iscarbon(victim))
		var/feed_bodypart = victim.get_bodypart(feed_zone)
		if (feed_bodypart)
			var/datum/wound/vampire_bite_mark/bite_mark = new
			bite_mark.apply_wound(feed_bodypart)

	victim = null

// If the mob is actively sentient or has been within the last 30 seconds, then as a certain chef would say, "Finally, some good fucking food."
/datum/action/cooldown/vampire/feed/proc/is_good_feed()
	if (!victim.mind)
		return FALSE
	if (IS_VAMPIRE(victim))
		return TRUE
	if (victim.stat == DEAD && (world.time - victim.timeofdeath) > 30 SECONDS)
		return FALSE
	if (!victim.client && (world.time - victim.lastclienttime) > 30 SECONDS)
		return FALSE
	return TRUE

/datum/action/cooldown/vampire/feed/proc/check_active_grab(feedback)
	if (user.pulling != victim || (user.grab_state < (is_neck_feed && iscarbon(victim) ? GRAB_NECK : GRAB_PASSIVE)))
		if (feedback)
			user.balloon_alert(user, "grab lost!")
		toggle_off(forced = TRUE)
		return FALSE
	return TRUE

/datum/action/cooldown/vampire/feed/proc/on_update_grab_state()
	SIGNAL_HANDLER
	if (!QDELETED(victim))
		check_active_grab()
	build_all_button_icons(UPDATE_BUTTON_STATUS)

/datum/action/cooldown/vampire/feed/proc/check_active_feed(datum/antagonist/vampire/victim_antag_datum)
	if (victim_antag_datum && victim_antag_datum.current_lifeforce <= LIFEFORCE_REAGENT_LIMIT)
		victim.balloon_alert(user, "lifeforce too weak!")
		return FALSE
	if (!victim_antag_datum && (victim.blood_volume <= 0 || HAS_TRAIT(victim, TRAIT_NOBLOOD)))
		return FALSE // Don't add a balloon alert here, because 'can_enthrall()' may send one as well and two at once is dumb.
	return TRUE

/datum/action/cooldown/vampire/feed/proc/on_victim_life(datum/source, seconds_per_tick, times_fired)
	SIGNAL_HANDLER
	if (!check_active_grab(feedback = TRUE))
		return

	var/datum/antagonist/vampire/victim_antag_datum = victim.mind?.has_antag_datum(/datum/antagonist/vampire)

	var/delta_time = DELTA_WORLD_TIME(SSmobs)
	var/feed_rate = delta_time / (is_neck_feed ? 30 : 60) // Amount to take per second as a 0-1 percentage.

	if (victim_antag_datum)
		handle_lifeforce_feed(feed_rate, victim_antag_datum)
	else
		handle_blood_feed(feed_rate)

	if (is_neck_feed)
		victim.adjustOxyLoss(10 * delta_time)

	owner.playsound_local(soundin = 'sound/effects/singlebeat.ogg', vol = 40, vary = TRUE)
	victim.playsound_local(soundin = 'sound/effects/singlebeat.ogg', vol = 40, vary = TRUE)

	if (check_active_feed(victim_antag_datum)) // We do this after draining so that passive blood regen doesn't keep feeding in limbo.
		return

	INVOKE_ASYNC(src, PROC_REF(end_feed_async))

/datum/action/cooldown/vampire/feed/proc/end_feed_async()
	try_enthrall()

	if (is_active) // Because 'can_enthrall()' calls 'check_active_grab()' it can toggle off the action.
		toggle_off()

/datum/action/cooldown/vampire/feed/proc/handle_blood_feed(feed_rate) // A bit more complex than lifeforce is, due to the feed limit being a thing.
	var/blood_to_take = min(victim.blood_volume, feed_rate * BLOOD_VOLUME_NORMAL)
	victim.blood_volume -= blood_to_take // Done before the feed limit, you can still drain blood from someone who has reached the limit. You just don't get anything for it.

	var/datum/component/feed_limit/feed_limit = victim.mind?.GetComponent(/datum/component/feed_limit)
	if (!feed_limit)
		feed_limit = victim.mind?.AddComponent(/datum/component/feed_limit)

	var/lifeforce_to_give = blood_to_take * BLOOD_TO_LIFEFORCE

	if (!is_good_feed)
		lifeforce_to_give = min(lifeforce_to_give, max(0, LIFEFORCE_REAGENT_LIMIT - antag_datum.current_lifeforce))

	if (feed_limit)
		lifeforce_to_give = min(lifeforce_to_give, feed_limit.get_remaining_lifeforce()) // So you don't get like 1 tick extra of lifeforce when hitting the limit. Also handles the limit itself.

	if (lifeforce_to_give > 0)
		antag_datum.adjust_lifeforce(lifeforce_to_give)
		feed_limit?.increment(victim, user, lifeforce_to_give) // Remember to increment it *after* calling 'get_remaining_lifeforce()'

/datum/action/cooldown/vampire/feed/proc/handle_lifeforce_feed(feed_rate, datum/antagonist/vampire/victim_antag_datum)
	// The last part makes it so vampires must leave other vampires with at least LIFEFORCE_REAGENT_LIMIT lifeforce. Prevents them from round removing each other willy nilly without stakes.
	// More importantly, it prevents one vampire from injecting blood, then having another vampire drink it from them. That could be used to make infinite lifeforce.
	var/lifeforce_to_take = min(victim_antag_datum.current_lifeforce, LIFEFORCE_PER_HUMAN * feed_rate, max(0, victim_antag_datum.current_lifeforce - LIFEFORCE_REAGENT_LIMIT))

	victim_antag_datum.adjust_lifeforce(-lifeforce_to_take)
	antag_datum.adjust_lifeforce(lifeforce_to_take)

/datum/action/cooldown/vampire/feed/proc/can_enthrall(feedback)
	if (!is_active || !is_neck_feed)
		return FALSE
	if (!ishuman(victim) || IS_VAMPIRE(victim))
		return FALSE
	if (!check_active_grab(feedback))
		return FALSE
	if (antag_datum.current_lifeforce < LIFEFORCE_REAGENT_LIMIT * 2)
		if (feedback)
			user.balloon_alert(user, "not enough lifeforce!")
		return FALSE
	if (victim.stat == DEAD)
		if (feedback)
			victim.balloon_alert(user, "dead!")
		return FALSE
	if (!victim.mind)
		if (feedback)
			victim.balloon_alert(user, "mindless!")
		return FALSE
	if (HAS_MIND_TRAIT(victim, TRAIT_UNCONVERTABLE))
		if (feedback)
			victim.balloon_alert(user, "unconvertable!")
		return FALSE
	if (HAS_TRAIT(victim, TRAIT_MINDSHIELD) && !HAS_MIND_TRAIT(victim, TRAIT_MIND_BREAK))
		if (feedback)
			victim.balloon_alert(user, "mindshielded!")
		return FALSE
	return TRUE

/datum/action/cooldown/vampire/feed/proc/try_enthrall()
	if (!can_enthrall(feedback = TRUE))
		return FALSE

	victim.balloon_alert(user, "enthralling...")
	victim.visible_message(message = span_danger("[victim]'s skin begins to turn grey."))

	UnregisterSignal(victim, COMSIG_LIVING_LIFE) // Stop feeding effects at this point.

	// Feeding someone dry takes a long while to begin with, so this being relatively short is fine.
	if (!do_after(user, 6 SECONDS, victim, timed_action_flags = IGNORE_SLOWDOWNS, extra_checks = CALLBACK(src, PROC_REF(can_enthrall))))
		user.balloon_alert(user, "interrupted!")
		return FALSE

	antag_datum.enthrall(victim)

	var/datum/antagonist/vampire/thrall/thrall_antag_datum = victim.mind.has_antag_datum(/datum/antagonist/vampire/thrall)

	antag_datum.adjust_lifeforce(-LIFEFORCE_REAGENT_LIMIT)
	thrall_antag_datum.set_lifeforce(LIFEFORCE_REAGENT_LIMIT)

	victim.setOxyLoss(0) // Stops them from instantly dying to the oxyloss from having all their blood drained.
	victim.setOrganLoss(ORGAN_SLOT_BRAIN, 0) // Oxyloss causes brain damage, so we give them a freebie. They'd heal it quickly anyways.

	var/mob/living/carbon/human/human_victim = victim
	human_victim.cure_all_traumas(TRAUMA_RESILIENCE_LOBOTOMY) // Second part of said freebie. (same trauma resilience level as vampire regen)

	return TRUE
