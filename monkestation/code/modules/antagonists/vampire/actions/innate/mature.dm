/datum/action/cooldown/vampire/rank
	name = "Mature"
	desc = "Grow closer to your ancient lineage through sacrificing your lifeforce."
	cooldown_time = 10 SECONDS

/datum/action/cooldown/vampire/rank/New(Target)
	. = ..()
	RegisterSignal(vampire, COMSIG_VAMPIRE_RANK_CHANGED, PROC_REF(update_cost))

/datum/action/cooldown/vampire/rank/Destroy()
	. = ..()
	UnregisterSignal(vampire, COMSIG_VAMPIRE_RANK_CHANGED)

/datum/action/cooldown/vampire/rank/IsAvailable(feedback)
	if(!..())
		return FALSE

	if(vampire.vampire_rank >= VAMPIRE_RANK_MAX)
		owner.balloon_alert(owner, "maxed out!")
		return FALSE

/datum/action/cooldown/vampire/rank/Activate()
	if(vampire.vampire_rank >= VAMPIRE_RANK_MAX)
		to_chat(owner, span_boldnotice("You've done it! You've reached the epitome of vampiric prowess!"))
	else
		to_chat(owner, span_boldnotice("You feel your body quiver as your biology morphs closer to your ancient lineage. You feel stronger."))

	vampire.set_rank(vampire.vampire_rank + 1)

/datum/action/cooldown/vampire/rank/proc/update_cost()
	SIGNAL_HANDLER
	life_cost = VAMPIRE_RANKUP_COST + VAMPIRE_RANKUP_SCALING * vampire.vampire_rank
	update_button()
