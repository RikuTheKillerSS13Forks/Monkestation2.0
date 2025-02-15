// Make sure thralls don't have much state dependent on the antag datum.
// Otherwise removing the flesh bud will cause a really bad day for someone.
// I.e. don't give them learnable abilities, don't give them objectives, etc.
// Once they have ranked up, those restraints are removed as the datum persists.

/datum/antagonist/vampire/thrall
	name = "\improper Thrall"
	roundend_category = "thralls"
	show_in_antagpanel = FALSE
	masquerade_enabled = FALSE
	current_rank = 0
	normal_ability_points = 0

	current_actions = list(
		/datum/action/cooldown/vampire/mature,
		/datum/action/cooldown/vampire/feed,
		/datum/action/cooldown/vampire/regeneration,
	)

/datum/antagonist/vampire/thrall/apply_innate_effects(mob/living/mob_override)
	. = ..() // Do this first, it sets user.
	if (has_matured())
		return

	apply_damage_bane()

/datum/antagonist/vampire/thrall/remove_innate_effects(mob/living/mob_override)
	if (has_matured())
		return ..()

	remove_damage_bane()

	return ..() // Call this last, or else user will be null.

/datum/antagonist/vampire/thrall/rank_up()
	if (has_matured())
		return
	. = ..() // Call after the mature check since this raises their rank.

	remove_damage_bane()
	grant_action(/datum/action/cooldown/vampire/masquerade)

	name = "\improper Vampire" // Congrats, you're a vampire now.
	roundend_category = "vampires"

	var/datum/action/antag_info/info_button = info_button_ref?.resolve()
	info_button?.update_antag_name()

/datum/antagonist/vampire/thrall/proc/has_matured()
	return current_rank != 0

/datum/antagonist/vampire/thrall/proc/apply_damage_bane()
	if (user?.physiology)
		user.physiology.brute_mod *= 2
		user.physiology.burn_mod *= 2

/datum/antagonist/vampire/thrall/proc/remove_damage_bane()
	if (user?.physiology)
		user.physiology.brute_mod /= 2
		user.physiology.burn_mod /= 2
