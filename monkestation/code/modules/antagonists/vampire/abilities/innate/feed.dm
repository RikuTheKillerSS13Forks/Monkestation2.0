/datum/vampire_ability/feed
	name = "Feed"
	desc = "Drink the blood of a victim.<br> \
		Victims must be sapient, fresh and at least of alien physiology.<br> \
		There is a 30 second grace period if a victim dies or goes comatose.<br> \
		A passive grab drinks from the wrist, aggressive or above from the neck.<br> \
		Succeeding in a neck feed will automatically put the victim in a neck grab.<br> \
		If the victim is wearing a garlic or cross necklace, you can't neck feed.<br> \
		Drinking someone dry will enthrall them with you as their master.<br> \
		Feed rate scales with Brutality."
	granted_action = /datum/action/cooldown/vampire/feed
