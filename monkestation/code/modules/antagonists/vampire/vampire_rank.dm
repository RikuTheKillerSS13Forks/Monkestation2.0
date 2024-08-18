/datum/antagonist/vampire/proc/set_rank(new_rank, force_update = FALSE)
	if(new_rank < vampire_rank)
		CRASH("Attempted to lower vampire rank. This is undefined behaviour and will lead to issues.")

	var/old_rank = vampire_rank
	new_rank = clamp(new_rank, 0, VAMPIRE_RANK_MAX)

	if(new_rank == old_rank && !force_update)
		return

	if(old_rank == 0) // Thrall -> Vampire
		name = "\improper Vampire"
		roundend_category = "Vampire"

	vampire_rank = new_rank

	update_hud()

	var/new_stat_points = VAMPIRE_SP_PER_RANK * new_rank
	if(clan == VAMPIRE_CLAN_CAITIFF)
		new_stat_points += VAMPIRE_SP_CAITIFF_BONUS * new_rank
	set_stat_points(new_stat_points)

	check_ability_reqs_of_criteria(VAMPIRE_ABILITIES_RANK)

	SEND_SIGNAL(src, COMSIG_VAMPIRE_RANK_CHANGED, old_rank)
