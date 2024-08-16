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

	if(old_amount == lifeforce)
		return

	SEND_SIGNAL(src, COMSIG_VAMPIRE_LIFEFORCE_CHANGED, old_amount)

	update_hud()

	if(lifeforce > LIFEFORCE_MAXIMUM)
		set_lifeforce_change(LIFEFORCE_CHANGE_OVERFLOW, -1 - (lifeforce - LIFEFORCE_MAXIMUM) * 0.05) // lose 1 per second initially and an additional 1 per 20 excess
	else if(old_amount > LIFEFORCE_MAXIMUM)
		clear_lifeforce_change(LIFEFORCE_CHANGE_OVERFLOW)

	if(lifeforce <= 0)
		owner.current.visible_message(
			message = span_danger("[owner.current] lets out a scream of pure terror and turns to dust right before your eyes!"),
			self_message = span_userdanger("Your body turns to dust as the lifeforce that once animated it runs out!"),
			blind_message = span_hear("You hear a scream of pure terror!")
		)
		INVOKE_ASYNC(owner.current, TYPE_PROC_REF(/mob, emote), "scream")
		owner.current.investigate_log("has been dusted by a lack of lifeforce. (vampire)", INVESTIGATE_DEATHS)
		owner.current.dust(drop_items = TRUE)

/datum/antagonist/vampire/proc/adjust_lifeforce(amount)
	set_lifeforce(lifeforce + amount)
