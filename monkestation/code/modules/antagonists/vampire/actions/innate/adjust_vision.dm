// This action is kinda shit, to be entirely honest.
// Mostly cause I want to disable night vision during masquerade.
// That said, we can afford a couple of extra calls to 'update_sight()', really.
// And I've also added comments to any parts that seemed even a bit unclear.

/datum/action/adjust_vision/vampire
	desc = "Adjust your eyes, molding the darkness as you see fit."
	buttontooltipstyle = "cult"

	background_icon = 'monkestation/icons/vampires/vampire_actions.dmi'
	background_icon_state = "vamp_power_off"
	overlay_icon_state = null

	// Red with a hint of purple.
	low_light_cutoff = list(15, 2, 5)
	medium_light_cutoff = list(30, 5, 10)
	high_light_cutoff = list(50, 10, 20)

	/// This action changes light levels so much that I actually just need to save it between grants/removes and masquerade uses.
	var/saved_light_level = 3 // VISION_ACTION_LIGHT_HIG

/datum/action/adjust_vision/vampire/New(Target)
	. = ..()
	RegisterSignal(target, COMSIG_VAMPIRE_MASQUERADE, PROC_REF(on_masquerade))

/datum/action/adjust_vision/vampire/Destroy()
	UnregisterSignal(target, COMSIG_VAMPIRE_MASQUERADE)
	return ..()

/datum/action/adjust_vision/vampire/Grant(mob/living/grant_to)
	. = ..()
	var/datum/antagonist/vampire/antag_datum = target
	if (antag_datum.masquerade_enabled)
		set_light_level(0) // VISION_ACTION_LIGHT_OFF
	else
		set_light_level(saved_light_level)

/datum/action/adjust_vision/vampire/Trigger(trigger_flags)
	light_level = saved_light_level // Bypass masquerade setting light_level to 0.
	. = ..()
	saved_light_level = light_level // Save the user-set change to light level.

	var/datum/antagonist/vampire/antag_datum = target
	if (antag_datum.masquerade_enabled)
		set_light_level(0) // VISION_ACTION_LIGHT_OFF

/datum/action/adjust_vision/vampire/proc/on_masquerade(datum/source, new_state, old_state)
	SIGNAL_HANDLER
	if (!owner) // The masquerade signal is sent while this has no owner when the antag datum is initializing.
		return
	if (new_state)
		set_light_level(0) // VISION_ACTION_LIGHT_OFF
	else
		set_light_level(saved_light_level)
