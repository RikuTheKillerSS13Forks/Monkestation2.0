#define WRIST_FEED "wrist"
#define NECK_FEED "neck"

/datum/action/cooldown/vampire/feed
	name = "Feed"
	desc = "Drink the blood of a victim, a more aggressive grab feeds directly from the carotid artery and allows you to enthrall your victim if they were alive when you started feeding."
	button_icon_state = "power_feed"
	cooldown_time = 1 SECOND

	/// If we're currently feeding, used for sanity.
	var/is_feeding = FALSE

	/// The amount of blood a target has since our last feed, this loops and lets us not spam alerts of low blood.
	var/target_blood = BLOOD_VOLUME_MAX_LETHAL

	/// Whether the target was alive or not when we started feeding.
	var/started_alive = TRUE

	/// Whether the feed was started with a passive (wrist feed) or aggressive (neck feed) grab.
	var/feed_type = WRIST_FEED

	/// Bodypart zone we bit into.
	var/target_zone

	/// Weakref to the victim.
	var/datum/weakref/victim_ref

/datum/action/cooldown/vampire/feed/IsAvailable(feedback)
	if(!..())
		return FALSE

	var/mob/living/carbon/victim = owner.pulling

	if(is_feeding) // you need to be able to stop feeding
		return TRUE

	if(!istype(victim))
		if(feedback)
			owner.balloon_alert(owner, "needs grab!")
		return FALSE

	if(victim.blood_volume <= 0 || victim.get_blood_id() != /datum/reagent/blood) // this makes mobs with exotic blood or no blood immune to feeding
		if(feedback)
			owner.balloon_alert(owner, "no blood!")
		return FALSE

	if(victim.stat == DEAD && victim.timeofdeath + 30 SECONDS < world.time) // succumbing doesn't stop the vampire from getting a meal, only from enthralling you
		if(feedback)
			owner.balloon_alert(owner, "too decayed!")
		return FALSE

	feed_type = owner.grab_state == GRAB_PASSIVE ? WRIST_FEED : NECK_FEED

	if(!get_suitable_limb(victim))
		if(feedback)
			owner.balloon_alert(owner, "no suitable [feed_type]!")
		return FALSE

	return TRUE

/datum/action/cooldown/vampire/feed/Activate(atom/target)
	if(is_feeding)
		stop_feeding(victim_ref.resolve(), forced = FALSE) // victim_ref should never be null if is_feeding is true
		return ..()

	var/mob/living/carbon/victim = owner.pulling

	if(feed_type == WRIST_FEED)
		to_chat(victim, span_danger("You feel [owner] tug at your wrist."))
	else
		to_chat(victim, span_bolddanger("[owner] opens [owner.p_their()] mouth and closes in on your neck!"))

	if(!do_after(owner, 2 SECONDS, victim)) // should prevent duplicate feeds as you can't initiate multiple do_afters on a target
		return

	is_feeding = TRUE // you've secured the meal, nice
	started_alive = victim.stat != DEAD
	victim_ref = WEAKREF(victim)

	RegisterSignal(victim, COMSIG_LIVING_LIFE, PROC_REF(on_life))
	RegisterSignal(victim, COMSIG_QDELETING, PROC_REF(on_victim_qdel))
	RegisterSignal(victim, COMSIG_CARBON_REMOVE_LIMB, PROC_REF(check_removed_limb))
	RegisterSignal(victim, COMSIG_MOVABLE_MOVED, PROC_REF(check_adjacent))
	RegisterSignal(owner, COMSIG_MOVABLE_MOVED, PROC_REF(check_adjacent))

	if(feed_type == WRIST_FEED)
		owner.visible_message(
			message = span_danger("[owner] lifts [victim]'s wrist to [owner.p_their()] mouth and bites into it!"),
			self_message = span_notice("You lift [victim]'s wrist up to your mouth and bite into it."),
			ignored_mobs = victim
			)
		to_chat(victim, span_danger("[owner] lifts your wrist up to [owner.p_their()] mouth and bites into it!"))

		if(!HAS_TRAIT(victim, TRAIT_ANALGESIA))
			victim.emote("flinch")
	else
		owner.visible_message(
			message = span_bolddanger("[owner] bites into [victim]'s neck!"),
			self_message = span_boldnotice("You bite into [victim]'s neck!"),
			ignored_mobs = victim
		)
		to_chat(victim, span_userdanger("[owner] bites into your neck!"))

		if(!HAS_TRAIT(victim, TRAIT_ANALGESIA))
			victim.emote("scream")

	return ..()

/datum/action/cooldown/vampire/feed/Remove(mob/removed_from)
	if(is_feeding)
		stop_feeding(victim_ref.resolve(), forced = TRUE) // victim_ref should never be null if is_feeding is true
	return ..()

/datum/action/cooldown/vampire/feed/proc/on_victim_qdel(mob/living/carbon/victim)
	SIGNAL_HANDLER

	stop_feeding(victim, forced = TRUE)

