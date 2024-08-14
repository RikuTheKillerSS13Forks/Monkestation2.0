/datum/antagonist/vampire/proc/set_stat(stat, amount)
	var/old_amount = get_stat(stat)
	if(amount < old_amount)
		CRASH("Attempted to lower vampire stat [stat]. This is undefined behaviour and will lead to issues.")
	var/new_amount = clamp(amount, 0, VAMPIRE_SP_MAXIMUM)
	if(new_amount == old_amount)
		return
	var/delta = new_amount - old_amount
	stats[stat] = new_amount
	spent_stat_points += delta
	available_stat_points -= delta

/datum/antagonist/vampire/proc/adjust_stat(stat, amount)
	set_stat(stat, stats[stat] + amount)

/datum/antagonist/vampire/proc/get_stat(stat)
	var/amount = stats[stat]
	return amount ? amount : 0

/datum/antagonist/vampire/proc/set_stat_points(amount)
	if(amount == stat_points)
		return
	if(amount < stat_points)
		CRASH("Attempted to lower vampire stat points. This is undefined behaviour and will lead to issues.")
	available_stat_points += amount - stat_points
	stat_points = amount

/datum/antagonist/vampire/proc/adjust_stat_points(amount)
	set_stat_points(stat_points + amount)
