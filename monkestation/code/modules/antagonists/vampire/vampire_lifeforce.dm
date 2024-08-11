/datum/antagonist/vampire/proc/update_lifeforce_changes()
	lifeforce_per_second = 0
	for(var/source as anything in lifeforce_changes)
		var/change = lifeforce_changes[source]
		lifeforce_per_second += change

/datum/antagonist/vampire/proc/set_lifeforce_change(source, amount)
	lifeforce_changes[source] = amount
	update_lifeforce_changes()

/datum/antagonist/vampire/proc/clear_lifeforce_change(source)
	lifeforce_changes -= source
	update_lifeforce_changes()

/datum/antagonist/vampire/proc/set_lifeforce(amount)
	var/old_amount = lifeforce

	lifeforce = max(0, amount)

	if(old_amount != lifeforce)
		SEND_SIGNAL(src, COMSIG_VAMPIRE_LIFEFORCE_CHANGED, old_amount, lifeforce)

	if(lifeforce <= 0)
		to_chat(owner.current, span_userdanger("Your body turns to dust as the lifeforce that once animated it runs out!"))
		owner.current.investigate_log("has been dusted by a lack of lifeforce. (vampire)", INVESTIGATE_DEATHS)
		owner.current.dust(drop_items = TRUE)

/datum/antagonist/vampire/proc/adjust_lifeforce(amount)
	set_lifeforce(lifeforce + amount)
