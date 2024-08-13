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
	var/vampire_rank = 0
	var/starting_rank = 1
	//antag_hud_name = "vampire"
	//hud_icon = 'monkestation/icons/vampires/vampire_icons.dmi'

	//ui_name = "AntagInfoVampire"

	/// Current amount of lifeforce.
	var/lifeforce = LIFEFORCE_PER_HUMAN // 1 human is worth 20 minutes
	/// Lifeforce changes per second. Don't modify this directly.
	var/list/lifeforce_changes = list(LIFEFORCE_CHANGE_THIRST = LIFEFORCE_DRAIN_BASE)
	/// Cached value made from lifeforce_changes, don't change this directly.
	var/lifeforce_per_second = 0

	/// Whether or not masquerade is enabled. Masquerade hides obvious signs of being a vampire.
	var/masquerade_enabled = TRUE

	var/atom/movable/screen/vampire/lifeforce_counter/lifeforce_display
	var/atom/movable/screen/vampire/rank_counter/rank_display

	var/datum/action/cooldown/vampire/feed/feed_action

	/// List of traits that are always active. Don't bloat this with 20 billion passives, reserve those for stat abilities.
	var/static/list/innate_traits = list(
		TRAIT_NOBLOOD,  // vampires are entirely bloodless and instead run on the lifeforce they *extract* from the blood of sapients
		TRAIT_STABLEHEART, // which also means they don't need a heart
		TRAIT_NOCRITDAMAGE, // helps with enthralling and also helps vampires save their thralls
		TRAIT_GENELESS // hulk + vampire = oh fuck no
	)

	/// List of traits that are removed when masquerade is enabled.
	var/static/list/visible_traits = list(
		TRAIT_COLDBLOODED,
		TRAIT_NO_MIRROR_REFLECTION
	)

	/// List of traits that are added when masquerade is enabled.
	var/static/list/masquerade_traits = list(
		TRAIT_FAKEBLOOD,
		TRAIT_FAKEGENES
	)

/datum/antagonist/vampire/New()
	. = ..()
	feed_action = new(src)

/datum/antagonist/vampire/Destroy()
	. = ..()
	QDEL_NULL(feed_action)

/datum/antagonist/vampire/on_gain()
	. = ..()
	set_rank(starting_rank)

/datum/antagonist/vampire/apply_innate_effects(mob/living/mob_override)
	var/mob/living/carbon/human/target_mob = mob_override || owner.current
	if(!istype(target_mob))
		return

	update_masquerade()
	update_lifeforce_changes()

	handle_clown_mutation(target_mob, "Your thirst for blood has overtaken your clownish nature, allowing you to wield weapons without harming yourself.")

	set_masquerade(FALSE)
	target_mob.add_traits(innate_traits, VAMPIRE_TRAIT)
	target_mob.blood_volume = BLOOD_VOLUME_NORMAL // if this somehow deviates, something is wrong as you have TRAIT_NOBLOOD and nothing should modify blood_volume if you have it

	RegisterSignal(target_mob, COMSIG_LIVING_LIFE, PROC_REF(on_life))

	if(target_mob.hud_used)
		on_hud_created()
	else
		RegisterSignal(target_mob, COMSIG_MOB_HUD_CREATED, PROC_REF(on_hud_created))

	feed_action?.Grant(target_mob)

/datum/antagonist/vampire/remove_innate_effects(mob/living/mob_override)
	var/mob/living/carbon/human/target_mob = mob_override || owner.current
	if(!istype(target_mob))
		return

	handle_clown_mutation(target_mob, removing = FALSE)

	REMOVE_TRAITS_IN(target_mob, VAMPIRE_TRAIT)

	UnregisterSignal(target_mob, COMSIG_LIVING_LIFE)

	if(target_mob.hud_used)
		var/datum/hud/hud = target_mob.hud_used
		hud.infodisplay -= lifeforce_display
		hud.infodisplay -= rank_display
		QDEL_NULL(lifeforce_display)
		QDEL_NULL(rank_display)

	feed_action?.Remove(target_mob)

/datum/antagonist/vampire/proc/on_life(datum/source, seconds_per_tick, times_fired)
	SIGNAL_HANDLER
	adjust_lifeforce(lifeforce_per_second * seconds_per_tick)

