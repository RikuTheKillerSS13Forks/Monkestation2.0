/datum/mood_event/nanite_happiness
	description = "<span class='nicegreen robot'>+++++++HAPPINESS ENHANCEMENT+++++++</span>"
	mood_change = 7

/datum/mood_event/nanite_happiness/add_effects(message)
	description = "<span class='nicegreen robot'>+++++++[message]+++++++</span>"

/datum/mood_event/monster_hunter
	description = "Glory to the hunt."
	mood_change = 10
	hidden = TRUE

/datum/mood_event/delightful // the mood_change for this is procedural
	description = "Man, everything just feels so great right now!"

/datum/mood_event/delightful/add_effects(change)
	mood_change = change

/datum/mood_event/gregarious_negative
	description = "I feel so alone..."
	mood_change = -10
