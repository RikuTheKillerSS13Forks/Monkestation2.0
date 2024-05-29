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

	/// The list of activators for this symptom.
	/// These are run through sequentially to check if the symptom should process_active.
	/// Activators also modify the potency of symptoms after disease progress gives the base amount.
	var/list/datum/symptom_activator/activators = list()

	/// The potency of the previous cycle.
	/// Useful for passive effects that need to update based on potency.
	var/previous_potency = 0

	/// The minimum amount of potency required to trigger this symptom.
	/// Useful for symptoms that have a high impact even at low potency.
	var/minimum_potency = 0

	/// The maximum amount of potency this symptom can have.
	/// Anything 0 or below means the symptom is uncapped.
	var/maximum_potency = 0

	/// What potency this symptom starts out at, if the min_potency threshold is passed.
	/// The potency is in absolute units, not relative, so if you change potency_scale you may need to change this too.
	var/initial_potency = 1

	/// How much potency roughly doubles the effects of this symptom. (except for non-linear scaling)
	/// Used to give the player an idea of how much potency past min_potency they need.
	/// This DOES affect the potency calculations.
	var/potency_scale = 1

/// Returns the final potency amount of this symptom by running through the entire activation string.
/datum/symptom/proc/get_potency(mob/living/carbon/host, datum/disease/advanced/disease, seconds_per_tick)
	var/potency = disease.get_base_potency()

	if (potency <= 0)
		return 0

	for (var/datum/symptom_activator/activator as anything in activators)
		potency *= activator.get_potency(host, disease, src, potency, seconds_per_tick)
		if (potency <= 0) // this means an activator didn't pass it's check
			return 0

	if (potency < minimum_potency) // initial potency threshold check
		return 0

	potency = (potency - minimum_potency + initial_potency) / potency_scale // simple enough math

	if (maximum_potency > 0 && potency > maximum_potency)
		return maximum_potency

	return max(0, potency) // just in case

/// Runs the effects of this symptom.
/// Returns whether or not the active effect ran successfully.
/datum/symptom/proc/try_run_effect(mob/living/carbon/host, datum/disease/advanced/disease, seconds_per_tick) // does a lot so that other procs dont have to call parent
	var/potency = get_potency(host, disease, seconds_per_tick)

	var/list/compatible_activators = list()

	for (var/datum/symptom_activator/activator as anything in activators)
		if (!activator.incompatibility_reason)
			compatible_activators += activator

	if (potency <= 0)
		if (active)
			active = FALSE
			current_cycles = 0
			deactivate_passive_effect(host, disease)
			SEND_SIGNAL(src, COMSIG_SYMPTOM_DEACTIVATE_PASSIVE, host, disease)
		process_any(host, disease, potency, seconds_per_tick) // called here instead of at the start so that passives, active state and cycles update first
		process_inactive(host, disease, seconds_per_tick)
		for (var/datum/symptom_activator/activator as anything in compatible_activators)
			activator.process_any(host, disease, symptom, potency, seconds_per_tick)
			activator.process_inactive(host, disease, symptom, seconds_per_tick)
		previous_potency = potency
		return FALSE

	cycles++
	current_cycles++
	if (!active)
		active = TRUE
		activate_passive_effect(host, disease)
		SEND_SIGNAL(src, COMSIG_SYMPTOM_ACTIVATE_PASSIVE, host, disease)
	process_any(host, disease, potency, seconds_per_tick)
	process_active(host, disease, seconds_per_tick)
	for (var/datum/symptom_activator/activator as anything in compatible_activators)
		activator.process_any(host, disease, symptom, potency, seconds_per_tick)
		activator.process_active(host, disease, symptom, potency, seconds_per_tick)
	previous_potency = potency
	return TRUE


/datum/symptom/proc/can_run_effect(active_stage = -1, seconds_per_tick)
	if((cycles < max_count || max_count == -1) && (stage <= active_stage || active_stage == -1) && prob(min(chance * seconds_per_tick, max_chance)))
		return 1
	return 0

/// Only runs on the first valid cycle in a row.
/// Useful for messages and applying passive effects.
/datum/symptom/proc/activate_passive_effect(mob/living/carbon/mob, datum/disease/advanced/disease)

/// Only runs on the last valid cycle in a row.
/// Useful for messages and removing passive effects.
/datum/symptom/proc/deactivate_passive_effect(mob/living/carbon/mob, datum/disease/advanced/disease)

/// Runs once every valid cycle.
/// This is where the most things should go.
/datum/symptom/proc/process_active(mob/living/carbon/host, datum/disease/advanced/disease, potency, seconds_per_tick)

/// Runs once every invalid cycle.
/// Rarely useful, but it exists.
/datum/symptom/proc/process_inactive(mob/living/carbon/host, datum/disease/advanced/disease, seconds_per_tick)

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
