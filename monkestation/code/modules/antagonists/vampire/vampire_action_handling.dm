/datum/antagonist/vampire
	/// Our current abilities in 'list[action_type] = action_instance' format. During init this is a basic list of action types instead.
	var/list/current_actions = list(
		/datum/action/cooldown/vampire/mature,
		/datum/action/cooldown/vampire/feed,
		/datum/action/cooldown/vampire/regeneration,
		/datum/action/cooldown/vampire/masquerade,
	)

/datum/antagonist/vampire/proc/grant_actions()
	for (var/action_type in current_actions)
		var/datum/action/cooldown/vampire/action = current_actions[action_type]
		action.Grant(user)

/datum/antagonist/vampire/proc/remove_actions()
	for (var/action_type in current_actions)
		var/datum/action/cooldown/vampire/action = current_actions[action_type]
		action.Remove(user)

/datum/antagonist/vampire/proc/grant_action(type)
	if (current_actions[type])
		return

	var/datum/action/cooldown/vampire/new_action = new type(src)
	current_actions[type] = new_action

	if (user)
		new_action.Grant(user)

/datum/antagonist/vampire/proc/remove_action(type)
	qdel(current_actions[type])
	current_actions[type] = null

/datum/antagonist/vampire/proc/get_action(type)
	return current_actions[type]
