/datum/vampire_ability/feed
	name = "Feed"
	desc = "Drink the blood of a victim.\
		Victims must be sapient, fresh and at least of alien physiology.\
		There is a 30 second grace period if a victim dies or goes comatose.\
		A passive grab drinks from the wrist, aggressive or above from the neck.\
		Succeeding in a neck feed will automatically put the victim in a neck grab.\
		If the victim is wearing a garlic or cross necklace, you can't neck feed.\
		Drinking someone dry will enthrall them with you as their master.\
		You are unable to talk while feeding.\
		Rate scales with Brutality."
	granted_action = /datum/action/cooldown/vampire/feed
