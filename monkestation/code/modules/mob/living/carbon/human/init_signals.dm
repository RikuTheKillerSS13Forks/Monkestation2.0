/mob/living/carbon/human/register_init_signals()
	. = ..()

	cascade_trait(TRAIT_HUSK, TRAIT_NOBLOOD)
