/datum/action/cooldown/vampire
	name = "Please ahelp"
	desc = "If you see this ahelp IMMEDIATELY"
	cooldown_time = 0.5 SECONDS

	button_icon = 'monkestation/icons/vampires/actions_vampire.dmi'
	background_icon = 'monkestation/icons/vampires/actions_vampire.dmi'
	background_icon_state = "vamp_power_off"
	base_background_icon_state = "vamp_power_off"
	active_background_icon_state = "vamp_power_on"
	buttontooltipstyle = "cult"
	transparent_when_unavailable = TRUE

	/// How much lifeforce it costs to use this action.
	var/life_cost = 0

	/// How much lifeforce this action uses over time while active. Toggle-only.
	var/constant_life_cost = 0

	/// Whether this action is a toggle or not.
	var/toggleable = FALSE

	/// If toggleable, whether or not this action is currently toggled on. Use is_active() for checks.
	var/active = FALSE

	var/mob/living/carbon/human/user
	var/datum/antagonist/vampire/vampire

/datum/action/cooldown/vampire/New(Target)
	. = ..()

	vampire = Target
	if(!istype(vampire))
		CRASH("Vampire action created without a linked vampire antag datum.")

	RegisterSignal(vampire, COMSIG_VAMPIRE_LIFEFORCE_CHANGED, PROC_REF(update_button))

/datum/action/cooldown/vampire/Grant(mob/granted_to)
	. = ..()

	if(!ishuman(granted_to))
		CRASH("Vampire action granted to non-human mob.")
	user = granted_to

/datum/action/cooldown/vampire/Remove(mob/removed_from)
	. = ..()

	if(toggleable && is_active())
		toggle_off() // doesn't matter if can_toggle_off would return false here, just do it anyway

	if(user == removed_from)
		user = null

/datum/action/cooldown/vampire/IsAvailable(feedback)
	if(!..())
		return FALSE

	if(toggleable && is_active() && can_toggle_off())
		return TRUE

	if(vampire.lifeforce < life_cost)
		if(feedback)
			owner.balloon_alert(owner, "needs [life_cost] lifeforce!")
		return FALSE

	if(toggleable && !is_active() && !can_toggle_on(feedback))
		return FALSE

	return TRUE

/datum/action/cooldown/vampire/Destroy() // assumes that the action target is always the vampire antag datum, so this should be called if vampire is qdel'd
	UnregisterSignal(vampire, COMSIG_VAMPIRE_LIFEFORCE_CHANGED)
	vampire = null
	return ..()

/datum/action/cooldown/vampire/proc/update_button() // not named update_button_status as thats an action level proc, this is a signal handler for that
	SIGNAL_HANDLER
	build_all_button_icons(UPDATE_BUTTON_STATUS)

/datum/action/cooldown/vampire/Activate(atom/target)
	if(life_cost && (!toggleable || is_active())) // deactivation shouldn't cost anything
		vampire.adjust_lifeforce(-life_cost)
	if(!toggleable)
		return ..()
	if(is_active())
		toggle_off()
	else
		toggle_on()

/// Normally just returns 'active', but can be used to override it if necessary. Used for checks instead of 'active' itself.
/datum/action/cooldown/vampire/proc/is_active()
	return active

/// Actually toggles the action on. Use on_toggle_on() for subtypes if possible.
/datum/action/cooldown/vampire/proc/toggle_on()
	SIGNAL_HANDLER

	if(is_active())
		return
	active = TRUE

	if(constant_life_cost)
		vampire.set_lifeforce_change(VAMPIRE_CONSTANT_LIFEFORCE_COST(src), -constant_life_cost)

	INVOKE_ASYNC(src, PROC_REF(on_toggle_on))
	build_all_button_icons()

	StartCooldown(0.5 SECONDS)

/// To be implemented by subtypes. Called from toggle_on after active is set to TRUE.
/datum/action/cooldown/vampire/proc/on_toggle_on()

/// To be implemented by subtypes. Whether or not the action can be toggled on right now.
/datum/action/cooldown/vampire/proc/can_toggle_on(feedback)
	return TRUE

/// Actually toggles the action on. Use on_toggle_off() for subtypes if possible.
/datum/action/cooldown/vampire/proc/toggle_off()
	SIGNAL_HANDLER

	if(!is_active())
		return
	active = FALSE

	vampire.clear_lifeforce_change(VAMPIRE_CONSTANT_LIFEFORCE_COST(src))

	INVOKE_ASYNC(src, PROC_REF(on_toggle_off))
	build_all_button_icons()

	StartCooldown(cooldown_time)

/// To be implemented by subtypes. Called from toggle_off after active is set to FALSE.
/datum/action/cooldown/vampire/proc/on_toggle_off()

/// To be implemented by subtypes. Whether or not the action can be toggled off right now.
/datum/action/cooldown/vampire/proc/can_toggle_off(feedback)
	return TRUE

/datum/action/cooldown/vampire/is_action_active(atom/movable/screen/movable/action_button/current_button)
	return ..() || is_active()
