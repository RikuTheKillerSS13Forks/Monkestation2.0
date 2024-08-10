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

/datum/antagonist/vampire/proc/set_life_force(amount)
	life_force = max(0, amount)

	if(life_force <= 0)
		to_chat(owner.current, span_userdanger("Your body turns to dust as the life force that once animated it runs out!"))
		owner.current.investigate_log("has been dusted by a lack of life force. (vampire)", INVESTIGATE_DEATHS)
		owner.current.dust(drop_items = TRUE)

/datum/antagonist/vampire/proc/adjust_life_force(amount)
	set_life_force(life_force + amount)
