/atom/movable/screen/alert/status_effect/vampire
	icon = 'monkestation/icons/vampires/vampire_actions.dmi'
	alerttooltipstyle = "cult"

/atom/movable/screen/alert/status_effect/vampire/Initialize(mapload, datum/hud/hud_owner)
	var/image/underlay = image(icon = 'monkestation/icons/vampires/vampire_actions.dmi', icon_state = "status_effect_bg")

	if(clickable_glow)
		underlay.add_filter("clickglow", 2, outline_filter(color = COLOR_GOLD, size = 1))
		mouse_over_pointer = MOUSE_HAND_POINTER

	underlays += underlay
	clickable_glow = FALSE // So it doesn't add the default one.
	return ..()


/datum/status_effect/vampire
	var/mob/living/carbon/human/user
	var/datum/antagonist/vampire/antag_datum

/datum/status_effect/vampire/on_apply()
	user = owner
	if (!istype(user))
		CRASH("Vampire status effect with ID \"[id]\" added to non-human mob \"[user]\".")

	antag_datum = user.mind?.has_antag_datum(/datum/antagonist/vampire)
	if (!antag_datum)
		CRASH("Vampire status effect with ID \"[id]\" added to non-vampire mob \"[user]\".")

	return TRUE

// Registering to COMSIG_QDELETING on the antag datum might bring issues, just have the antag datum clean these up.
// The reason for this is that a decent chunk of these might have effects on removal that are... undesirable.
// Like frenzy, which will kill you. We don't want that if the antag datum is deleted! So be careful.
// Things that add these are responsible for cleaning them up, like Regeneration is for Torpor.
/datum/status_effect/vampire/Destroy()
	. = ..()

	user = null
	antag_datum = null

/datum/status_effect/vampire/proc/on_antag_datum_deleted()
	SIGNAL_HANDLER
	qdel(src)
