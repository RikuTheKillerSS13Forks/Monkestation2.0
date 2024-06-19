/mob/living/carbon/register_init_signals()
	. = ..()

	RegisterSignal(src, SIGNAL_ADDTRAIT(TRAIT_NOHARDCRIT), PROC_REF(on_nohardcrit_trait_gain))
	RegisterSignal(src, SIGNAL_REMOVETRAIT(TRAIT_NOHARDCRIT), PROC_REF(on_nohardcrit_trait_gain))

	RegisterSignal(src, SIGNAL_ADDTRAIT(TRAIT_NOPASSOUT), PROC_REF(on_nopassout_trait_gain))
	RegisterSignal(src, SIGNAL_REMOVETRAIT(TRAIT_NOPASSOUT), PROC_REF(on_nopassout_trait_gain))

/mob/living/carbon/proc/on_nohardcrit_trait_gain(datum/source)
	SIGNAL_HANDLER
	REMOVE_TRAIT(src, TRAIT_KNOCKEDOUT, CRIT_HEALTH_TRAIT)

/mob/living/carbon/proc/on_nohardcrit_trait_loss(datum/source)
	SIGNAL_HANDLER
	if (health <= hardcrit_threshold)
		ADD_TRAIT(src, TRAIT_KNOCKEDOUT, CRIT_HEALTH_TRAIT)

/mob/living/carbon/proc/on_nopassout_trait_gain(datum/source)
	SIGNAL_HANDLER
	REMOVE_TRAIT(src, TRAIT_KNOCKEDOUT, OXYLOSS_TRAIT)

/mob/living/carbon/proc/on_nopassout_trait_loss(datum/source)
	SIGNAL_HANDLER
	if(getOxyLoss() > 50)
		ADD_TRAIT(src, TRAIT_KNOCKEDOUT, OXYLOSS_TRAIT)
