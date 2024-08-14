/datum/vampire_ability
	var/name = "ERROR"
	var/desc = "TELL THE ADMEMES"

	/// Associative list of stat requirements for the ability.
	var/static/stat_reqs = list()

	/// Minimum rank required to get the ability.
	var/static/min_rank = 0

	/// The type of action to be granted to the vampire by this ability, if any.
	var/static/datum/action/cooldown/vampire/granted_action_type = null

	/// The action currently granted to the vampire by this ability, if any.
	var/datum/action/cooldown/vampire/granted_action = null

	/// The vampire who owns this ability.
	var/datum/antagonist/vampire/owner = null

	/// The current mob using this ability.
	var/mob/living/carbon/human/user = null

/// Actually grants the action to the vampire. Use on_grant for subtypes if possible.
/datum/vampire_ability/proc/grant(/datum/antagonist/vampire/new_owner)
	SHOULD_NOT_SLEEP(TRUE)

	owner = new_owner
	user = owner.owner.current

	RegisterSignal(owner, COMSIG_QDELETING, PROC_REF(clear_ref))
	RegisterSignal(user, COMSIG_QDELETING, PROC_REF(clear_ref))

	if(granted_action_type)
		granted_action = new granted_action_type
		granted_action.Grant(user)

	INVOKE_ASYNC(src, PROC_REF(on_grant))

/// To be implemented by subtypes. Called in grant() after setting owner and user.
/datum/vampire_ability/proc/on_grant()

/// Actually removes the action from the vampire. Use on_remove for subtypes if possible.
/datum/vampire_ability/proc/remove()
	SHOULD_NOT_SLEEP(TRUE)

	UnregisterSignal(owner, COMSIG_QDELETING, PROC_REF(clear_ref))
	UnregisterSignal(user, COMSIG_QDELETING, PROC_REF(clear_ref))

	QDEL_NULL(granted_action)

	INVOKE_ASYNC(src, PROC_REF(on_remove))

	owner = null
	user = null

/// To be implemented by subtypes. Called in remove() before unsetting owner and user.
/datum/vampire_ability/proc/on_remove()

/// If you pass the owner or user to this, the ability self-removes.
/datum/vampire_ability/proc/clear_ref(datum/ref)
	SIGNAL_HANDLER

	if(ref == owner || ref == user)
		remove()

/datum/vampire_ability/Destroy(force, ...)
	. = ..()

	if(owner || user)
		remove()
