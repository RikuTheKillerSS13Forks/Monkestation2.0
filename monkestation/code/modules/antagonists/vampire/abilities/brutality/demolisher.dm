/datum/vampire_ability/demolisher
	name = "Demolisher"
	desc = "You can tear down walls with your bare hands."
	stat_reqs = list(VAMPIRE_STAT_BRUTALITY = 60)

/datum/vampire_ability/demolisher/on_grant_mob()
	AddElement(user, /datum/element/wall_tearer, allow_reinforced = TRUE, tear_time = 1 SECOND) // capstone ability, it's very strong for a reason

/datum/vampire_ability/demolisher/on_remove_mob()
	RemoveElement(user, /datum/element/wall_tearer, allow_reinforced = TRUE, tear_time = 1 SECOND)
