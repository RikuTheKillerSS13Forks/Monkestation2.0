/datum/mood_event/nanite_sadness
	description = "+++++++HAPPINESS SUPPRESSION+++++++</span>"
	mood_change = -7

/datum/mood_event/nanite_sadness/add_effects(message)
	description = "<span class='warning robot'>+++++++[message]+++++++</span>"

/datum/mood_event/delightful_depression
	description = "Nothing feels the same anymore..."
	mood_change = -20
	timeout = 5 MINUTES

/datum/mood_event/fizzle
	description = "My throat feels itchy and weird."
	mood_change = -3
