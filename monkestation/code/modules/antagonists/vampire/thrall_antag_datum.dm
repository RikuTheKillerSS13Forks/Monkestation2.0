/datum/antagonist/vampire/thrall
	name = "\improper Thrall"
	roundend_category = "thralls"
	show_in_antagpanel = FALSE
	masquerade_enabled = FALSE
	current_rank = 0
	normal_ability_points = 0

	current_abilities = list(
		/datum/action/cooldown/vampire/mature,
		/datum/action/cooldown/vampire/feed,
		/datum/action/cooldown/vampire/regeneration,
	)

/datum/antagonist/vampire/thrall/rank_up()
	. = ..()
	if (current_rank != 1)
		return // You've already become a vampire.

	name = "\improper Vampire" // Congrats, you're a vampire now.
	roundend_category = "vampires"
	grant_ability(/datum/action/cooldown/vampire/masquerade)

	var/datum/action/antag_info/info_button = info_button_ref?.resolve()
	info_button?.update_antag_name()
