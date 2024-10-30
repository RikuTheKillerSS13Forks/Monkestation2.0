/datum/species/zombie/infectious
	/// Typepath for the mutant hands to grant our mob.
	var/mutant_hand_type = /obj/item/mutant_hand/zombie

	/// List of action types to grant during init and instances of those actions during runtime.
	var/list/granted_actions = list(
		/datum/action/cooldown/zombie/feast,
		/datum/action/cooldown/zombie/evolve,
	)

	/// How much flesh we've consumed. Used for abilities. Don't modify this directly.
	var/consumed_flesh = 0

/datum/species/zombie/infectious/on_species_gain(mob/living/carbon/C, datum/species/old_species)
	var/list/granted_action_types = granted_actions.Copy()
	granted_actions.Cut() // No reason to use list removal if we can clear it instead.

	for(var/datum/action/action as anything in granted_action_types)
		action = new action(src) // Passing ourselves to the action links it to us, making it self-destruct if the species is lost for any reason.
		granted_actions += action

	. = ..()

	if(C.mind && !C.mind.has_antag_datum(/datum/antagonist/zombie))
		C.mind.add_antag_datum(/datum/antagonist/zombie)

/datum/species/zombie/infectious/on_species_loss(mob/living/carbon/human/C, datum/species/new_species, pref_load)
	granted_actions = null // As mentioned earlier, the actions will self-destruct due to being linked to us. We still need to clear our ref to them, though.

	return ..()

/datum/species/zombie/infectious/proc/set_consumed_flesh(amount)
	var/old_amount = consumed_flesh
	consumed_flesh = clamp(amount, 0, ZOMBIE_FLESH_MAXIMUM)

	if(consumed_flesh != old_amount)
		update_consumed_flesh(old_amount)

/datum/species/zombie/infectious/proc/adjust_consumed_flesh(amount)
	set_consumed_flesh(consumed_flesh + amount)

/datum/species/zombie/infectious/proc/update_consumed_flesh(old_amount)
	SEND_SIGNAL(src, COMSIG_ZOMBIE_FLESH_CHANGED, old_amount, consumed_flesh)
