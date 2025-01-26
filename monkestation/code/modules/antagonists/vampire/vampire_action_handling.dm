/datum/antagonist/vampire
	/// Our current abilities in 'list[action_type] = action_instance' format. During init this is a basic list of action types instead.
	var/list/current_abilities = list(
		/datum/action/cooldown/vampire/mature,
		/datum/action/cooldown/vampire/feed,
		/datum/action/cooldown/vampire/regeneration,
		/datum/action/cooldown/vampire/masquerade,
	)

/datum/antagonist/vampire/proc/grant_ability(type)
	var/datum/action/cooldown/vampire/new_action = new type(src)
	current_abilities[type] = new_action

	if (user)
		new_action.Grant(user)

