/mob/living/carbon/human/register_init_signals()
	. = ..()

	cascade_trait(TRAIT_HUSK, TRAIT_NOBLOOD)

	RegisterSignal(src, SIGNAL_ADDTRAIT(TRAIT_PALE_GREY_SKIN), PROC_REF(on_pale_grey_skin_trait_gain))
	RegisterSignal(src, SIGNAL_REMOVETRAIT(TRAIT_PALE_GREY_SKIN), PROC_REF(on_pale_grey_skin_trait_loss))

/mob/living/carbon/human/proc/on_pale_grey_skin_trait_gain(datum/source)
	SIGNAL_HANDLER
	for(var/obj/item/bodypart/part as anything in bodyparts)
		part.variable_color = "#b8b8b8"
	update_body_parts()

/mob/living/carbon/human/proc/on_pale_grey_skin_trait_loss(datum/source)
	SIGNAL_HANDLER
	for(var/obj/item/bodypart/part as anything in bodyparts)
		part.variable_color = null
	update_body_parts()
