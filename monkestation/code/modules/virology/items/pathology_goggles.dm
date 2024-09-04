/obj/item/clothing/glasses/pathology
	name = "optical viral analyzer"
	desc = "A pair of goggles fitted with an analyzer for viral particles and reagents. Comes with a handy toggle for avoiding visual overload."
	gender = NEUTER

	icon = 'monkestation/icons/obj/clothing/glasses.dmi'
	worn_icon = 'monkestation/icons/obj/clothing/eyes.dmi'
	icon_state = "pathology_on"
	worn_icon_state = "pathology_on"
	inhand_icon_state = "glasses"

	glass_colour_type = /datum/client_colour/glass_colour/lightgreen
	clothing_traits = list(TRAIT_REAGENT_SCANNER)
	actions_types = list(/datum/action/item_action/toggle_virus_view)

	var/enabled = TRUE

/obj/item/clothing/glasses/pathology/proc/enable(mob/M)
	ADD_TRAIT(M, TRAIT_VIRUS_SCANNER, REF(src))
	enabled = TRUE

	icon_state = "pathology_on"
	worn_icon_state = "pathology_on"

	M.update_worn_glasses()
	update_item_action_buttons()

	playsound(get_turf(src), 'sound/machines/click.ogg', vol = 30, vary = TRUE)

/obj/item/clothing/glasses/pathology/proc/disable(mob/M)
	REMOVE_TRAIT(M, TRAIT_VIRUS_SCANNER, REF(src))
	enabled = FALSE

	icon_state = "pathology_off"
	worn_icon_state = "pathology_off"

	M.update_worn_glasses()
	update_item_action_buttons()

	playsound(get_turf(src), 'sound/machines/click.ogg', vol = 30, vary = TRUE)

/obj/item/clothing/glasses/pathology/item_action_slot_check(slot, mob/user)
	return slot & ITEM_SLOT_EYES

/obj/item/clothing/glasses/pathology/ui_action_click(mob/user, actiontype)
	if(enabled)
		disable(user)
	else
		enable(user)

/obj/item/clothing/glasses/pathology/equipped(mob/M, slot)
	..()
	if(slot != ITEM_SLOT_EYES)
		return
	if(enabled)
		enable(M)
	RegisterSignal(M, COMSIG_MOB_UNEQUIPPED_ITEM, PROC_REF(clear_effects))

/obj/item/clothing/glasses/pathology/proc/clear_effects(mob/living/source, obj/item/dropped_item)
	SIGNAL_HANDLER
	if(dropped_item != src)
		return
	if (!source.client)
		return
	disable(source)
	UnregisterSignal(source, list(COMSIG_MOB_UNEQUIPPED_ITEM))

/mob/proc/virusView()
	if(!client)
		return
	GLOB.pathology_goggles_wearers.Add(src)
	for (var/obj/item/I in GLOB.infected_items)
		if (I.pathogen)
			client.images |= I.pathogen
	for (var/mob/living/L in GLOB.infected_contact_mobs)
		if (L.pathogen)
			client.images |= L.pathogen
	for (var/obj/effect/pathogen_cloud/C as anything in GLOB.pathogen_clouds)
		if (C.pathogen)
			client.images |= C.pathogen
	for (var/obj/effect/decal/cleanable/C in GLOB.infected_cleanables)
		if (C.pathogen)
			client.images |= C.pathogen

/mob/proc/stopvirusView()
	if(!client)
		return
	GLOB.pathology_goggles_wearers.Remove(src)
	for (var/obj/item/I in GLOB.infected_items)
		client.images -= I.pathogen
	for (var/mob/living/L in GLOB.infected_contact_mobs)
		client.images -= L.pathogen
	for(var/obj/effect/pathogen_cloud/C as anything in GLOB.pathogen_clouds)
		client.images -= C.pathogen
	for (var/obj/effect/decal/cleanable/C in GLOB.infected_cleanables)
		client.images -= C.pathogen
