/datum/antagonist/vampire
	var/current_lifeforce = LIFEFORCE_PER_HUMAN
	var/maximum_lifeforce = LIFEFORCE_MAXIMUM
	var/lifeforce_per_second = -LIFEFORCE_THIRST

/datum/antagonist/vampire/proc/set_lifeforce(amount)
	current_lifeforce = clamp(amount, 0, maximum_lifeforce)

/datum/antagonist/vampire/proc/adjust_lifeforce(amount)
	set_lifeforce(current_lifeforce + amount)
