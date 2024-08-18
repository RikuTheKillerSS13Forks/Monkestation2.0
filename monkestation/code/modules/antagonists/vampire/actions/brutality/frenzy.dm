/datum/action/cooldown/vampire/frenzy
	name = "Frenzy"
	desc = "Enter a state of total bloodlust. Rapidly drains lifeforce while active."
	cooldown_time = 2 MINUTES
	toggleable = TRUE
	constant_life_cost = LIFEFORCE_PER_HUMAN / 60 // the duration is 30 seconds so this should drain roughly 50 lifeforce

/datum/action/cooldown/vampire/frenzy/on_toggle_on()
	vampire.set_stat_multiplier(VAMPIRE_STAT_BRUTALITY, REF(src), 1.5)
	vampire.set_stat_multiplier(VAMPIRE_STAT_PURSUIT, REF(src), 1.5)
	ADD_TRAIT(vampire, TRAIT_VAMPIRE_FRENZY)

/datum/action/cooldown/vampire/frenzy/on_toggle_off()
	vampire.clear_stat_multiplier(VAMPIRE_STAT_BRUTALITY, REF(src))
	REMOVE_TRAIT(vampire, TRAIT_VAMPIRE_FRENZY)
