/datum/symptom
	// How dangerous the symptom is.
		// 0 = generally helpful (ex: full glass syndrome)
		// 1 = neutral, just flavor text (ex: headache)
		// 2 = minor inconvenience (ex: tourettes)
		// 3 = severe inconvenience (ex: random tripping)
		// 4 = likely to indirectly lead to death (ex: Harlequin Ichthyosis)
		// 5 = will definitely kill you (ex: gibbingtons/necrosis)
	var/badness = EFFECT_DANGER_ANNOYING
	///are we a restricted type
	var/restricted = FALSE
	var/encyclopedia = ""

	/// How many times the effect of this symptom has activated, in total.
	var/cycles = 0

	/// How many times the effect of this symptom has activated since the last deactivation.
	var/current_cycles = 0

	/// Whether or not the symptom is currently active.
	var/active = FALSE

	/// The list of *all* activators for this symptom.
	/// Compatible ones are run through sequentially to check if the symptom is active.
	/// Activators also modify the potency of symptoms after disease progress gives the base amount.
	var/list/datum/symptom_activator/activators = list()

	/// The list of *compatible* activators for this symptom.
	/// These are run through sequentially to check if the symptom is active.
	/// Activators also modify the potency of symptoms after disease progress gives the base amount.
	var/list/datum/symptom_activator/compatible_activators = list()

	/// The potency of the previous cycle.
	/// Useful for passive effects that need to update based on potency.
	var/previous_potency = 0

	/// The minimum amount of potency required to trigger this symptom.
	/// Useful for symptoms that have an immediate impact.
	/// Potency always starts at 1 once this is passed.
	var/minimum_potency = 0.2

	/// The maximum amount of potency this symptom can have.
	/// Anything 0 or below means the symptom is uncapped.
	var/maximum_potency = 0

	/// How much potency doubles the initial potency of this symptom. (except for non-linear scaling)
	/// Used to give the player an idea of how much potency past min_potency they need.
	/// This DOES affect the potency calculations.
	var/potency_scale = 1

/datum/symptom/proc/add_activator(datum/symptom_activator/activator, mob/living/carbon/host, datum/disease/advanced/disease)
	activators += activator
	update_compatibility()

/datum/symptom/proc/remove_activator(datum/symptom_activator/activator, mob/living/carbon/host, datum/disease/advanced/disease)
	activators -= activator
	update_compatibility()

/datum/symptom/proc/update_compatibility(mob/living/carbon/host, datum/disease/advanced/disease)
	for (var/datum/symptom_activator/activator as anything in activators)
		var/incompatibility_reason = activator.check_incompatibility(src, host, disease)

		if (incompatibility_reason && !activator.incompatibility_reason)
			activator.on_remove(src, host, disease)
			compatible_activators -= activator
		else if (!incompatibility_reason)
			activator.on_add(src, host, disease)
			compatible_activators += activator

		activator.incompatibility_reason = incompatibility_reason

/// Returns the final potency amount of this symptom by running through the entire activation string.
/datum/symptom/proc/get_potency(mob/living/carbon/host, datum/disease/advanced/disease, seconds_per_tick)
	var/potency = disease.get_base_potency()

	if (potency <= 0)
		return 0

	for (var/datum/symptom_activator/activator as anything in compatible_activators)
		potency *= activator.get_potency(host, disease, src, potency, seconds_per_tick)
		if (potency <= 0) // this means an activator didn't pass it's check
			return 0

	if (potency < minimum_potency) // initial potency threshold check
		return 0

	potency = (potency - minimum_potency + 1) / potency_scale

	if (maximum_potency > 0 && potency > maximum_potency)
		return maximum_potency

	return max(0, potency) // just in case

/// Runs the effects of this symptom.
/// Returns whether or not the active effect ran successfully.
/datum/symptom/proc/try_run_effect(mob/living/carbon/host, datum/disease/advanced/disease, seconds_per_tick)
	var/potency = get_potency(host, disease, seconds_per_tick)

	if (potency <= 0)
		handle_active(host, disease, potency, seconds_per_tick)
		return FALSE
	handle_inactive(host, disease, potency, seconds_per_tick)
	return TRUE

/// Handles processing for a valid cycle.
/datum/symptom/proc/handle_active(mob/living/carbon/host, datum/disease/advanced/disease, potency, seconds_per_tick)
	if (active)
		active = FALSE
		current_cycles = 0
		deactivate_passive_effect(host, disease)
		SEND_SIGNAL(src, COMSIG_SYMPTOM_DEACTIVATE_PASSIVE, host, disease, seconds_per_tick)
	process_any(host, disease, potency, seconds_per_tick)
	process_inactive(host, disease, seconds_per_tick)
	SEND_SIGNAL(src, COMSIG_SYMPTOM_PROCESS_ANY, host, disease, potency, seconds_per_tick)
	SEND_SIGNAL(src, COMSIG_SYMPTOM_PROCESS_INACTIVE, host, disease, potency, seconds_per_tick)

/// Handles processing for an inactive cycle.
/datum/symptom/proc/handle_inactive(mob/living/carbon/host, datum/disease/advanced/disease, potency, seconds_per_tick)
	cycles++
	current_cycles++
	if (!active)
		active = TRUE
		activate_passive_effect(host, disease)
		SEND_SIGNAL(src, COMSIG_SYMPTOM_ACTIVATE_PASSIVE, host, disease, seconds_per_tick)
	process_any(host, disease, potency, seconds_per_tick)
	process_active(host, disease, seconds_per_tick)
	SEND_SIGNAL(src, COMSIG_SYMPTOM_PROCESS_ANY, host, disease, potency, seconds_per_tick)
	SEND_SIGNAL(src, COMSIG_SYMPTOM_PROCESS_ACTIVE, host, disease, potency, seconds_per_tick)
	previous_potency = potency

/// Only runs on the first valid cycle in a row.
/// Useful for messages and applying passive effects.
/datum/symptom/proc/activate_passive_effect(mob/living/carbon/host, datum/disease/advanced/disease)

/// Only runs on the last valid cycle in a row.
/// Useful for messages and removing passive effects.
/datum/symptom/proc/deactivate_passive_effect(mob/living/carbon/host, datum/disease/advanced/disease)

/// Runs once every valid cycle.
/// This is where the most things should go.
/datum/symptom/proc/process_active(mob/living/carbon/host, datum/disease/advanced/disease, potency, seconds_per_tick)

/// Runs once every invalid cycle.
/// Rarely useful, but it exists.
/datum/symptom/proc/process_inactive(mob/living/carbon/host, datum/disease/advanced/disease, potency, seconds_per_tick)

/// Runs once every cycle regardless of validity.
/datum/symptom/proc/process_any(mob/living/carbon/host, datum/disease/advanced/disease, potency, seconds_per_tick)

/datum/symptom/proc/on_touch(mob/living/carbon/mob, toucher, touched, touch_type)
	// Called when the sufferer of the symptom bumps, is bumped, or is touched by hand.
/datum/symptom/proc/on_death(mob/living/carbon/mob)
	// Called when the sufferer of the symptom dies
///called before speech goes out, returns FALSE if we stop, otherwise returns Edited Message
/datum/symptom/proc/on_speech(mob/living/mob)


/datum/symptom/proc/disable_effect(mob/living/mob, datum/disease/advanced/disease)
	if (cycles > 0)
		deactivate_passive_effect(mob, disease)
