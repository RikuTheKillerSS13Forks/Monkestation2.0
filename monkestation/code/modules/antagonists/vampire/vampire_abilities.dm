/// Initializes the list of available vampire abilities.
/datum/antagonist/vampire/proc/init_available_abilities()
	if(available_abilities)
		return

	var/all = subtypesof(/datum/vampire_ability)

	available_abilities = list(
		VAMPIRE_ABILITIES_ALL = all,
		VAMPIRE_ABILITIES_RANK = list()
	)

	for(var/datum/vampire_ability/ability_type as anything in all)
		var/datum/vampire_ability/ability = new ability_type
		if(ability.min_rank > 0)
			available_abilities[VAMPIRE_ABILITIES_RANK] += ability_type
		for(var/stat as anything in ability.stat_reqs)
			available_abilities[stat] += list(ability_type)
		qdel(ability)

/// Checks ability reqs for a the given available_abilities criteria. Criteria are stat name defines or defines under "VAMPIRE_ABILITIES_".
/datum/antagonist/vampire/proc/check_ability_reqs_of_criteria(criteria)
	var/abilities = available_abilities[criteria]
	if(!abilities)
		return
	for(var/ability as anything in abilities)
		check_ability_reqs(ability)

/// Checks the requirements for the given type of ability and grants it to the vampire if they're met.
/datum/antagonist/vampire/proc/check_ability_reqs(datum/vampire_ability/ability_type)
	if(current_abilities[ability_type])
		return

	var/datum/vampire_ability/ability = new ability_type

	if(!ability.check_reqs(src))
		qdel(ability)
		return

	current_abilities[ability_type] = ability
	ability.grant(src)

/// Removes all abilities from the vampire.
/datum/antagonist/vampire/proc/clear_abilities()
	for(var/ability_type as anything in current_abilities)
		var/datum/vampire_ability/ability = current_abilities[ability_type]
		ability.remove()
	current_abilities.Cut()
