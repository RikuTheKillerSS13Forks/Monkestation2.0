/datum/symptom_activator
	var/name = "Base Activator"
	var/desc = "Bug the coders about this."

	/// A rough estimate of how potent this activator is when it passes.
	/// Used to give the player a sense of how options scale.
	/// Updated every time an option is changed.
	var/potency_estimate = 0

	/// If above 0, how many of these you can have on one symptom.
	var/max_count = 1

	/// If not null, used to tell the player why this is incompatible.
	/// Also makes symptoms act as if this activator doesn't exist.
	var/incompatibility_reason

	/// List of *all* modifiers for this activator.
	/// Compatible ones can modify our behaviour in several ways.
	var/list/datum/activator_modifier/modifiers = list()

	/// List of *compatible* modifiers for this activator.
	/// These can modify our behaviour in several ways.
	var/list/datum/activator_modifier/compatible_modifiers = list()

	/// List of activator types this activator is incompatible with.
	var/list/incompatible_activators = list()

	/// List of symptom types this activator is incompatible with.
	var/list/incompatible_symptoms = list()

/datum/symptom_activator/proc/add_modifier(datum/activator_modifier/modifier, datum/symptom/symptom, mob/living/carbon/host, datum/disease/advanced/disease)
	modifiers += modifier
	update_compatibility()

/datum/symptom_activator/proc/remove_modifier(datum/activator_modifier/modifier, datum/symptom/symptom, mob/living/carbon/host, datum/disease/advanced/disease)
	modifiers -= modifier
	update_compatibility()

/datum/symptom_activator/proc/update_compatibility(/datum/symptom/symptom, mob/living/carbon/host, datum/disease/advanced/disease)
	for (var/datum/activator_modifier/modifier as anything in modifiers)
		var/incompatibility_reason = modifier.check_incompatibility(src, symptom, host, disease)

		if (incompatibility_reason && !modifier.incompatibility_reason)
			modifier.on_remove(src, symptom, host, disease)
			compatible_modifiers -= modifier
		else if (!incompatibility_reason)
			modifier.on_add(src, symptom, host, disease)
			compatible_modifiers += modifier

		modifier.incompatibility_reason = incompatibility_reason

/// Called every time the activation string of our symptom changes.
/// If compatible, return null, if not, return the reason why as a string.
/datum/symptom_activator/proc/check_incompatibility(datum/symptom/symptom, mob/living/carbon/host, datum/disease/advanced/disease)
	if (max_count > 0)
		var/self_count = 0
		for (var/activator as anything in symptom.activators)
			if (istype(activator, type))
				self_count++
		if (max_count > self_count)
			return "Maximum amount of \"[name]\" is [max_count]."
	for (var/symptom_type as anything in incompatible_symptoms)
		if (istype(symptom, symptom_type))
			return "Incompatible with [symptom]."
	for (var/activator_type as anything in incompatible_activators)
		for (var/activator as anything in symptom.activators)
			if (istype(activator, activator_type))
				return "Incompatible with [activator]."

/// Returns a copy of this activator.
/datum/symptom_activator/proc/get_copy()
	var/datum/symptom_activator/copy = new type
	for (var/datum/activator_modifier/modifier as anything in modifiers)
		copy.add_modifier(modifier.get_copy())
	return copy

/// Called when the activator is added to a symptom.
/// This is where signals are registered.
/datum/symptom_activator/proc/on_add(datum/symptom/symptom, mob/living/carbon/host, datum/disease/advanced/disease)
	SHOULD_CALL_PARENT(TRUE)

	RegisterSignal(symptom, COMSIG_SYMPTOM_ACTIVATE_PASSIVE, PROC_REF(activate_passive_effect))
	RegisterSignal(symptom, COMSIG_SYMPTOM_DEACTIVATE_PASSIVE, PROC_REF(deactivate_passive_effect))
	RegisterSignal(symptom, COMSIG_SYMPTOM_PROCESS_ANY, PROC_REF(process_active))
	RegisterSignal(symptom, COMSIG_SYMPTOM_PROCESS_ACTIVE, PROC_REF(process_active))
	RegisterSignal(symptom, COMSIG_SYMPTOM_PROCESS_INACTIVE, PROC_REF(process_inactive))

