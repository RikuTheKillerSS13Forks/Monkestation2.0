/datum/action/cooldown/vampire/mature
	name = "Mature"
	desc = "Grow ever closer to the ancient nature of your lineage."
	button_icon_state = "power_mature"
	cooldown_time = 5 SECONDS
	lifeforce_cost = 150 // This decides how much lifeforce it takes for thralls to become vampires.

/datum/action/cooldown/vampire/mature/IsAvailable(feedback)
	. = ..()
	if (antag_datum.current_rank > 0 && !antag_datum.clan)
		if (feedback)
			user.balloon_alert("form a clan vow!")
			to_chat(user, span_cult("Your power remains at a standstill. You must first make a choice."))
		return FALSE

/datum/action/cooldown/vampire/mature/Activate(atom/target)
	. = ..()
	antag_datum.rank_up()
	to_chat(user, span_cult("Your body trembles as every fibre of your very being is invigorated with newfound power. You've ascended beyond your former self."))
