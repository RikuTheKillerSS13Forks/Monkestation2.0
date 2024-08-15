/datum/antagonist/vampire/proc/set_rank(new_rank)
	if(new_rank < vampire_rank)
		CRASH("Attempted to lower vampire rank. This is undefined behaviour and will lead to issues.")

	var/old_rank = vampire_rank
	var/new_rank = clamp(new_rank, 0, VAMPIRE_RANK_MAX)

	if(new_rank == old_rank)
		return

	if(old_rank == 0) // Thrall -> Vampire
		name = "\improper Vampire"
		roundend_category = "Vampire"

	vampire_rank = new_rank

	update_hud()

	set_stat_points(VAMPIRE_SP_PER_RANK * new_rank) // add Caitiff bonus later

	SEND_SIGNAL(src, COMSIG_VAMPIRE_RANK_UP, old_rank)

/datum/antagonist/vampire/proc/rank_up()
	set_rank(vampire_rank + 1)

