/datum/antagonist/vampire
	var/current_rank = 1
	var/maximum_rank = 8
	var/normal_ability_points = 1
	var/ultimate_ability_points = 0

/datum/antagonist/vampire/proc/rank_up()
	if (current_rank >= maximum_rank)
		return

	current_rank++

	if (current_rank % 4 == 0)
		ultimate_ability_points++
	else
		normal_ability_points++

	update_hud()
