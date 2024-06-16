/datum/action/cooldown/brother/one_mind
	name = "One Mind"
	desc = "Temporarily swap minds with one of your brothers. Makes both of you blink."
	button_icon_state = "swap"
	cooldown_time = 1 MINUTE

/datum/action/cooldown/brother/one_mind/IsAvailable(feedback)
	if(!..())
		return FALSE
	if(HAS_TRAIT(owner.mind, TRAIT_ONE_MIND))
		return FALSE
	for(var/datum/mind/brother in (team.members - owner.mind))
		if(!QDELETED(brother.current) && brother.current.stat != DEAD)
			return TRUE

/datum/action/cooldown/brother/one_mind/Activate()
	var/list/datum/mind/others = (team.members - owner.mind)
	var/datum/mind/target = length(others) == 1 ? others[1] : tgui_input_list(owner, "Choose a brother to swap with.", name, others)
	new /datum/blood_brother_mind_swap(owner.mind, target)

/datum/blood_brother_mind_swap
	var/datum/weakref/owner_bond_ref
	var/datum/weakref/target_bond_ref

/datum/blood_brother_mind_swap/New(datum/mind/owner, datum/mind/target)
	INVOKE_ASYNC(src, PROC_REF(do_swap), owner, target)

/datum/blood_brother_mind_swap/proc/do_swap(datum/mind/owner, datum/mind/target)
	var/mob/living/owner_mob = owner?.current
	var/mob/living/target_mob = target?.current
	var/datum/antagonist/brother/owner_bond = owner.has_antag_datum(/datum/antagonist/brother)
	var/datum/antagonist/brother/target_bond = target.has_antag_datum(/datum/antagonist/brother)

	if(QDELETED(owner_mob) || owner_mob.stat == DEAD) // the sanity check of all sanity checks
		return qdel(src)

	if(QDELETED(owner_bond) || QDELETED(target_bond))
		owner_mob.balloon_alert(owner_mob, "failed!")
		return qdel(src)

	if(QDELETED(target_mob) || target_mob.stat == DEAD)
		owner_mob.balloon_alert(owner_mob, "failed!")
		return qdel(src)

	if(HAS_TRAIT(owner, TRAIT_ONE_MIND) || HAS_TRAIT(target, TRAIT_ONE_MIND)) // i dont want to risk this since it breaks everything majestically
		owner_mob.balloon_alert(owner_mob, "already swapped!")
		return qdel(src)

	target_mob.balloon_alert(target_mob, "swapping minds...")

	if(!do_after(owner_mob, 0.8 SECONDS, timed_action_flags = IGNORE_USER_LOC_CHANGE | IGNORE_HELD_ITEM | IGNORE_SLOWDOWNS))
		alert_both(owner_mob, target_mob, "failed!")
		return qdel(src)

	add_blink_overlay(owner_mob)
	add_blink_overlay(target_mob)

	sleep(0.2 SECONDS)

	owner_mob = owner?.current // in case you SOMEHOW swapped bodies during the literal 1 second i looked away
	target_mob = target?.current

	if(QDELETED(owner_bond) || QDELETED(target_bond))
		alert_both(owner_mob, target_mob, "failed!")
		return qdel(src)

	if(QDELETED(owner_mob) || owner_mob.stat == DEAD || QDELETED(target_mob) || target_mob.stat == DEAD) // a lot of checks here, minds are fragile after all
		alert_both(owner_mob, target_mob, "failed!")
		return qdel(src)

	if(HAS_TRAIT(owner, TRAIT_ONE_MIND) || HAS_TRAIT(target, TRAIT_ONE_MIND)) // don't even try it
		alert_both(owner_mob, target_mob, "already swapped!")
		return qdel(src)

	owner_bond.swap_action?.StartCooldown(30 SECONDS) // used to show the player how much time they have left
	target_bond.swap_action?.StartCooldown(30 SECONDS)

	ADD_TRAIT(owner, TRAIT_ONE_MIND, TRAIT_GENERIC)
	ADD_TRAIT(target, TRAIT_ONE_MIND, TRAIT_GENERIC)

	owner.swap_addictions(target) // addictions should probably be on the brain but here it is anyway

	owner_mob.ghostize(can_reenter_corpse = TRUE)
	target_mob.ghostize(can_reenter_corpse = TRUE)

	add_overlay(owner_mob, owner)
	add_overlay(target_mob, target)

	INVOKE_ASYNC(src, PROC_REF(finalize_swap), owner, target_mob) // async for lag mitigation
	INVOKE_ASYNC(src, PROC_REF(finalize_swap), target, owner_mob)

	owner_bond_ref = WEAKREF(owner_bond)
	target_bond_ref = WEAKREF(target_bond)

	addtimer(CALLBACK(src, PROC_REF(try_return)), 29 SECONDS) // try_return sleeps for 1 second and we want this to last 30 seconds total

