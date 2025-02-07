/atom/movable/screen/alert/status_effect/vampire/starlit
	name = "Starlit"
	desc = "Your neophyte skin is being bombarded by starlight! Your powers are weakened!"
	icon_state = "starlight"

/datum/status_effect/vampire/starlit
	id = "vampire_starlit"
	tick_interval = STATUS_EFFECT_NO_TICK
	alert_type = /atom/movable/screen/alert/status_effect/vampire/starlit

/datum/status_effect/vampire/starlit/on_apply()
	. = ..()
	ADD_TRAIT(user, TRAIT_VAMPIRE_STARLIT, REF(src)) // Still uses a trait for faster checks and the access to signals it gives you.
	user.add_movespeed_modifier(/datum/movespeed_modifier/vampire_starlit)
	user.add_actionspeed_modifier(/datum/actionspeed_modifier/vampire_starlit)
	user.physiology?.brute_mod *= 1.5
	user.physiology?.burn_mod *= 1.5

	user.visible_message(
		message = span_danger("[user]'s skin reddens and singes!"),
		self_message = span_userdanger("Your neophyte skin is scalded by the starlight!"),
		blind_message = span_hear("You hear a soft simmer."), // Mm, vampire cooked at low heat.
	)

/datum/status_effect/vampire/starlit/on_remove()
	REMOVE_TRAIT(user, TRAIT_VAMPIRE_STARLIT, REF(src))
	user.remove_movespeed_modifier(/datum/movespeed_modifier/vampire_starlit)
	user.remove_actionspeed_modifier(/datum/actionspeed_modifier/vampire_starlit)
	user.physiology?.brute_mod /= 1.5
	user.physiology?.burn_mod /= 1.5

/datum/movespeed_modifier/vampire_starlit
	multiplicative_slowdown = 0.5

/datum/actionspeed_modifier/vampire_starlit
	multiplicative_slowdown = 0.5
