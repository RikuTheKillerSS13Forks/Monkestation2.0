/datum/vampire_ability/frenzy
	name = "Frenzy"
	desc = "Enter a state of total bloodlust for 30 seconds.<br> \
	Increases Brutality and Pursuit scaling by 50%.<br> \
	Disables Masquerade until the duration ends.<br> \
	Rapidly drains lifeforce while active.<br> \
	Has a cooldown of 2 minutes.<br> \
	Can be ended early."
	granted_action = /datum/action/cooldown/vampire/frenzy
	stat_reqs = list(VAMPIRE_STAT_BRUTALITY = 30)