/// Called when the activator is removed from a symptom.
/// This is where signals are registered.
/datum/symptom_activator/proc/on_remove(datum/symptom/symptom, mob/living/carbon/host, datum/disease/advanced/disease)
	SHOULD_CALL_PARENT(TRUE)

	UnregisterSignal(symptom, list(
		COMSIG_SYMPTOM_ACTIVATE_PASSIVE,
		COMSIG_SYMPTOM_DEACTIVATE_PASSIVE,
		COMSIG_SYMPTOM_PROCESS_ANY,
		COMSIG_SYMPTOM_PROCESS_ACTIVE,
		COMSIG_SYMPTOM_PROCESS_INACTIVE,
	))

/// Gets the potency multiplier of this activator.
/// 0 means the activation failed and will stop the execution of the activation string.
/// This acts similarly to process_any and can be used for effects that happen over time.
/// This is the only one called before the symptom activates.
/// The potency value passed to this is the potency value before this activator.
/datum/symptom_activator/proc/get_potency(datum/symptom/symptom, mob/living/carbon/host, datum/disease/advanced/disease, potency, seconds_per_tick)
	return 0

/// Only runs on the first valid cycle in a row.
/// Called after the symptom activates, but before processing.
/datum/symptom_activator/proc/activate_passive_effect(datum/symptom/symptom, mob/living/carbon/host, datum/disease/advanced/disease)
	SIGNAL_HANDLER
	SHOULD_CALL_PARENT(TRUE)
	SEND_SIGNAL(src, COMSIG_ACTIVATOR_ACTIVATE_PASSIVE, symptom, host, disease)

/// Only runs on the last valid cycle in a row.
/// Called after the symptom deactivates, but before processing.
/datum/symptom_activator/proc/deactivate_passive_effect(datum/symptom/symptom, mob/living/carbon/host, datum/disease/advanced/disease)
	SIGNAL_HANDLER
	SHOULD_CALL_PARENT(TRUE)
	SEND_SIGNAL(src, COMSIG_ACTIVATOR_DEACTIVATE_PASSIVE, symptom, host, disease)

/// Runs once every cycle regardless of validity.
/// Called after symptom processing.
/datum/symptom_activator/proc/process_any(datum/symptom/symptom, mob/living/carbon/host, datum/disease/advanced/disease, potency, seconds_per_tick)
	SIGNAL_HANDLER

/// Runs once every valid cycle.
/// Called after symptom processing.
/datum/symptom_activator/proc/process_active(datum/symptom/symptom, mob/living/carbon/host, datum/disease/advanced/disease, potency, seconds_per_tick)
	SIGNAL_HANDLER
	SHOULD_CALL_PARENT(TRUE)
	SEND_SIGNAL(src, COMSIG_ACTIVATOR_PROCESS_ANY, symptom, host, disease, potency, seconds_per_tick) // called here instead of process_any for consistency with symptom call order
	SEND_SIGNAL(src, COMSIG_ACTIVATOR_PROCESS_ACTIVE, symptom, host, disease, potency, seconds_per_tick)

/// Runs once every invalid cycle.
/// Called after symptom processing.
/datum/symptom_activator/proc/process_inactive(datum/symptom/symptom, mob/living/carbon/host, datum/disease/advanced/disease, potency, seconds_per_tick)
	SIGNAL_HANDLER
	SHOULD_CALL_PARENT(TRUE)
	SEND_SIGNAL(src, COMSIG_ACTIVATOR_PROCESS_ANY, symptom, host, disease, potency, seconds_per_tick) // called here instead of process_any for consistency with symptom call order
	SEND_SIGNAL(src, COMSIG_ACTIVATOR_PROCESS_INACTIVE, symptom, host, disease, potency, seconds_per_tick)
