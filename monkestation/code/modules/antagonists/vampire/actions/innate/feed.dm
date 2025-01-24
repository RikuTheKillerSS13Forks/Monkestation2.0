/datum/action/cooldown/vampire/feed
	name = "Feed"
	desc = "Nourish yourself from the blood of a mortal or the lifeforce of your kin."
	is_toggleable = TRUE

	var/is_neck_feed = FALSE

/datum/action/cooldown/vampire/feed/IsAvailable(feedback)
	. = ..()
	if (!.)
		return
	if (is_active)
		return TRUE
	if (!can_feed(feedback))
		return FALSE

/datum/action/cooldown/vampire/feed/proc/can_feed(feedback)
	if (!isliving(user.pulling))
		if (feedback)
			user.balloon_alert(user, "grab someone first!")
		return FALSE

	var/mob/living/target = user.pulling
	var/datum/antagonist/vampire/target_antag_datum = target.mind?.has_antag_datum(/datum/antagonist/vampire)

	if (!target_antag_datum && HAS_TRAIT(target, TRAIT_NOBLOOD))
		if (feedback)
			user.balloon_alert(user, "[target.p_they()] lack[target.p_s()] blood!")
		return FALSE
	if (target_antag_datum && target_antag_datum.current_lifeforce <= 0)
		if (feedback)
			user.balloon_alert(user, "[target.p_they()] lack[target.p_s()] lifeforce!")
		return FALSE
	return TRUE

/datum/action/cooldown/vampire/feed/toggle_on()
	. = ..()
	var/mob/living/target = user.pulling
	is_neck_feed = user.grab_state >= GRAB_AGGRESSIVE || !iscarbon(target) // Lifting up the wrist of a mouse would be pretty wack.

	if (is_neck_feed)
		to_chat(target, span_userdanger("[user] opens [user.p_their()] mouth, revealing a pair of fangs that are closing in on your neck!"))
	else
		to_chat(target, span_danger("[user] starts to lift your wrist up to [user.p_their()] mouth."))

	if (is_neck_feed)
		user.visible_message(
			message = span_danger("[user] sinks [user.p_their()] fangs into [target]'s neck!"),
			self_message = span_notice("You sink your fangs into [target]'s neck."),
			ignored_mobs = list(target),
		)
		to_chat(target, span_userdanger("[user] sinks [user.p_their()] fangs into your neck!"))

		if (!HAS_TRAIT(target, TRAIT_ANALGESIA))
			target.emote("flinch")
	else
		user.visible_message(
			message = span_notice("[user] gently sinks [user.p_their()] fangs into [target]'s wrist."),
			self_message = span_notice("You gently sink your fangs into [target]'s wrist."),
			ignored_mobs = list(target),
		)
		to_chat(target, span_danger("[user] gently sinks [user.p_their()] fangs into your wrist."))

		if (!HAS_TRAIT(target, TRAIT_ANALGESIA))
			target.emote("scream")
