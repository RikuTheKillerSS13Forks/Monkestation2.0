/datum/action/cooldown/brother/swap_consciousness
	name = "One Mind"
	desc = "Temporarily swap minds with one of your brothers. Causes both sides to blink."
	button_icon_state = "swap"
	cooldown_time = 1 MINUTE

/datum/action/cooldown/brother/swap_consciousness/IsAvailable(feedback)
	if(owner.has_status_effect(/datum/status_effect/one_mind))
		return FALSE
	for(var/datum/mind/brother in (team.members - owner.mind))
		if(!QDELETED(brother.current) && brother.current.stat != DEAD)
			return ..()

/datum/action/cooldown/brother/swap_consciousness/Activate(atom/target)
	var/list/datum/mind/others = (team.members - owner.mind)

	if(length(others) == 1)
		if(swap_with(others[1]))
			return ..()
	else
		var/datum/mind/brother = tgui_input_list(owner, "Choose a brother to swap with.", "One Mind", others)
		if(brother && swap_with(brother))
			return ..()

/datum/action/cooldown/brother/swap_consciousness/proc/swap_with(datum/mind/target)
	var/mob/living/target_mob = target.current
	var/mob/living/owner = src.owner

	if(QDELETED(target_mob) || target_mob.stat == DEAD)
		owner.balloon_alert(owner, "failed!")
		return FALSE

	if(owner.has_status_effect(/datum/status_effect/one_mind) || target_mob.has_status_effect(/datum/status_effect/one_mind))
		owner.balloon_alert(owner, "already swapped!")

	target_mob.balloon_alert(target_mob, "swapping minds...")

	if(!do_after(owner, 1 SECOND, timed_action_flags = IGNORE_USER_LOC_CHANGE | IGNORE_HELD_ITEM | IGNORE_SLOWDOWNS))
		owner.balloon_alert(owner, "failed!")
		target_mob.balloon_alert(target_mob, "failed!")
		return FALSE

	if(QDELETED(target_mob) || target_mob.stat == DEAD)
		owner.balloon_alert(owner, "failed!")
		return FALSE

	if(owner.has_status_effect(/datum/status_effect/one_mind) || target_mob.has_status_effect(/datum/status_effect/one_mind))
		owner.balloon_alert(owner, "already swapped!")
		target_mob.balloon_alert(target_mob, "already swapped!")

	owner.apply_status_effect(/datum/status_effect/one_mind, target_mob)
	target_mob.apply_status_effect(/datum/status_effect/one_mind, owner)

	var/datum/mind/owner_mind = owner.mind

	owner.ghostize(TRUE)
	target_mob.ghostize(TRUE)

	owner_mind.swap_addictions(target)

	INVOKE_ASYNC(src, PROC_REF(finalize_other), target)

	owner_mind.transfer_to(target_mob)
	owner_mind.grab_ghost()
	to_chat(target_mob, span_boldnotice("You awaken in [target_mob]'s body!"))
	target_mob.emote("blink") // if this results in a neck snap im going to laugh my ass off

/datum/action/cooldown/brother/swap_consciousness/proc/finalize_other(datum/mind/other_mind)
	other_mind.transfer_to(owner)
	other_mind.grab_ghost()
	to_chat(owner, span_boldnotice("You awaken in [owner]'s body!"))
	owner.emote("blink")

/datum/status_effect/one_mind
	id = "one_mind"
	duration = 30 SECONDS
	alert_type = /atom/movable/screen/alert/status_effect/one_mind

	var/datum/weakref/old_mob_weakref
	var/canceled = FALSE

/datum/status_effect/one_mind/on_creation(mob/living/new_owner, old_mob)
	. = ..()
	old_mob_weakref = WEAKREF(old_mob)

/datum/status_effect/one_mind/on_remove()
	. = ..()

	if(canceled) // handled by our "paired" status effect
		return

	if(QDELETED(owner) || owner.stat == DEAD)
		return

	if(QDELETED(owner.mind))
		return

	var/mob/living/old_mob = old_mob_weakref.resolve()

	if(QDELETED(old_mob) || old_mob.stat == DEAD)
		owner.balloon_alert(owner, "can't return!")
		return

	var/datum/status_effect/one_mind/other_status = old_mob.has_status_effect(/datum/status_effect/one_mind)

	if(other_status)
		other_status.canceled = TRUE
		old_mob.remove_status_effect(/datum/status_effect/one_mind)

	owner.balloon_alert(owner, "returning...")

	INVOKE_ASYNC(src, PROC_REF(do_return), owner, old_mob)

/datum/status_effect/one_mind/proc/do_return(mob/living/owner, mob/living/old_mob)
	var/datum/weakref/mind_ref =  WEAKREF(owner.mind)
	var/datum/weakref/other_mind_ref = WEAKREF(old_mob.mind)

	sleep(1 SECOND)

	var/datum/mind/mind = mind_ref.resolve()
	var/datum/mind/other_mind = other_mind_ref.resolve()

	if(QDELETED(owner) || owner.stat == DEAD)
		return

	if(QDELETED(mind))
		return

	if(QDELETED(old_mob) || old_mob.stat == DEAD)
		owner.balloon_alert(owner, "can't return!")
		return

	owner.ghostize(TRUE)
	old_mob.ghostize(TRUE)

	if(!QDELETED(other_mind))
		mind.swap_addictions(other_mind)

	INVOKE_ASYNC(src, PROC_REF(finalize_other), other_mind, owner)

	mind.transfer_to(old_mob)
	mind.grab_ghost()
	to_chat(old_mob, span_boldnotice("You awaken back in your own body!"))
	old_mob.emote("blink") // what's better than rolling a neck snap once? rolling a neck snap twice!

	var/datum/antagonist/brother/bond = mind.has_antag_datum(/datum/antagonist/brother)
	bond?.swap_action.StartCooldown()

/datum/status_effect/one_mind/proc/finalize_other(datum/mind/other_mind, mob/living/owner)
	if(QDELETED(other_mind))
		return

	other_mind.transfer_to(owner)
	other_mind.grab_ghost()
	to_chat(owner, span_boldnotice("You awaken back in your own body!"))
	owner.emote("blink")

	var/datum/antagonist/brother/bond = other_mind.has_antag_datum(/datum/antagonist/brother)
	bond?.swap_action.StartCooldown()

/atom/movable/screen/alert/status_effect/one_mind
	name = "One Mind"
	desc = "Separated, yet united!"
	icon = 'monkestation/icons/mob/actions/actions_bb.dmi'
	icon_state = "swap"
