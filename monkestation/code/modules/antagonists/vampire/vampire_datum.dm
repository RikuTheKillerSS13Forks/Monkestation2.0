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
		TRAIT_NO_MIRROR_REFLECTION,
		TRAIT_PALE_GREY_SKIN
	)

	/// List of traits that are added when masquerade is enabled.
	var/static/list/masquerade_traits = list(
		TRAIT_FAKEBLOOD,
		TRAIT_FAKEGENES
	)

	/// How many stat points the vampire has in total. Don't modify this directly.
	var/stat_points = 0

	/// How many available stat points the vampire has. Don't modify this directly.
	var/available_stat_points = 0

	/// How many stat points the vampire has spent. Don't modify this directly.
	var/spent_stat_points = 0

	/// The stats of the vampire. The cornerstone of progression alongside ranks. Don't modify this directly.
	var/list/stats = list(
		VAMPIRE_STAT_BRUTALITY = 0,
		VAMPIRE_STAT_TENACITY = 0,
		VAMPIRE_STAT_PURSUIT = 0,
		VAMPIRE_STAT_RECOVERY = 0,
		VAMPIRE_STAT_PERCEPTION = 0,
		VAMPIRE_STAT_DISCRETION = 0
	)

	/// Associative list of abilities the vampire has unlocked.
	/// These are instances sorted by their type.
	var/list/current_abilities = list()

	/// Associative list of available abilities by their unlock conditions.
	/// Abilities that unlock based on a stat use the define of that stat as their key.
	/// And ones that have a rank requirement use VAMPIRE_ABILITIES_RANK.
	/// There's also VAMPIRE_ABILITIES_ALL if you need it for some reason.
	/// The abilities in here are in typepath form.
	var/static/list/available_abilities

	/// The clan of the vampire, if any.
	var/clan = null

	/// Modifier for feed rate. Value is in blood/s.
	var/datum/modifier/feed_rate_modifier = new(base_value = BLOOD_VOLUME_NORMAL / 30)

	/// Associative list of stat modifiers. Applied as multipliers. Don't modify this directly.
	var/list/stat_mods = list()

/datum/antagonist/vampire/New()
	. = ..()
	init_available_abilities()

/datum/antagonist/vampire/on_gain()
	vampire_rank = starting_rank
	owner.current.playsound_local(get_turf(owner.current), 'monkestation/sound/vampires/vampire_alert.ogg', vol = 100, vary = FALSE, pressure_affected = FALSE, use_reverb = FALSE)
	. = ..() // stupid hack to fix masquerade appearing before the antag panel
	set_rank(starting_rank, force_update = TRUE)

/datum/antagonist/vampire/apply_innate_effects(mob/living/mob_override)
	var/mob/living/carbon/human/target_mob = mob_override || owner.current
	if(!istype(target_mob))
		return

	update_lifeforce_changes()

	handle_clown_mutation(target_mob, "Your thirst for blood has overtaken your clownish nature, allowing you to wield weapons without harming yourself.")

	target_mob.add_traits(innate_traits, VAMPIRE_TRAIT)
	target_mob.blood_volume = BLOOD_VOLUME_NORMAL // if this somehow deviates, something is wrong as you have TRAIT_NOBLOOD and nothing should modify blood_volume if you have it

	update_masquerade() // keep this below add_traits or else hulk will break our shitcode (bodypart.variable_color)

	RegisterSignal(target_mob, COMSIG_LIVING_LIFE, PROC_REF(on_life))

	if(target_mob.hud_used)
		on_hud_created()
	else
		RegisterSignal(target_mob, COMSIG_MOB_HUD_CREATED, PROC_REF(on_hud_created))

	check_ability_reqs_of_criteria(VAMPIRE_ABILITIES_ALL) // we only do it this way once

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

	clear_abilities()

/datum/antagonist/vampire/proc/on_life(datum/source, seconds_per_tick, times_fired)
	SIGNAL_HANDLER
	adjust_lifeforce(lifeforce_per_second * seconds_per_tick)

