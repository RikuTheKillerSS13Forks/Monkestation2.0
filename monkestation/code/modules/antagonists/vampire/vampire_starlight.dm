/datum/antagonist/vampire/proc/on_moved()
	SIGNAL_HANDLER
	handle_starlight() // Called in 'vampire_process.dm' as well.

/// Handles adding/removing TRAIT_VAMPIRE_STARLIT and sends the associated visual message when added.
/datum/antagonist/vampire/proc/handle_starlight()
	var/is_in_starlight = is_in_starlight()

	if (HAS_TRAIT(user, TRAIT_VAMPIRE_STARLIT) == is_in_starlight) // No changes need to be made.
		return

	if(is_in_starlight)
		user.apply_status_effect(/datum/status_effect/vampire/starlit)
	else
		user.remove_status_effect(/datum/status_effect/vampire/starlit)

/// Returns whether the vampire should be affected by starlight right now.
/datum/antagonist/vampire/proc/is_in_starlight()
	if(!isspaceturf(get_turf(user)))
		return FALSE

	var/chest_covered = FALSE
	var/head_covered = FALSE
	for(var/obj/item/clothing/equipped in user.get_equipped_items())
		chest_covered ||= (equipped.body_parts_covered & CHEST) && (equipped.clothing_flags & STOPSPRESSUREDAMAGE)
		head_covered ||= (equipped.body_parts_covered & HEAD) && (equipped.clothing_flags & STOPSPRESSUREDAMAGE)

	return !head_covered || !chest_covered
