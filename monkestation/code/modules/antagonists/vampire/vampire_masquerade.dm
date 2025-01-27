/datum/antagonist/vampire
	var/masquerade_enabled = TRUE

/datum/antagonist/vampire/proc/set_masquerade(state, forced = FALSE, silent = FALSE)
	if (masquerade_enabled == state && !forced)
		return

	var/old_state = masquerade_enabled
	masquerade_enabled = state

	if (masquerade_enabled)
		user.add_traits(masquerade_traits, REF(src))
		user.remove_traits(visible_traits, REF(src))
		user.RemoveElement(/datum/element/cult_eyes, initial_delay = 0)
		user.RemoveElement(/datum/element/vampire_skin)

		if (!silent)
			user.visible_message(
				message = span_danger("[user]'s skin returns to life and the glow of [user.p_their()] eyes rescinds to nothingness."),
				self_message = span_cult("You form a disguise, your skin now seemingly alive as your eyes readjust. Your powers are sealed."),
			)
			playsound(user, 'monkestation/sound/vampires/masquerade_enable.ogg', vol = 80, vary = FALSE)
	else
		user.add_traits(visible_traits, REF(src))
		user.remove_traits(masquerade_traits, REF(src))
		user.AddElement(/datum/element/cult_eyes, initial_delay = 0)
		user.AddElement(/datum/element/vampire_skin)

		if (!silent)
			user.visible_message(
				message = span_danger("[user]'s skin turns a pale grey, and [user.p_their()] eyes turn an unnatural, glowing shade of red."),
				self_message = span_cult("You shed your disguise, returning back to your undead form as your powers return to their glory."),
			)
			playsound(user, 'monkestation/sound/vampires/masquerade_disable.ogg', vol = 80, vary = FALSE)

	SEND_SIGNAL(src, COMSIG_VAMPIRE_MASQUERADE, masquerade_enabled, old_state)
