/datum/symptom_activator
	var/name = "Base Activator"
	var/desc = "Bug the coders about this."

	/// A rough estimate of how potent this activator is when it passes.
	/// Used to give the player a sense of how options scale.
	/// Updated every time an option is changed.
	var/potency_estimate = 0

	/// If not null, used to tell the player why this is incompatible.
	/// Also makes all potency checks pass with a value of 1.
	var/incompatibility_reason

	/// List of modifiers for this activator.
	/// These can modify our behaviour in several ways.
	var/list/datum/activator_modifier/modifiers = list()

	/// List of activators this activator is incompatible with.
	/// Can include itself, which makes it so you can only have one.
	var/list/incompatible_activators = list()

	/// List of symptoms this activator is incompatible with.
	var/list/incompatible_symptoms = list()

/// Called every time the activation string of our symptom changes.
/// If compatible, return null, if not, return the reason why as a string.
/datum/symptom_activator/proc/check_compatibility(mob/living/carbon/host, datum/disease/advanced/disease, datum/symptom/symptom)
	SHOULD_CALL_PARENT
	for (var/symptom_type as anything in incompatible_symptoms)
		if (istype(symptom, symptom_type))
			return "Incompatible with [symptom]."
	for (var/activator_type as anything in incompatible_activators)
		for (var/activator as anything in symptom.activators)
			if (istype(activator, activator_type))
				return "Incompatible with [activator]."

/// Called when the activator is added to a symptom.
/// This is where you register signals.
/datum/symptom_activator/proc/on_add(mob/living/carbon/host, datum/disease/advanced/disease, datum/symptom/symptom)

/// Called when the activator is removed from a symptom.
/// This is where you unregister signals.
/datum/symptom_activator/proc/on_remove(mob/living/carbon/host, datum/disease/advanced/disease, datum/symptom/symptom)

/// Gets the potency multiplier of this activator.
/// 0 means the activation failed and will stop the execution of the activation string.
/// This acts similarly to process_any and can be used for effects that happen over time.
/// This is the only one called before the symptom activates.
/// The potency value passed to this is the potency value before this activator.
/datum/symptom_activator/proc/get_potency(mob/living/carbon/host, datum/disease/advanced/disease, datum/symptom/symptom, potency, seconds_per_tick)
	return 0

/// Only runs on the first valid cycle in a row.
/// Called after the symptom activates, but before processing.
/datum/symptom_activator/proc/activate_passive_effect(mob/living/carbon/mob, datum/disease/advanced/disease)

/// Only runs on the last valid cycle in a row.
/// Called after the symptom deactivates, but before processing.
/datum/symptom_activator/proc/deactivate_passive_effect(mob/living/carbon/mob, datum/disease/advanced/disease)

/// Runs once every cycle regardless of validity.
/// Called after symptom processing.
/datum/symptom_activator/proc/process_any(mob/living/carbon/host, datum/disease/advanced/disease, datum/symptom/symptom, potency, seconds_per_tick)

/// Runs once every valid cycle.
/// Called after symptom processing.
/datum/symptom_activator/proc/process_active(mob/living/carbon/host, datum/disease/advanced/disease, datum/symptom/symptom, potency, seconds_per_tick)

/// Runs once every invalid cycle.
/// Called after symptom processing.
/datum/symptom_activator/proc/process_inactive(mob/living/carbon/host, datum/disease/advanced/disease, datum/symptom/symptom, seconds_per_tick)
