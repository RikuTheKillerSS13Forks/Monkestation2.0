/datum/antagonist/vampire/proc/update_life_force_changes()
	life_force_per_second = 0
	for(var/source as anything in life_force_changes)
		var/change = life_force_changes[source]
		life_force_per_second += change

/datum/antagonist/vampire/proc/set_life_force_change(source, amount)
	life_force_changes[source] = amount
	update_life_force_changes()

/datum/antagonist/vampire/proc/clear_life_force_change(source)
	life_force_changes -= source
	update_life_force_changes()
