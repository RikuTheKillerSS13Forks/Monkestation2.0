/datum/antagonist/vampire
	/// Our current abilities in 'list[action_type] = action_instance' format. During init this is a basic list of action types instead.
	/// Not everything here is guaranteed to be an action, due to VAMPIRE_ABILITY_BLOCKED being a possible value.
	var/list/current_abilities = list(
		/datum/action/cooldown/vampire/mature,
		/datum/action/cooldown/vampire/feed,
		/datum/action/cooldown/vampire/regeneration,
		/datum/action/cooldown/vampire/masquerade,
	)

/datum/antagonist/vampire/proc/grant_abilities()
	for (var/action_type in current_abilities)
		var/datum/action/cooldown/vampire/action = current_abilities[action_type]
		action.Grant(user)

/datum/antagonist/vampire/proc/remove_abilities()
	for (var/action_type in current_abilities)
		var/datum/action/cooldown/vampire/action = current_abilities[action_type]
		action.Remove(user)

/datum/antagonist/vampire/proc/grant_ability(type)
	if (current_abilities[type])
		return

	var/datum/action/cooldown/vampire/new_action = new type(src)
	current_abilities[type] = new_action

	if (user)
		new_action.Grant(user)

/datum/antagonist/vampire/proc/remove_ability(type)
	qdel(current_abilities[type])
	current_abilities[type] = null

/datum/antagonist/vampire/proc/get_ability(type)
	return current_abilities[type]
