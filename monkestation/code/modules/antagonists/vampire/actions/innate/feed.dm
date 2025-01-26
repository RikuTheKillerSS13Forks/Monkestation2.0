/datum/action/cooldown/vampire/feed
	name = "Feed"
	desc = "Nourish yourself from the blood of a mortal or the lifeforce of your kin."
	button_icon_state = "power_feed"
	cooldown_time = 2 SECONDS
	is_toggleable = TRUE
	vampire_check_flags = NONE

	var/is_neck_feed = FALSE

	/// A hard ref to whoever we're feeding from.
	var/mob/living/victim = null

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

	if (user.is_mouth_covered() && !isplasmaman(user))
		if (feedback)
			user.balloon_alert(user, "mouth covered!")
		return FALSE
	if (target_antag_datum && target_antag_datum.current_lifeforce <= 0)
		if (feedback)
			user.balloon_alert(user, "[target.p_they()] lack[target.p_s()] lifeforce!")
		return FALSE
	if (target.blood_volume <= 0 || HAS_TRAIT(target, TRAIT_NOBLOOD))
		if (feedback)
			user.balloon_alert(user, "[target.p_they()] lack[target.p_s()] blood!")
		return FALSE
	return TRUE

/datum/action/cooldown/vampire/feed/proc/start_feed_extra_checks()
	if (!isliving(user.pulling) || user.grab_state < (is_neck_feed && iscarbon(user.pulling) ? GRAB_AGGRESSIVE : GRAB_PASSIVE))
		return FALSE
	return can_feed()

/datum/action/cooldown/vampire/feed/toggle_on()
	var/mob/living/target = user.pulling
	is_neck_feed = user.grab_state >= GRAB_AGGRESSIVE || !iscarbon(target) // Lifting up the wrist of a mouse would be pretty wack. Also you can't aggro grab them.

	if (is_neck_feed)
		to_chat(target, span_userdanger("[user] opens [user.p_their()] mouth, revealing a pair of fangs that are closing in on your neck!"))
	else
		to_chat(target, span_danger("[user] starts to lift your wrist up to [user.p_their()] mouth."))

	if (!do_after(user, 2 SECONDS, target, timed_action_flags = (IGNORE_SLOWDOWNS | IGNORE_USER_LOC_CHANGE | IGNORE_TARGET_LOC_CHANGE), extra_checks = CALLBACK(src, PROC_REF(start_feed_extra_checks))))
		user.balloon_alert(user, "interrupted!")
		return

	if (is_neck_feed && iscarbon(target))
		user.setGrabState(GRAB_NECK) // This has to be before we set 'victim', otherwise 'on_update_grab_state()' has a seizure and tries to end the feed as it's starting.
		if (!target.buckled && !target.density)
			target.Move(user.loc) // GET OVER HERE!!

	victim = target
	. = ..()

	ADD_TRAIT(victim, TRAIT_NODEATH, REF(src))
	RegisterSignal(victim, COMSIG_QDELETING, PROC_REF(toggle_off))
	RegisterSignal(victim, COMSIG_LIVING_LIFE, PROC_REF(on_victim_life))

	if (is_neck_feed)
		user.visible_message(
			message = span_danger("[user] sinks [user.p_their()] fangs into [victim]'s neck!"),
			self_message = span_notice("You sink your fangs into [victim]'s neck."),
			ignored_mobs = list(victim),
		)
		to_chat(victim, span_userdanger("[user] sinks [user.p_their()] fangs into your neck!"))

		if (!HAS_TRAIT(victim, TRAIT_ANALGESIA))
			victim.emote("scream")
	else
		user.visible_message(
			message = span_notice("[user] gently sinks [user.p_their()] fangs into [victim]'s wrist."),
			self_message = span_notice("You gently sink your fangs into [victim]'s wrist."),
			ignored_mobs = list(victim),
		)
		to_chat(victim, span_danger("[user] gently sinks [user.p_their()] fangs into your wrist."))

		if (!HAS_TRAIT(victim, TRAIT_ANALGESIA))
			victim.emote("flinch")

	playsound(victim, 'sound/effects/wounds/blood1.ogg', vol = 20, vary = TRUE, extrarange = SILENCED_SOUND_EXTRARANGE)

