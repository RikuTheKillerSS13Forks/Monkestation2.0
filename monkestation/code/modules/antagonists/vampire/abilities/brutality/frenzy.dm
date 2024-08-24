/datum/vampire_ability/frenzy
	name = "Frenzy"
	desc = "Enter a state of total bloodlust for 30 seconds.\n\
	Increases Brutality and Pursuit scaling by 50%.\n\
	Disables Masquerade until the duration ends.\n\
	Rapidly drains lifeforce while active.\n\
	Has a cooldown of 2 minutes.\n\
	Can be ended early."
	granted_action = /datum/action/cooldown/vampire/frenzy
	stat_reqs = list(VAMPIRE_STAT_BRUTALITY = 30)
