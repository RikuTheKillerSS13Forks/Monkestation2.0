/datum/status_effect/vampire_hunger
	id = "vampire_hunger"
	duration = 30 SECONDS // good luck, you're on borrowed time
	show_duration = TRUE
	alert_type = /atom/movable/screen/alert/status_effect/vampire_hunger
	status_type = STATUS_EFFECT_MULTIPLE // good for mind transfers between two hungry vampires (if such a cursed scenario ever occurs)

	var/datum/antagonist/vampire/vampire
	var/cleared = FALSE

/datum/status_effect/vampire_hunger/New(list/arguments)
	. = ..()
	vampire = arguments[2]
	RegisterSignal(vampire, COMSIG_VAMPIRE_LIFEFORCE_CHANGED, PROC_REF(on_lifeforce_changed))
	RegisterSignal(vampire, COMSIG_QDELETING, PROC_REF(self_destruct))

/datum/status_effect/vampire_hunger/Destroy()
	. = ..()
	UnregisterSignal(vampire, list(COMSIG_VAMPIRE_LIFEFORCE_CHANGED, COMSIG_QDELETING))
	UnregisterSignal(owner.mind, list(COMSIG_MIND_TRANSFERRED, COMSIG_QDELETING))
	vampire = null

/datum/status_effect/vampire_hunger/on_apply()
	. = ..()
	RegisterSignal(owner.mind, COMSIG_MIND_TRANSFERRED, PROC_REF(on_mind_transfer))
	RegisterSignal(owner.mind, COMSIG_QDELETING, PROC_REF(self_destruct))

/datum/status_effect/vampire_hunger/on_remove()
	. = ..()
	if(cleared)
		return
	owner.visible_message(
		message = span_danger("[owner] lets out a scream of pure terror and turns to dust right before your eyes!"),
		self_message = span_userdanger("Your body turns to dust as the last shreds of your strength fade away!"),
		blind_message = span_hear("You hear a scream of pure terror!")
	)
	owner.emote("scream")
	owner.investigate_log("has been dusted by a lack of lifeforce. (vampire)", INVESTIGATE_DEATHS)
	owner.dust(drop_items = TRUE)

/datum/status_effect/vampire_hunger/tick(seconds_per_tick, times_fired)
	. = ..()
	if(SPT_PROB(5, seconds_per_tick))
		owner.emote("shiver")

/datum/status_effect/vampire_hunger/proc/on_lifeforce_changed(datum/source, old_amount, new_amount)
	SIGNAL_HANDLER
	if(new_amount <= 0)
		return
	cleared = TRUE
	qdel(src)

/datum/status_effect/vampire_hunger/proc/on_mind_transfer(datum/mind/mind, old_body)
	SIGNAL_HANDLER
	var/datum/status_effect/new_effect = mind.current?.apply_status_effect(type, vampire)
	new_effect?.duration = duration

/datum/status_effect/vampire_hunger/proc/self_destruct()
	SIGNAL_HANDLER
	qdel(src)

/atom/movable/screen/alert/status_effect/vampire_hunger
	name = "Hunger"
	desc = "Your body shivers and your mind is fogging up..."
	icon = 'icons/obj/objects.dmi'
	icon_state = "ash" // please take the hint
	alerttooltipstyle = "cult"
