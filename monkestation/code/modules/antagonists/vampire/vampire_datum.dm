/datum/antagonist/vampire
	name = "\improper Vampire"
	roundend_category = "vampires"
	antagpanel_category = "Vampire"
	job_rank = ROLE_VAMPIRE
	hijack_speed = 0.5

	show_in_antagpanel = TRUE
	show_name_in_check_antagonists = TRUE
	can_coexist_with_others = FALSE

	preview_outfit = /datum/outfit/vampire

	//antag_hud_name = "vampire"
	//hud_icon = 'monkestation/icons/vampires/vampire_icons.dmi'

	//ui_name = "AntagInfoVampire"

	/// Current amount of life force. Don't modify this directly.
	var/life_force = LIFE_FORCE_PER_HUMAN // 1 human is worth 20 minutes
	/// Life force changes per second. Don't modify this directly.
	var/list/life_force_changes = list(LIFE_FORCE_CHANGE_THIRST = LIFE_FORCE_DRAIN_BASE)
	/// Cached value made from life_force_changes. Don't modify this directly.
	var/life_force_per_second = 0

/datum/antagonist/vampire/apply_innate_effects(mob/living/mob_override)
	var/mob/living/carbon/human/target_mob = mob_override || owner.current
	if(!istype(target_mob))
		return

	update_life_force_changes()

	handle_clown_mutation(target_mob, "Your thirst for blood has overtaken your clownish nature, allowing you to wield weapons without harming yourself.")

	RegisterSignal(target_mob, COMSIG_LIVING_LIFE, PROC_REF(on_life))

/datum/antagonist/vampire/remove_innate_effects(mob/living/mob_override)
	var/mob/living/carbon/human/target_mob = mob_override || owner.current
	if(!istype(target_mob))
		return

	handle_clown_mutation(target_mob, "Your thirst for blood subsides and your clownish nature returns.", removing = FALSE)

	UnregisterSignal(target_mob, COMSIG_LIVING_LIFE)

/datum/antagonist/vampire/proc/on_life(mob/living/carbon/human/target_mob, seconds_per_tick, times_fired)
	SIGNAL_HANDLER

	if(target_mob.stat == DEAD)
		return

	adjust_life_force(life_force_per_second * seconds_per_tick)
