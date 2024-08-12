/datum/antagonist/vampire/proc/set_rank(rank)
	if(vampire_rank == rank)
		return
	vampire_rank = rank

	update_hud()

	name = vampire_rank == 0 ? "\improper Thrall" : "\improper Vampire"
	roundend_category = vampire_rank == 0 ? "thralls" : "vampires"

/datum/antagonist/vampire/proc/rank_up()
	set_rank(vampire_rank + 1)
