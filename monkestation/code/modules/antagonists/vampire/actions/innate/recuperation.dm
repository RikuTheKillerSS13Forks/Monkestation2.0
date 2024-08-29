// these thresholds are in recovery stat points
#define REGEN_THRESHOLD_TOX 15 // heals tox and clone
#define REGEN_THRESHOLD_WOUNDS 20 // heals wounds
#define REGEN_THRESHOLD_OXY 25 // heals oxy
#define REGEN_THRESHOLD_ORGANS 30 // heals organs and mild brain traumas
#define REGEN_THRESHOLD_PURGE 35 // purges toxic reagents
#define REGEN_THRESHOLD_REGROW_LIMBS 40 // regrows limbs
#define REGEN_THRESHOLD_REGROW_ORGANS 45 // regrows organs and heals severe brain traumas
#define REGEN_THRESHOLD_REVIVE 50 // revives from death

/datum/action/cooldown/vampire/recuperation
	name = "Recuperation"
	desc = "Greatly increase your recovery rate from physical injuries. Drains lifeforce when healing and doesn't work in masquerade."
	button_icon_state = "power_recup"
	toggleable = TRUE
	works_in_masquerade = TRUE // on_life still prevents it from working, but you can toggle it if you want
	has_custom_life_cost = TRUE

/datum/action/cooldown/vampire/recuperation/New(Target)
	. = ..()
	RegisterSignal(vampire, COMSIG_VAMPIRE_STAT_CHANGED_MOD, PROC_REF(on_stat_changed))
	update_recovery_scaling(vampire.get_stat_modified(VAMPIRE_STAT_RECOVERY))

/datum/action/cooldown/vampire/recuperation/Destroy()
	. = ..()
	UnregisterSignal(vampire, COMSIG_VAMPIRE_STAT_CHANGED_MOD)

/datum/action/cooldown/vampire/recuperation/Grant(mob/granted_to)
	. = ..()
	toggle_on()

/datum/action/cooldown/vampire/recuperation/on_toggle_on()
	RegisterSignal(owner, COMSIG_LIVING_LIFE, PROC_REF(on_life))

/datum/action/cooldown/vampire/recuperation/on_toggle_off()
	UnregisterSignal(owner, COMSIG_LIVING_LIFE)

/datum/action/cooldown/vampire/recuperation/proc/on_life(datum/source, seconds_per_tick, times_fired)
	SIGNAL_HANDLER

	if(vampire.masquerade_enabled)
		return

	var/regen_rate = vampire.regen_rate_modifier.get_value()
	var/base_regen_rate = vampire.regen_rate_modifier.get_base_value()
	var/regen_level = vampire.get_stat(VAMPIRE_STAT_RECOVERY)

	if(owner.stat == DEAD)
		if(regen_level < REGEN_THRESHOLD_REVIVE)
			return
		regen_rate *= 1.5 // regen faster while dead

	var/list/dmg = list(
		BRUTE = user.getBruteLoss(),
		BURN = user.getFireLoss()
	)

	if(regen_level >= REGEN_THRESHOLD_TOX)
		dmg[TOX] = user.getToxLoss()
		dmg[CLONE] = user.getCloneLoss()

	if(regen_level >= REGEN_THRESHOLD_OXY)
		dmg[OXY] = user.getOxyLoss()

	var/total_damage = 0
	for(var/dmgType as anything in dmg)
		var/amount = dmg[dmgType]
		if(!amount)
			dmg -= dmgType
			continue
		total_damage += amount

	var/total_life_cost = 0

	if(total_damage > 0)
		var/list/ratios = list()
		for(var/dmgType as anything in dmg)
			ratios[dmgType] = dmg[dmgType] / total_damage
		for(var/dmgType as anything in ratios)
			user.heal_damage_type(-regen_rate * ratios[dmgType] * seconds_per_tick, dmgType)
		total_life_cost += min(total_damage, regen_rate * seconds_per_tick) / 6 // 1 lifeforce per 6 damage healed

	if(regen_level >= REGEN_THRESHOLD_ORGANS)
		var/organ_regen_amount = regen_rate * 0.1 * seconds_per_tick // 0.2 - 0.3 healing per second in practice (about 5 minutes to heal 100 at 60 recovery)
		for(var/obj/item/organ/internal/organ in user.organs)
			if(organ.damage <= 0 && !(organ.organ_flags & ORGAN_FAILING))
				continue
			if((organ.organ_flags & ORGAN_FAILING) && !SPT_PROB(regen_rate * 2, seconds_per_tick)) // up to 6% chance per second per organ to recover from failure
				continue
			total_life_cost += min(organ.damage, organ_regen_amount) * 0.05 // 1 lifeforce per 20 organ damage healed
			organ.apply_organ_damage(-organ_regen_amount)

	if(regen_level >= REGEN_THRESHOLD_PURGE)
		var/toxin_purge_amount = regen_rate * 0.2 * seconds_per_tick // 0.43u - 0.6u per second in practice (time is entirely dependent on dosage)
		for(var/datum/reagent/toxin/toxin in user.reagents.reagent_list) // only purges toxins, purging meth would be laame
			total_life_cost += min(toxin.volume, toxin_purge_amount) * 0.2 // 1 lifeforce per 5u toxins purged
			user.reagents.remove_reagent(toxin.type, toxin_purge_amount)

	if(regen_level >= REGEN_THRESHOLD_REGROW_LIMBS)
		total_life_cost += handle_regrow(regen_rate, regen_level, seconds_per_tick)

	vampire.adjust_lifeforce(-total_life_cost)

