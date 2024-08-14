/datum/antagonist/vampire/proc/set_rank(rank)
	if(vampire_rank == rank)
		return
	vampire_rank = rank

	update_hud()

	name = rank == 0 ? "\improper Thrall" : "\improper Vampire"
	roundend_category = rank == 0 ? "thralls" : "vampires"

	set_stat_points(VAMPIRE_SP_PER_RANK * rank) // add Caitiff bonus later

/datum/antagonist/vampire/proc/rank_up()
	set_rank(vampire_rank + 1)
