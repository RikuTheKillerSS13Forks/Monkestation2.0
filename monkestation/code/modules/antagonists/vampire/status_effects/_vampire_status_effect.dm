/atom/movable/screen/alert/status_effect/vampire
	icon = 'monkestation/icons/vampires/vampire_actions.dmi'
	alerttooltipstyle = "cult"

	var/background_icon = 'monkestation/icons/vampires/vampire_actions.dmi'
	var/background_icon_state = "status_effect_bg"

/atom/movable/screen/alert/status_effect/vampire/Initialize(mapload, datum/hud/hud_owner)
	var/image/underlay = image(icon = background_icon, icon_state = background_icon_state)

	if(clickable_glow)
		underlay.add_filter("clickglow", 2, outline_filter(color = COLOR_GOLD, size = 1))
		mouse_over_pointer = MOUSE_HAND_POINTER

	underlays += underlay
	clickable_glow = FALSE // So it doesn't add the default one.
	return ..()


/datum/status_effect/vampire
	var/mob/living/carbon/human/user
	var/datum/antagonist/vampire/antag_datum

/datum/status_effect/vampire/on_apply()
	user = owner
	if (!istype(user))
		CRASH("Vampire status effect with ID \"[id]\" added to non-human mob \"[user]\".")

	antag_datum = user.mind?.has_antag_datum(/datum/antagonist/vampire)
	if (!antag_datum)
		CRASH("Vampire status effect with ID \"[id]\" added to non-vampire mob \"[user]\".")

	RegisterSignal(antag_datum, COMSIG_VAMPIRE_CLEANUP, PROC_REF(on_cleanup))

	return TRUE

/datum/status_effect/vampire/Destroy()
	. = ..() // Call parent first in case 'on_remove()' uses the 'user' or 'antag_datum' vars.

	UnregisterSignal(antag_datum, COMSIG_VAMPIRE_CLEANUP) // Done here to avoid dropping support for 'on_remove_on_mob_delete = FALSE' or alternatively, duplicating this.

	user = null
	antag_datum = null

/datum/status_effect/vampire/proc/on_cleanup()
	SIGNAL_HANDLER
	qdel(src)
