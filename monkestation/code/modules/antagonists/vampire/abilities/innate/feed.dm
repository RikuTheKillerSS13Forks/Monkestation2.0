/datum/vampire_ability/feed
	name = "Feed"
	desc = "Drink the blood of a victim.\n\
		Victims must be sapient, fresh and at least of alien physiology.\n\
		There is a 30 second grace period if a victim dies or goes comatose.\n\
		A passive grab drinks from the wrist, aggressive or above from the neck.\n\
		Succeeding in a neck feed will automatically put the victim in a neck grab.\n\
		If the victim is wearing a garlic or cross necklace, you can't neck feed.\n\
		Drinking someone dry will enthrall them with you as their master.\n\
		You are unable to talk while feeding.\n\
		Rate scales with Brutality."
	granted_action = /datum/action/cooldown/vampire/feed
