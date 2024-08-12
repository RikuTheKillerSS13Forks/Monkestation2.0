/datum/antagonist/vampire/proc/set_rank(rank)
	vampire_rank = rank
	update_hud()

/datum/antagonist/vampire/proc/rank_up()
	vampire_rank++
