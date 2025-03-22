/atom/movable/screen/alert/status_effect/vampire/frenzy
	name = "Frenzy"
	desc = "Your thirst for blood has boiled over the edge!"
	icon_state = "frenzy"

/datum/status_effect/vampire/frenzy
	id = "vampire_frenzy"
	tick_interval = STATUS_EFFECT_NO_TICK
	alert_type = /atom/movable/screen/alert/status_effect/vampire/frenzy

/datum/status_effect/vampire/frenzy/on_apply()
	. = ..()
	ADD_TRAIT(user, TRAIT_VAMPIRE_FRENZY, REF(src)) // Still uses a trait for faster checks and the access to signals it gives you.
	user.add_actionspeed_modifier(/datum/actionspeed_modifier/vampire_frenzy)

	user.visible_message(
		message = span_danger("[user] looks exhausted, yet renewed as they enter a frenzy!"),
		self_message = span_warning("You succumb to your vampiric thirst, entering a frenzy!"),
	)

/datum/status_effect/vampire/frenzy/on_remove()
	REMOVE_TRAIT(user, TRAIT_VAMPIRE_FRENZY, REF(src))
	user.remove_actionspeed_modifier(/datum/actionspeed_modifier/vampire_frenzy)

	user.visible_message(
		message = span_danger("[user] calms down from their frenzy."),
		self_message = span_warning("With your lifeforce regained, you calm down from your frenzy."),
	)

/datum/actionspeed_modifier/vampire_frenzy
	multiplicative_slowdown = -0.5