/datum/action/cooldown/vampire/feed/proc/stop_feeding(mob/living/carbon/victim, forced = FALSE, bodypart_override = null)
	if(!is_feeding)
		return

	is_feeding = FALSE
	target_zone = null
	victim_ref = null

	UnregisterSignal(victim, list(COMSIG_LIVING_LIFE, COMSIG_QDELETING, COMSIG_CARBON_REMOVE_LIMB, COMSIG_MOVABLE_MOVED))
	UnregisterSignal(owner, COMSIG_MOVABLE_MOVED)

	var/obj/item/bodypart/target_limb = bodypart_override ? bodypart_override : (is_suitable_limb(victim, target_zone) ? victim.get_bodypart(target_zone) : null)

	if(forced)
		owner.visible_message(
			message = span_danger("[owner]'s fangs are ripped out of [victim]'s [feed_type]!"),
			self_message = span_danger("Your fangs are ripped out of [victim]'s [feed_type]!"),
			ignored_mobs = victim
		)
		to_chat(victim, span_danger("[owner]'s fangs are ripped out of your [feed_type]!"))

		if(target_limb)
			victim.cause_wound_of_type_and_severity(WOUND_PIERCE, target_limb, WOUND_SEVERITY_MODERATE)
	else
		owner.visible_message(
			message = span_notice("[owner] releases [owner.p_their()] bite on [victim]'s [feed_type]."),
			self_message = span_notice("You release your bite on [victim]'s [feed_type]."),
			ignored_mobs = victim
		)
		to_chat(victim, span_notice("[owner] releases [owner.p_their()] bite on your [feed_type]."))

/datum/action/cooldown/vampire/feed/proc/on_life(mob/living/carbon/victim, seconds_per_tick, times_fired)
	SIGNAL_HANDLER

	if(!check_adjacent()) // handles its own balloon alert and stop_feeding
		return

	if(victim.get_blood_id() != /datum/reagent/blood)
		owner.balloon_alert(owner, "incompatible blood!")
		stop_feeding(victim, forced = FALSE)
		return

	if(!is_suitable_limb(victim, target_zone))
		owner.balloon_alert(owner, "limb gone!")
		stop_feeding(victim, forced = TRUE)
		return

	if(victim.blood_volume <= 0)
		INVOKE_ASYNC(src, PROC_REF(attempt_enthrall), victim)
		return

	var/blood_to_drain = min(victim.blood_volume, BLOOD_VOLUME_NORMAL / (feed_type == WRIST_FEED ? 60 : 30) * seconds_per_tick) // add brutality scaling later

	victim.blood_volume -= blood_to_drain
	vampire.adjust_lifeforce(blood_to_drain * BLOOD_TO_LIFEFORCE) // finally some good fucking food

/datum/action/cooldown/vampire/feed/proc/is_suitable_limb(mob/living/carbon/victim, zone)
	var/obj/item/bodypart/limb = victim.get_bodypart(zone)
	return limb && (limb.biological_state & BIO_BLOODED)

/datum/action/cooldown/vampire/feed/proc/get_suitable_limb(mob/living/carbon/victim)
	if(feed_type == WRIST_FEED)
		if(is_suitable_limb(victim, BODY_ZONE_R_ARM))
			target_zone = BODY_ZONE_R_ARM
			return TRUE
		if(is_suitable_limb(victim, BODY_ZONE_L_ARM))
			target_zone = BODY_ZONE_L_ARM
			return TRUE
	else
		if(is_suitable_limb(victim, BODY_ZONE_HEAD)) // results in your feed getting canceled if someone decapitates your victim, which is funny
			target_zone = BODY_ZONE_HEAD
			return TRUE
		if(is_suitable_limb(victim, BODY_ZONE_CHEST)) // but you can still feed straight from a neck stub, might add a mood event for this later
			target_zone = BODY_ZONE_CHEST
			return TRUE
	return FALSE

/datum/action/cooldown/vampire/feed/proc/check_adjacent(datum/source)
	SIGNAL_HANDLER

	var/victim = victim_ref?.resolve()

	if(!victim || (owner.pulling != victim && !owner.Adjacent(victim)))
		owner.balloon_alert(owner, "out of range!")
		stop_feeding(victim, forced = TRUE)
		return FALSE
	return TRUE

/datum/action/cooldown/vampire/feed/proc/check_removed_limb(mob/living/carbon/victim, obj/item/bodypart/limb, dismembered)
	if(limb.body_zone != target_zone)
		return
	if(!is_suitable_limb(victim, target_zone))
		owner.balloon_alert(owner, "limb gone!")
		stop_feeding(victim, forced = TRUE, bodypart_override = limb)
		return

/datum/action/cooldown/vampire/feed/proc/attempt_enthrall(mob/living/carbon/human/victim)
	if(!started_alive || vampire.vampire_rank == 0 || !istype(victim))
		owner.balloon_alert(owner, "out of blood!")
		stop_feeding(victim, forced = FALSE)
		return

	if(!can_enthrall(victim))
		stop_feeding(victim, forced = FALSE)
		return

	UnregisterSignal(victim, list(COMSIG_LIVING_LIFE))
	owner.balloon_alert(owner, "enthralling...")

	if(!do_after(owner, 5 SECONDS, victim, timed_action_flags = IGNORE_SLOWDOWNS | IGNORE_HELD_ITEM, extra_checks = CALLBACK(src, PROC_REF(enthrall_extra_check))))
		stop_feeding(victim, forced = FALSE)
		return

	vampire.enthrall(victim)

	stop_feeding(victim, forced = FALSE)

/datum/action/cooldown/vampire/feed/proc/can_enthrall(mob/living/carbon/victim)
	if(!victim)
		return FALSE
	if(!victim.mind)
		owner.balloon_alert("mindless!")
		return FALSE
	if(HAS_TRAIT(victim, TRAIT_MINDSHIELD))
		owner.balloon_alert("mindshielded!")
		return FALSE
	return TRUE

/datum/action/cooldown/vampire/feed/proc/enthrall_extra_check()
	return can_enthrall(victim_ref?.resolve())

#undef WRIST_FEED
#undef NECK_FEED
