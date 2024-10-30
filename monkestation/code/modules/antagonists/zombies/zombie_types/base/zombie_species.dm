// I would like to convert these to their own datum type but I have like 2 hours so this is what we are getting.
/datum/species/zombie/infectious
	/// The path of mutant hands to give this zombie.
	var/obj/item/mutant_hand/zombie/hand_path = /obj/item/mutant_hand/zombie

	/// The list of action types to give on gain.
	var/list/granted_action_types = list(
		/datum/action/cooldown/zombie/feast,
		/datum/action/cooldown/zombie/evolve,
	)

	/// The list of action instances we have actually granted.
	var/list/granted_actions = list()

	/// File that bodypart_overlay_icon_states pulls from.
	var/list/bodypart_overlay_icon = 'monkestation/icons/mob/species/zombie/special_zombie_overlays.dmi'

	/// Associative list of bodypart overlays by body zone.
	var/list/bodypart_overlay_icon_states = list()

	/// How much flesh we've consumed. Used for evolving.
	var/consumed_flesh = 0

/datum/species/zombie/infectious/on_species_gain(mob/living/carbon/C, datum/species/old_species)
	. = ..()
	for(var/zone as anything in bodypart_overlay_icon_states)
		var/obj/item/bodypart/bodypart = C.get_bodypart(zone)
		if(!bodypart)
			continue

		var/overlay_state = bodypart_overlay_icon_states[zone]
		var/datum/bodypart_overlay/simple/overlay = new
		overlay.icon = bodypart_overlay_icon
		overlay.icon_state = overlay_state
		overlay.layers = EXTERNAL_ADJACENT | EXTERNAL_FRONT

		bodypart.add_bodypart_overlay(overlay)
