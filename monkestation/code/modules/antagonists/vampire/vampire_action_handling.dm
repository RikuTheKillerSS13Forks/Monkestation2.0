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
		if (istype(action)) // In case it's VAMPIRE_ABILITY_BLOCKED
			action.Grant(user)

/datum/antagonist/vampire/proc/remove_abilities()
	for (var/action_type in current_abilities)
		var/datum/action/cooldown/vampire/action = current_abilities[action_type]
		if (istype(action)) // In case it's VAMPIRE_ABILITY_BLOCKED
			action.Remove(user)

/datum/antagonist/vampire/proc/grant_ability(type)
	if (current_abilities[type] != null)
		return

	var/datum/action/cooldown/vampire/new_action = new type(src)
	current_abilities[type] = new_action

	if (user)
		new_action.Grant(user)

/datum/antagonist/vampire/proc/remove_ability(type)
	if (current_abilities[type] == VAMPIRE_ABILITY_BLOCKED)
		return
	qdel(current_abilities[type])
	current_abilities[type] = null

/datum/antagonist/vampire/proc/get_ability(type)
	var/datum/action/cooldown/vampire/action = current_abilities[type]
	return istype(action) ? action : null

/datum/antagonist/vampire/proc/block_ability(type)
	qdel(current_abilities[type])
	current_abilities[type] = VAMPIRE_ABILITY_BLOCKED

/datum/antagonist/vampire/proc/unblock_ability(type)
	if (current_abilities[type] != VAMPIRE_ABILITY_BLOCKED)
		return
	current_abilities[type] = null
