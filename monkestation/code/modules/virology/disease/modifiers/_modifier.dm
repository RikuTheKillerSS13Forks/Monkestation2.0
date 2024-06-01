/datum/activator_modifier
	var/name = "Base Modifier"
	var/desc = "WHAT HAVE YOU DONE?!"

	/// If above 0, how many of these you can have on one activator.
	var/max_count = 1

	/// If not null, used to tell the player why this is incompatible.
	/// Makes this modifier have no effect on the activator it's attached to.
	var/incompatibility_reason

	/// List of modifier types this modifier is incompatible with.
	/// Can include itself, which makes it so you can only have one.
	var/list/incompatible_modifiers = list()

	/// List of activator types this modifier is incompatible with.
	var/list/incompatible_activators = list()

	/// List of symptom types this modifier is incompatible with.
	var/list/incompatible_symptoms = list()

/// Called every time the activation string of our symptom changes.
/// If compatible, return null, if not, return the reason why as a string.
/datum/symptom_activator/proc/check_incompatibility(datum/symptom_activator/activator, datum/symptom/symptom, mob/living/carbon/host, datum/disease/advanced/disease)
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
		if (istype(activator, activator_type))
			return "Incompatible with [activator]."
	for (var/modifier_type as anything in incompatible_modifiers)
		for (var/modifier as anything in activator.modifiers)
			if (istype(modifier, modifier_type))
				return "Incompatible with [modifier]."

/// Returns a copy of this modifier.
/datum/activator_modifier/get_copy()
	var/datum/activator_modifier/copy = new type
	return copy

/// Called when the modifier is added to an activator.
/// This is where signals should be registered.
/datum/activator_modifier/proc/on_add(datum/symptom_activator/activator, datum/symptom/symptom, mob/living/carbon/host, datum/disease/advanced/disease)
	SHOULD_CALL_PARENT(TRUE)

	RegisterSignal(activator, COMSIG_ACTIVATOR_ACTIVATE_PASSIVE, PROC_REF(activate_passive_effect))
	RegisterSignal(activator, COMSIG_ACTIVATOR_DEACTIVATE_PASSIVE, PROC_REF(deactivate_passive_effect))
	RegisterSignal(activator, COMSIG_ACTIVATOR_PROCESS_ANY, PROC_REF(process_any))
	RegisterSignal(activator, COMSIG_ACTIVATOR_PROCESS_ACTIVE, PROC_REF(process_active))
	RegisterSignal(activator, COMSIG_ACTIVATOR_PROCESS_INACTIVE, PROC_REF(process_inactive))

/// Called when the modifier is removed from an activator.
/// This is where signals should be unregistered.
/datum/activator_modifier/proc/on_remove(datum/symptom_activator/activator, datum/symptom/symptom, mob/living/carbon/host, datum/disease/advanced/disease)
	SHOULD_CALL_PARENT(TRUE)

	UnregisterSignal(activator, list(
		COMSIG_ACTIVATOR_ACTIVATE_PASSIVE,
		COMSIG_ACTIVATOR_DEACTIVATE_PASSIVE,
		COMSIG_ACTIVATOR_PROCESS_ANY,
		COMSIG_ACTIVATOR_PROCESS_ACTIVE,
		COMSIG_ACTIVATOR_PROCESS_INACTIVE,
	))

/// Only runs on the first valid cycle in a row.
/// Called after the activator activates, but before processing.
/datum/activator_modifier/proc/activate_passive_effect(datum/symptom_activator/activator, datum/symptom/symptom, mob/living/carbon/host, datum/disease/advanced/disease)
	SIGNAL_HANDLER

/// Only runs on the last valid cycle in a row.
/// Called after the activator deactivates, but before processing.
/datum/activator_modifier/proc/deactivate_passive_effect(datum/symptom_activator/activator, datum/symptom/symptom, mob/living/carbon/host, datum/disease/advanced/disease)
	SIGNAL_HANDLER

/// Runs once every cycle regardless of validity.
/// Called after activator processing.
/datum/activator_modifier/proc/process_any(datum/symptom_activator/activator, datum/symptom/symptom, mob/living/carbon/host, datum/disease/advanced/disease, potency, seconds_per_tick)
	SIGNAL_HANDLER

/// Runs once every valid cycle.
/// Called after activator processing.
/datum/activator_modifier/proc/process_active(datum/symptom_activator/activator, datum/symptom/symptom, mob/living/carbon/host, datum/disease/advanced/disease, potency, seconds_per_tick)
	SIGNAL_HANDLER

/// Runs once every invalid cycle.
/// Called after activator processing.
/datum/activator_modifier/proc/process_inactive(datum/symptom_activator/activator, datum/symptom/symptom, mob/living/carbon/host, datum/disease/advanced/disease, potency, seconds_per_tick)
	SIGNAL_HANDLER

