/datum/status_effect/changeling_adrenaline
	id = "changeling_adrenaline"
	show_duration = TRUE
	tick_interval = 0

/datum/status_effect/changeling_adrenaline/tick(seconds_per_tick, times_fired)
	owner.AdjustAllImmobility()
