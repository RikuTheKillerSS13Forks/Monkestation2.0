/datum/action/cooldown/vampire
	name = "Please ahelp"
	desc = "If you see this ahelp IMMEDIATELY"

	button_icon = 'monkestation/icons/vampires/actions_vampire.dmi'
	base_background_icon_state = "vamp_power_off"
	active_background_icon_state = "vamp_power_on"

	/// How much lifeforce it costs to use this action.
	var/life_cost = 0

	/// How much lifeforce this action uses over time while active. Toggle-only.
	var/constant_life_cost = 0

	/// Whether this action is a toggle or not.
	var/toggleable = FALSE

	/// If toggleable, whether or not this action is currently toggled on.
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

	if(user == removed_from)
		user = null

/datum/action/cooldown/vampire/IsAvailable(feedback)
	if(!..())
		return FALSE

	if(vampire.lifeforce < life_cost)
		if(feedback)
			owner.balloon_alert(owner, "needs [life_cost] lifeforce!")
		return FALSE

	return TRUE

/datum/action/cooldown/vampire/Destroy() // assumes that the action target is always the vampire antag datum, so this should be called if vampire is qdel'd
	UnregisterSignal(vampire, COMSIG_VAMPIRE_LIFEFORCE_CHANGED)
	vampire = null
	return ..()

/datum/action/cooldown/vampire/proc/update_button(datum/source) // not named update_button_status as thats an action level proc, this is a signal handler for that
	SIGNAL_HANDLER
	build_all_button_icons(UPDATE_BUTTON_STATUS)

/datum/action/cooldown/vampire/proc/Activate(atom/target)
	. = ..()
	if(life_cost)
		vampire.adjust_lifeforce(-life_cost)
	if(!toggleable)
		return
	if(active)
		toggle_off()
	else
		toggle_on()

/datum/action/cooldown/vampire/proc/toggle_on()
	if(active)
		return
	active = TRUE

	if(constant_life_cost)
		vampire.set_lifeforce_change(VAMPIRE_CONSTANT_LIFEFORCE_COST(src), -constant_life_cost)

	INVOKE_ASYNC(src, PROC_REF(on_toggle_on))

/// To be implemented by subtypes. Called from toggle_on after active is set to TRUE.
/datum/action/cooldown/vampire/proc/on_toggle_on()

/datum/action/cooldown/vampire/proc/toggle_off()
	if(!active)
		return
	active = FALSE

	vampire.clear_lifeforce_change(VAMPIRE_CONSTANT_LIFEFORCE_COST(src))

	INVOKE_ASYNC(src, PROC_REF(on_toggle_off))

/// To be implemented by subtypes. Called from toggle_off after active is set to FALSE.
/datum/action/cooldown/vampire/proc/on_toggle_off()
