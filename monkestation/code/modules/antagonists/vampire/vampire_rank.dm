/datum/antagonist/vampire/proc/set_rank(new_rank)
	if(vampire_rank == new_rank)
		return
	vampire_rank = new_rank

	update_hud()

	name = new_rank == 0 ? "\improper Thrall" : "\improper Vampire"
	roundend_category = new_rank == 0 ? "thralls" : "vampires"

	set_stat_points(VAMPIRE_SP_PER_RANK * new_rank) // add Caitiff bonus later

/datum/antagonist/vampire/proc/rank_up()
	set_rank(vampire_rank + 1)
	SEND_SIGNAL(owner, COMSIG_VAMPIRE_RANK_UP, vampire_rank)

