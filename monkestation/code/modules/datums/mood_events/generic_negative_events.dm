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

/datum/mood_event/gregarious_positive
	description = "I'm making so many new friends!"
	mood_change = 5

/datum/mood_event/retro_headache
	description = "Ugh, my head is pounding."
	mood_change = -5
	timeout = 1 MINUTE

/datum/mood_event/retro_angry
	description = "For fucks sake!"
	mood_change = -5
	timeout = 1 MINUTE

/datum/mood_event/retro_skinloose
	description = "My skin feels weird..."
	mood_change = -3
	timeout = 2 MINUTES

/datum/mood_event/retro_skinoff
	description = "My skin just fell off!"
	mood_change = -8
	timeout = 5 MINUTES
