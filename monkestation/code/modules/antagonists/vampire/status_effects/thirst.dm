/atom/movable/screen/alert/status_effect/vampire/thirst
	name = "Thirst"
	desc = "Your body is shivering. The edges of your vision are darkening. You need lifeforce, and you need it fast."

	icon_state = "power_torpor"
	background_icon_state = "vamp_power_off_oneshot"

/datum/status_effect/vampire/thirst
	id = "vampire_thirst"
	duration = 30 SECONDS
	show_duration = TRUE
	tick_interval = 0.2 SECONDS
	alert_type = /atom/movable/screen/alert/status_effect/vampire/thirst

/datum/status_effect/vampire/thirst/on_apply()
	. = ..()
	to_chat(user, span_userdanger("Your lifeforce runs thin..."))

/datum/status_effect/vampire/thirst/on_remove()
	. = ..()
	to_chat(user, span_warning("You've staved off the worst, for now..."))

/datum/status_effect/vampire/thirst/tick(seconds_per_tick, times_fired)
	. = ..()
	if (user.stat == DEAD)
		return
	if (SPT_PROB(10, seconds_per_tick))
		user.emote("shiver")
	if (duration < world.time)
		duration = max(duration, world.time) // The status effect never actually expires on its own.
		if (!HAS_TRAIT(user, TRAIT_NODEATH))
			user.death(gibbed = FALSE, cause_of_death = "vampiric malnutrition")