/datum/blood_brother_mind_swap/proc/add_blink_overlay(mob/living/target_mob)
	INVOKE_ASYNC(src, PROC_REF(animate_blink_overlay), target_mob)

/datum/blood_brother_mind_swap/proc/animate_blink_overlay(mob/living/target_mob)
	var/atom/overlay = target_mob?.overlay_fullscreen("one_mind_blink", /atom/movable/screen/fullscreen/flash/black)
	if(!overlay)
		return
	overlay.alpha = 0
	animate(overlay, 0.18 SECONDS, alpha = 255) // in testing, the 0.2 second animate resulted in the swap happening before the animate finished
	sleep(0.25 SECONDS) // it's slightly over 0.2 seconds to avoid visual glitches, the extra 0.05 seconds won't render on the client anyway
	target_mob?.clear_fullscreen("one_mind_blink", animated = FALSE) // i wish i could animate it but the mind transfer breaks overlays for a short while

/datum/blood_brother_mind_swap/proc/add_overlay(mob/living/target_mob, datum/mind/mind)
	if(!target_mob || !mind)
		return
	target_mob.overlay_fullscreen("one_mind", /atom/movable/screen/fullscreen/one_mind)
	RegisterSignal(mind, COMSIG_MIND_TRANSFERRED, PROC_REF(transfer_overlay))
	RegisterSignal(mind, COMSIG_QDELETING, PROC_REF(on_mind_deleted))

/datum/blood_brother_mind_swap/proc/remove_overlay(mob/living/target_mob, datum/mind/mind)
	target_mob?.clear_fullscreen("one_mind", animated = FALSE)
	if(mind)
		UnregisterSignal(mind, list(COMSIG_MIND_TRANSFERRED, COMSIG_QDELETING))

/datum/blood_brother_mind_swap/proc/on_mind_deleted(datum/mind/mind, force)
	SIGNAL_HANDLER
	remove_overlay(mind.current)

/datum/blood_brother_mind_swap/proc/transfer_overlay(datum/mind/mind, mob/living/previous_body)
	SIGNAL_HANDLER
	remove_overlay(previous_body)
	add_overlay(mind.current)

/datum/blood_brother_mind_swap/proc/finalize_swap(datum/mind/mind, mob/living/target_mob)
	if(QDELETED(target_mob))
		return
	mind.transfer_to(target_mob)
	target_mob.grab_ghost(force = TRUE) // since can_reenter_corpse is false, we force it
	to_chat(target_mob, span_boldnotice("You awaken in [target_mob]'s body!"))
	target_mob.emote("blink") // if this results in a neck snap im going to laugh my ass off
	SEND_SIGNAL(target_mob, COMSIG_BB_CLEAR_ABILITIES)

/datum/blood_brother_mind_swap/proc/try_return()
	var/datum/antagonist/brother/owner_bond = owner_bond_ref?.resolve()
	var/datum/antagonist/brother/target_bond = target_bond_ref?.resolve()

	alert_both(owner_bond?.owner?.current, target_bond?.owner?.current, "returning...")

	sleep(0.8 SECONDS)

	add_blink_overlay(owner_bond?.owner?.current)
	add_blink_overlay(target_bond?.owner?.current)

	sleep(0.2 SECONDS)

	var/datum/mind/owner = owner_bond?.owner
	var/datum/mind/target = target_bond?.owner
	var/mob/living/owner_mob = owner?.current
	var/mob/living/target_mob = target?.current

	owner_bond?.swap_action?.StartCooldown() // this is the real cooldown
	target_bond?.swap_action?.StartCooldown()

	if(owner)
		REMOVE_TRAIT(owner, TRAIT_ONE_MIND, TRAIT_GENERIC)
	if(target)
		REMOVE_TRAIT(target, TRAIT_ONE_MIND, TRAIT_GENERIC)

	if(owner && target)
		owner.swap_addictions(target)

	owner_mob?.ghostize(can_reenter_corpse = target_mob != null)
	if(!target)
		owner_mob?.death() // no amount of TRAIT_NODEATH will save you from having your soul removed

	target_mob?.ghostize(can_reenter_corpse = owner_mob != null)
	if(!owner)
		target_mob?.death()

	remove_overlay(owner_mob, owner)
	remove_overlay(target_mob, target)

	if(owner && target_mob)
		INVOKE_ASYNC(src, PROC_REF(finalize_swap), owner, target_mob)
	if(target && owner_mob)
		INVOKE_ASYNC(src, PROC_REF(finalize_swap), target, owner_mob)

	addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(qdel)), 10 SECONDS) // swapping minds is async and also doing this costs fuckall so it's probably fine

/datum/blood_brother_mind_swap/proc/has_trait(datum/target)
	return HAS_TRAIT(target, TRAIT_ONE_MIND)

/datum/blood_brother_mind_swap/proc/alert_both(mob/living/owner_mob, mob/living/target_mob, message) // i had to do this so many times i just made it a proc
	owner_mob?.balloon_alert(owner_mob, message)
	target_mob?.balloon_alert(target_mob, message)