/datum/action/cooldown/vampire/feed/toggle_off(forced)
	. = ..()

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
		feed_zone = pick(eligible_zones)

	if (forced)
		user.visible_message(
			message = span_danger("[user]'s fangs are torn from [victim]'s [feed_name]!"),
			self_message = span_warning("Your fangs are torn from [victim]'s [feed_name]!"),
			ignored_mobs = list(victim),
		)
		to_chat(victim, span_userdanger("[user]'s fangs are torn from your [feed_name]!"))
		playsound(victim, 'sound/effects/wounds/blood2.ogg', vol = 50, vary = TRUE, extrarange = MEDIUM_RANGE_SOUND_EXTRARANGE)

		victim.apply_damage(rand(8, 12), BRUTE, feed_zone, wound_bonus = CANT_WOUND) // This causes them to make a pain emote so there's no need to do custom logic.
	else
		user.visible_message(
			message = span_notice("[user] lifts [user.p_their()] fangs from [victim]'s [feed_name]."),
			self_message = span_notice("You lift your fangs from [victim]'s [feed_name]."),
			ignored_mobs = list(victim),
		)
		to_chat(victim, span_green("[user] lifts [user.p_their()] fangs from your [feed_name]."))

	if (iscarbon(victim))
		var/feed_bodypart = victim.get_bodypart(feed_zone)
		if (feed_bodypart)
			var/datum/wound/vampire_bite_mark/bite_mark = new
			bite_mark.apply_wound(feed_bodypart)

	victim = null

/datum/action/cooldown/vampire/feed/proc/check_active_grab()
	if (user.pulling != victim || (user.grab_state < (is_neck_feed && iscarbon(victim) ? GRAB_NECK : GRAB_PASSIVE)))
		user.balloon_alert(user, "grab lost!")
		toggle_off(forced = TRUE)
		return FALSE
	return TRUE

/datum/action/cooldown/vampire/feed/proc/check_active_feed(datum/antagonist/vampire/victim_antag_datum)
	if (victim_antag_datum && victim_antag_datum.current_lifeforce <= 0)
		user.balloon_alert(user, "[victim.p_theyre()] out of lifeforce!")
		toggle_off()
	if (victim.blood_volume <= 0 || HAS_TRAIT(victim, TRAIT_NOBLOOD))
		user.balloon_alert(user, "[victim.p_theyre()] out of blood!")
		toggle_off()

/datum/action/cooldown/vampire/feed/proc/on_victim_life(datum/source, seconds_per_tick, times_fired)
	SIGNAL_HANDLER
	if (!check_active_grab())
		return

	var/datum/antagonist/vampire/victim_antag_datum = victim.mind?.has_antag_datum(/datum/antagonist/vampire)

	var/delta_time = DELTA_WORLD_TIME(SSmobs)
	var/feed_rate = delta_time / (is_neck_feed ? 30 : 60) // Amount to take per second as a 0-1 percentage.

	if (victim_antag_datum)
		var/lifeforce_to_take = min(victim_antag_datum.current_lifeforce, LIFEFORCE_PER_HUMAN * feed_rate)
		antag_datum.adjust_lifeforce(lifeforce_to_take)
		victim_antag_datum.adjust_lifeforce(-lifeforce_to_take)
	else
		var/blood_to_take = min(victim.blood_volume, BLOOD_VOLUME_NORMAL * feed_rate)
		antag_datum.adjust_lifeforce(blood_to_take * BLOOD_TO_LIFEFORCE)
		victim.blood_volume -= blood_to_take // This will only take 8 seconds to become lethal, so the TTK on a vampire with feed is a 2-4 second grab + 2 second delay + 6 second drain. (10-12 seconds)

	if (is_neck_feed)
		victim.adjustOxyLoss(10 * delta_time)

	owner.playsound_local(soundin = 'sound/effects/singlebeat.ogg', vol = 40, vary = TRUE)
	victim.playsound_local(soundin = 'sound/effects/singlebeat.ogg', vol = 40, vary = TRUE)

	check_active_feed(victim_antag_datum) // We do this after draining so that passive blood regen doesn't keep feeding in limbo.

/datum/action/cooldown/vampire/feed/proc/on_update_grab_state()
	SIGNAL_HANDLER
	if (!QDELETED(victim))
		check_active_grab()
	build_all_button_icons(UPDATE_BUTTON_STATUS)
