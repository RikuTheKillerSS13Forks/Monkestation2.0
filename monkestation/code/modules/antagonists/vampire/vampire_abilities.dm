/// Initializes the list of available vampire abilities. SHOULD ONLY BE CALLED ONCE.
/datum/antagonist/vampire/proc/init_available_abilities()
	var/all = subtypesof(/datum/vampire_ability)

	var/result = list(
		VAMPIRE_ABILITIES_ALL = all,
		VAMPIRE_ABILITIES_RANK = list()
	)

	for(var/datum/vampire_ability/ability as anything in all)
		if(initial(ability.min_rank) > 0)
			result[VAMPIRE_ABILITIES_RANK] += ability
		for(var/stat as anything in initial(ability.stat_reqs))
			result[stat] += list(stat)

	return result

/// Checks ability reqs for a the given available_abilities criteria. Criteria are stat name defines or defines under "VAMPIRE_ABILITIES_".
/datum/antagonist/vampire/proc/check_ability_reqs_of_criteria(criteria)
	var/abilities = available_abilities[criteria]
	if(!abilities)
		return
	for(var/ability as anything in abilities)
		check_ability_reqs(ability)

/// Checks the requirements for the given type of ability and grants it to the vampire if they're met.
/datum/antagonist/vampire/proc/check_ability_reqs(/datum/vampire_ability/ability_type)
	if(current_abilities[ability_type])
		return

	if(vampire_rank < initial(ability_type.min_rank))
		return

	var/clan_req = initial(ability_type.clan_req)
	if(clan_req && clan != clan_req)
		return

	var/list/stat_reqs = initial(ability_type.stat_reqs)
	for(var/stat as anything in stat_reqs)
		if(get_stat(stat) < stat_reqs[stat])
			return

	var/datum/vampire_ability/ability = new ability_type
	current_abilities[ability_type] = ability
	ability.grant(src)

/// Removes all abilities from the vampire.
/datum/antagonist/vampire/proc/clear_abilities()
	for(var/ability_type as anything in current_abilities)
		var/datum/vampire_ability/ability = current_abilities[ability_type]
		ability.remove()
