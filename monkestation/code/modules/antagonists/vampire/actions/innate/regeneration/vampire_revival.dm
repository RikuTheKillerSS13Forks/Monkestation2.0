/datum/action/cooldown/vampire/regeneration
	COOLDOWN_DECLARE(revival_cooldown)
	var/is_reviving = FALSE

/datum/action/cooldown/vampire/regeneration/proc/handle_revival()
	if (user.stat != DEAD || user.health + user.getOxyLoss() < (user.maxHealth * 0.5))
		is_reviving = FALSE
		return

	if (!is_reviving)
		COOLDOWN_START(src, revival_cooldown, 5 SECONDS) // Actually 6 seconds. But this makes it way more likely to be exactly 3 life ticks of effects, then 1 for revival.
		is_reviving = TRUE

		user.notify_ghost_cloning("Your immortal life is not yet over!", sound = 'monkestation/sound/vampires/owl_7.ogg')
		user.grab_ghost() // You shall bear witness to your revival.

	if (!COOLDOWN_FINISHED(src, revival_cooldown))
		handle_revival_effects()
		return

	is_reviving = FALSE

	user.setOxyLoss(0) // In case you succumbed, wakes you up immediately.
	INVOKE_ASYNC(user, TYPE_PROC_REF(/mob/living, revive)) // Async cause of IPCs and AIs. It should just be vfx/sfx thou, revival itself is instant... I hope.

	user.set_resting(TRUE, silent = TRUE) // Otherwise our instant one early returns if you're already trying to get up.
	user.set_resting(FALSE, silent = TRUE, instant = TRUE)

	user.visible_message(
		message = span_bolddanger("[user] comes back from the dead!"),
		self_message = span_green("You've come back from the dead! ...only to still be undead."),
	)

/datum/action/cooldown/vampire/regeneration/proc/handle_revival_effects()
	user.visible_message(
		message = span_danger("[user]'s body twitches ominously!"),
		self_message = span_notice("Your body twitches."),
	)

	playsound(user, 'sound/effects/singlebeat.ogg', vol = 20, vary = TRUE, extrarange = MEDIUM_RANGE_SOUND_EXTRARANGE)

	var/pixel_x_offset = rand(-2, 2)
	animate(user, 0.3 SECONDS, flags = ANIMATION_PARALLEL | ANIMATION_RELATIVE, easing = CUBIC_EASING | EASE_OUT, pixel_y = 3, pixel_x = pixel_x_offset)
	animate(user, 0.3 SECONDS, flags = ANIMATION_PARALLEL | ANIMATION_RELATIVE, easing = CUBIC_EASING | EASE_IN, pixel_y = -3, pixel_x = -pixel_x_offset)
