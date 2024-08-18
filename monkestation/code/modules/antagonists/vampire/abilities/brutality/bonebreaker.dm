/datum/vampire_ability/bonebreaker
	name = "Bonebreaker"
	desc = "Your punches deal more damage.<br> \
		Scales with Brutality."
	stat_reqs = list(VAMPIRE_STAT_BRUTALITY = 1)

	var/damage_mod

/datum/vampire_ability/bonebreaker/on_grant()
	RegisterSignal(owner, COMSIG_VAMPIRE_STAT_CHANGED_MOD, PROC_REF(on_stat_changed))

/datum/vampire_ability/bonebreaker/on_grant_mob()
	update_mod()

/datum/vampire_ability/bonebreaker/on_remove()
	RegisterSignal(owner, COMSIG_VAMPIRE_STAT_CHANGED_MOD, PROC_REF(on_stat_changed))

/datum/vampire_ability/bonebreaker/on_remove_mob()
	user.physiology.unarmed_damage_mod /= damage_mod

/datum/vampire_ability/bonebreaker/proc/on_stat_changed(datum/source, stat)
	SIGNAL_HANDLER
	if(stat != VAMPIRE_STAT_BRUTALITY)
		return
	update_mod()

/datum/vampire_ability/bonebreaker/proc/update_mod()
	if(!isnull(damage_mod))
		user.physiology.unarmed_damage_mod /= damage_mod

	damage_mod = 1 + (owner.get_stat(VAMPIRE_STAT_BRUTALITY) / VAMPIRE_SP_MAXIMUM) * 2 // 3x punch damage at max
	user.physiology.unarmed_damage_mod *= damage_mod
