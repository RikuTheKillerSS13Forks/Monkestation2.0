/datum/action/cooldown/vampire/feed
	name = "Feed"
	desc = "Nourish yourself from the blood of a mortal or the lifeforce of your kin."
	is_toggleable = TRUE
	vampire_check_flags = NONE

	var/is_neck_feed = FALSE

	/// A hard ref to whoever we're feeding from.
	var/mob/living/victim = null

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

	if (!user.Adjacent(target))
		if (feedback)
			user.balloon_alert(user, "too far away!")
		return FALSE
	if (user.is_mouth_covered() && !isplasmaman(user))
		if (feedback)
			user.balloon_alert(user, "mouth covered!")
		return FALSE
	if (!target_antag_datum && HAS_TRAIT(target, TRAIT_NOBLOOD))
		if (feedback)
			user.balloon_alert(user, "[target.p_they()] lack[target.p_s()] blood!")
		return FALSE
	if (target_antag_datum && target_antag_datum.current_lifeforce <= 0)
		if (feedback)
			user.balloon_alert(user, "[target.p_they()] lack[target.p_s()] lifeforce!")
		return FALSE
	return TRUE

/datum/action/cooldown/vampire/feed/proc/start_feed_extra_checks()
	if (!isliving(user.pulling) || user.grab_state < (is_neck_feed && iscarbon(user.pulling) ? GRAB_AGGRESSIVE : GRAB_PASSIVE))
		return FALSE
	return can_feed()

/datum/action/cooldown/vampire/feed/toggle_on()
	var/mob/living/target = user.pulling
	is_neck_feed = user.grab_state >= GRAB_AGGRESSIVE || !iscarbon(target) // Lifting up the wrist of a mouse would be pretty wack.

	if (is_neck_feed)
		to_chat(target, span_userdanger("[user] opens [user.p_their()] mouth, revealing a pair of fangs that are closing in on your neck!"))
	else
		to_chat(target, span_danger("[user] starts to lift your wrist up to [user.p_their()] mouth."))

	if (!do_after(user, 2 SECONDS, target, timed_action_flags = IGNORE_SLOWDOWNS | IGNORE_USER_LOC_CHANGE | IGNORE_TARGET_LOC_CHANGE, extra_checks = PROC_REF(start_feed_extra_checks)))
		user.balloon_alert(user, "interrupted!")
		return

	victim = target
	. = ..()

	// VFX/SFX START

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

	// VFX/SFX END

	ADD_TRAIT(victim, TRAIT_NODEATH, REF(src))
	RegisterSignal(victim, COMSIG_QDELETING, PROC_REF(toggle_off))
	RegisterSignal(victim, COMSIG_LIVING_LIFE, PROC_REF(on_victim_life))

/datum/action/cooldown/vampire/feed/toggle_off() // This should only handle mechanically stopping the feed.
	. = ..()
	if (!victim)
		return

	REMOVE_TRAIT(victim, TRAIT_NODEATH, REF(src))
	UnregisterSignal(victim, list(COMSIG_QDELETING, COMSIG_LIVING_LIFE))
	victim = null

/datum/action/cooldown/vampire/feed/proc/stop_feeding(forced) // This should handle messages and then toggle the action off.
	var/feed_name = is_neck_feed ? "neck" : "wrist"

	if (forced)
		user.visible_message(
			message = span_danger("[user]'s fangs are torn from [victim]'s [feed_name]!"),
			self_message = span_warning("Your fangs are torn from [victim]'s [feed_name]!"),
			ignored_mobs = list(victim),
		)
		to_chat(victim, span_userdanger("[user]'s fangs are torn from your [feed_name]!"))
	else
		user.visible_message(
			message = span_notice("[user] lifts [user.p_their()] fangs from [victim]'s [feed_name]."),
			self_message = span_notice("You lift your fangs from [victim]'s [feed_name]."),
			ignored_mobs = list(victim),
		)
		to_chat(victim, span_green("[user] lifts [user.p_their()] fangs from your [feed_name]."))

	toggle_off()

/datum/action/cooldown/vampire/feed/proc/check_active_grab()
	if (user.pulling != victim || (user.grab_state < (is_neck_feed && iscarbon(victim) ? GRAB_NECK : GRAB_PASSIVE)))
		user.balloon_alert(user, "grab lost!")
		stop_feeding(forced = TRUE)
		return FALSE
	return TRUE

/datum/action/cooldown/vampire/feed/proc/check_active_feed()
	var/datum/antagonist/vampire/victim_antag_datum = victim.mind?.has_antag_datum(/datum/antagonist/vampire)

	if (!check_active_grab())
		return FALSE
	if (!victim_antag_datum && HAS_TRAIT(victim, TRAIT_NOBLOOD))
		user.balloon_alert(user, "[victim.p_theyre()] out of blood!")
		stop_feeding()
		return FALSE
	if (victim_antag_datum && victim_antag_datum.current_lifeforce <= 0)
		user.balloon_alert(user, "[victim.p_theyre()] out of lifeforce!")
		stop_feeding()
		return FALSE
	return TRUE

/datum/action/cooldown/vampire/feed/proc/on_victim_life()
	SIGNAL_HANDLER

	if (!check_active_feed())
		return
