#define DECAY_TIME 600 // Number of seconds until 'lifeforce_drained' goes from FEED_LIMIT to 0
#define FEED_LIMIT LIFEFORCE_PER_HUMAN
#define DECAY_RATE (FEED_LIMIT / DECAY_TIME)

// A component applied to the mind, makes it so you can't drain more than 1 person worth of lifeforce from someone.
// I can't afford to have vampires just drain the same changeling for 5000 blood, it completely breaks balancing.
// This can be entirely bypassed by directly feeding from a vampire.
/datum/component/feed_limit
	dupe_mode = COMPONENT_DUPE_UNIQUE

	/// The amount of blood drained from us so far. Decays over time.
	var/lifeforce_drained = 0

	/// Whether we've reached the limit.
	var/limit_reached = FALSE

/datum/component/feed_limit/Initialize(...)
	if (!istype(parent, /datum/mind))
		stack_trace("Tried to add a vampire feed limit to a non-mind datum. This should NEVER happen.")
		return COMPONENT_INCOMPATIBLE

/datum/component/feed_limit/RegisterWithParent()
	RegisterSignal(parent, COMSIG_MIND_TRANSFERRED, PROC_REF(on_mind_transferred))
	RegisterSignal(parent, COMSIG_ANTAGONIST_GAINED, PROC_REF(on_antagonist_gained))

	var/datum/mind/mind = parent
	if (mind.current)
		RegisterWithMob(mind.current)

/datum/component/feed_limit/UnregisterFromParent()
	UnregisterSignal(parent, list(COMSIG_MIND_TRANSFERRED, COMSIG_ANTAGONIST_GAINED))

	var/datum/mind/mind = parent
	if (mind.current)
		UnregisterFromMob(mind.current)

/datum/component/feed_limit/proc/RegisterWithMob(mob/living/target)
	if (!isliving(target))
		return

	RegisterSignal(target, COMSIG_ATOM_EXAMINE, PROC_REF(on_examine))
	RegisterSignal(target, COMSIG_LIVING_LIFE, PROC_REF(on_life))

	if (limit_reached)
		target.add_mood_event("feed_limit", /datum/mood_event/feed_limit)

/datum/component/feed_limit/proc/UnregisterFromMob(mob/living/target)
	if (!isliving(target))
		return

	UnregisterSignal(target, list(COMSIG_ATOM_EXAMINE, COMSIG_LIVING_LIFE))

	target.clear_mood_event("feed_limit")

/datum/component/feed_limit/proc/on_mind_transferred(datum/mind/mind, mob/previous_body)
	SIGNAL_HANDLER
	UnregisterFromMob(previous_body)
	RegisterWithMob(mind.current)

/datum/component/feed_limit/proc/on_antagonist_gained(datum/mind/mind, datum/antagonist/antagonist)
	SIGNAL_HANDLER
	if (istype(antagonist, /datum/antagonist/vampire))
		qdel(src)

/datum/component/feed_limit/proc/on_examine(mob/living/target, mob/examiner, list/examine_text)
	SIGNAL_HANDLER
	if (!IS_VAMPIRE(examiner))
		return
	if (limit_reached)
		examine_text += span_cult("[target.p_Their()] lifeforce is extremely weak. Feeding on [target.p_them()] now would serve no purpose.")
		return
	if (lifeforce_drained > FEED_LIMIT * 0.5)
		examine_text += span_cult("[target.p_Their()] lifeforce is weakened. Feeding on [target.p_them()] now would be less satiating than usual.")

/datum/component/feed_limit/proc/increment(mob/living/target, mob/living/carbon/human/vampire, amount)
	SIGNAL_HANDLER
	if (limit_reached)
		return

	lifeforce_drained = min(lifeforce_drained + amount, FEED_LIMIT)
	if (lifeforce_drained < FEED_LIMIT)
		return

	limit_reached = TRUE

	target.balloon_alert(vampire, "lifeforce drained!")
	to_chat(vampire, span_cult("[target]'s lifeforce has become too weak to be of any further use. You'll have to wait 10 minutes before gaining any more from them."))

	target.add_mood_event("feed_limit", /datum/mood_event/feed_limit)
	to_chat(target, span_warning("You feel... off."))

/datum/component/feed_limit/proc/on_life(mob/living/target, seconds_per_tick, times_fired)
	SIGNAL_HANDLER
	lifeforce_drained -= DECAY_RATE * DELTA_WORLD_TIME(SSmobs)
	if (lifeforce_drained <= 0)
		qdel(src)

/datum/component/feed_limit/proc/get_remaining_lifeforce()
	return limit_reached ? 0 : (FEED_LIMIT - lifeforce_drained)

#undef DECAY_TIME
#undef DECAY_RATE
