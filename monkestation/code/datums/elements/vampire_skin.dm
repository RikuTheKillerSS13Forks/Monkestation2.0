// Makes your skin grey. That's all this does.
// This is my response to our skin color pipeline being ass.
// Because I'm too much of a pussy to actually fix it.

/datum/element/vampire_skin/Attach(mob/living/carbon/human/target)
	. = ..()

	if(!ishuman(target))
		return ELEMENT_INCOMPATIBLE

	for(var/obj/item/bodypart/bodypart in target.bodyparts)
		bodypart.variable_color = "#bbbbbb"
	target.update_body_parts()

	RegisterSignal(target, COMSIG_CARBON_ATTACH_LIMB, PROC_REF(on_attach_limb))

/datum/element/vampire_skin/Detach(mob/living/carbon/human/target, ...)
	. = ..()

	for(var/obj/item/bodypart/bodypart in target.bodyparts)
		bodypart.variable_color = null
	target.update_body_parts()

	UnregisterSignal(target, COMSIG_CARBON_ATTACH_LIMB)

/datum/element/vampire_skin/proc/on_attach_limb(datum/source, obj/item/bodypart/new_limb, special)
	SIGNAL_HANDLER
	new_limb.variable_color = "#bbbbbb"