/// Handles regrowing both organs and limbs. Limbs take priority because performance and honestly they're more important anyway.
/// Returns the amount of lifeforce the whole thing cost.
/datum/action/cooldown/vampire/recuperation/proc/handle_regrow(regen_rate, regen_level, seconds_per_tick)
	if(!SPT_PROB(regen_rate * 2, seconds_per_tick)) // up to 6% chance per second to regrow something (also makes the performance impact negligible)
		return 0

	var/missing_zones = user.get_missing_limbs()
	if(length(missing_zones))
		var/regrow_zone = pick(missing_zones)
		user.regenerate_limb(regrow_zone)
		var/obj/item/bodypart/new_limb = user.get_bodypart(regrow_zone)
		if(!new_limb) // i hope for the sake of this codebase that this hopefully pointless check never passes
			return 0
		playsound(user, 'sound/magic/demon_consume.ogg', vol = 50, vary = TRUE)
		user.visible_message(
			message = span_danger("[user]'s flesh shifts nauseatingly as [user.p_their()] [new_limb.plaintext_zone] regrows!"),
			self_message = span_green("Your flesh shifts as your [new_limb.plaintext_zone] regrows!"),
			blind_message = span_hear("You hear a wet crunch!")
		)
		return 10 // low? yeah, but you're also at least recovery 40 so come on

	if(regen_level < REGEN_THRESHOLD_REGROW_ORGANS)
		return 0

	var/datum/dna/dna = user.has_dna()
	if(!dna)
		return 0 // nope fuck that

	// Unlike limb regrowth, this is in order of priority.
	var/valid_slots = list(
		ORGAN_SLOT_EYES, // seeing is the most important thing
		ORGAN_SLOT_LUNGS, // right behind breathing
		ORGAN_SLOT_EARS, // hearing you can go without for a bit
		ORGAN_SLOT_LIVER, // a liver? definitely can go without
		ORGAN_SLOT_HEART, // you can go without it entirely but fixing your tongue and ass before your heart would be fucking weird
		ORGAN_SLOT_STOMACH, // your hunger is based on your lifeforce so this is useless too
		ORGAN_SLOT_TONGUE, // next up, speaking properly
		ORGAN_SLOT_BUTT, // clearly, farting is more important than pissing
		ORGAN_SLOT_BLADDER
	)

	for(var/slot as anything in valid_slots)
		var/obj/item/organ/organ = user.get_organ_slot(slot)
		if(organ)
			continue
		var/organ_type = dna.species?.get_mutant_organ_type_for_slot(slot)
		if(!organ_type)
			continue
		organ = new organ_type
		organ.Insert(user, special = TRUE, drop_if_replaced = FALSE)
		to_chat(user, span_green("You feel an odd sensation as your [organ.name] regrow[organ.p_s()]!"))
		user.playsound_local(get_turf(user), 'sound/magic/demon_consume.ogg', vol = 20, vary = TRUE)
		return 5 // getting gutted shouldnt cost 50 lifeforce

	return 0

/datum/action/cooldown/vampire/recuperation/proc/on_stat_changed(datum/source, stat, old_amount, new_amount)
	SIGNAL_HANDLER
	if(stat != VAMPIRE_STAT_RECOVERY)
		return
	update_recovery_scaling(new_amount)

/datum/action/cooldown/vampire/recuperation/proc/update_recovery_scaling(recovery)
	vampire.regen_rate_modifier.set_multiplicative(VAMPIRE_STAT_RECOVERY, 1 + recovery / VAMPIRE_SP_MAXIMUM * 2) // 3x regen rate at max recovery

#undef REGEN_THRESHOLD_TOX
#undef REGEN_THRESHOLD_WOUNDS
#undef REGEN_THRESHOLD_OXY
#undef REGEN_THRESHOLD_ORGANS
#undef REGEN_THRESHOLD_PURGE
#undef REGEN_THRESHOLD_REGROW_LIMBS
#undef REGEN_THRESHOLD_REGROW_ORGANS
#undef REGEN_THRESHOLD_REVIVE
