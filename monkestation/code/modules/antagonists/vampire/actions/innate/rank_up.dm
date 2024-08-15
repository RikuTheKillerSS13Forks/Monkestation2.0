/datum/action/cooldown/vampire/rank
	name = "Rank up" //Temp name
	desc = "Grow more ancient with your stored life force, consumes large amounts of life force in the process."

	cooldown_time = 10 SECONDS

/datum/action/cooldown/vampire/rank/Activate()
	. = ..()
	SIGNAL_HANDLER
	var/offset_value = 50 // How much it offsets the calculation
	var/increment_value = 25 // How much it increments per rank
	var/rank = vampire.vampire_rank
	var/calculated_cost = ((rank + 1) * increment_value) + offset_value
	life_cost = calculated_cost
	vampire.rank_up()

/datum/action/cooldown/vampire/rank/Grant(owner)
	. = ..()
	RegisterSignal(vampire, COMSIG_VAMPIRE_RANK_UP, Activate())

/datum/action/cooldown/vampire/rank/Remove(owner)
	. = ..()
	UnregisterSignal(vampire, COMSIG_VAMPIRE_RANK_UP)
