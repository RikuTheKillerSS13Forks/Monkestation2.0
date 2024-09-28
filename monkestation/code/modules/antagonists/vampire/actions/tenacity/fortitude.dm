/datum/armor/vampire_fortitude // Way stronger than nanite armor.
	melee = 40
	bullet = 40
	laser = 30
	energy = 30

/datum/movespeed_modifier/vampire_fortitude // Decent bit of slowdown.
	multiplicative_slowdown = 0.5

/datum/action/cooldown/vampire/fortitude
	name = "Fortitude"
	desc = "Enhance your body even further at the cost of speed. Drains lifeforce while active."
	button_icon_state = "power_fortitude"
	toggleable = TRUE
	constant_life_cost = LIFEFORCE_PER_HUMAN / 300 // 5 minutes of fortitude per human.

/datum/action/cooldown/vampire/fortitude/on_toggle_on()
	user.set_armor(user.get_armor().add_other_armor(/datum/armor/vampire_fortitude))
	user.add_movespeed_modifier(/datum/movespeed_modifier/vampire_fortitude)

	to_chat(user, span_notice("You enhance your body past it's limits. No one may hurt you any longer."))

/datum/action/cooldown/vampire/fortitude/on_toggle_off()
	user.set_armor(user.get_armor().subtract_other_armor(/datum/armor/vampire_fortitude))
	user.remove_movespeed_modifier(/datum/movespeed_modifier/vampire_fortitude)

	to_chat(user, span_notice("You stop enhancing your body, freed of the burden once more."))
