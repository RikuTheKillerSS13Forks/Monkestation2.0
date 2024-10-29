//UNIMPLEMENTED
//explodes on death, blinding(and damaging?) nearby non zombies
/datum/species/zombie/infectious/bloater
	name = "Bloater Zombie"
	bodypart_overlay_icon_states = list(BODY_ZONE_CHEST = "bloater-chest")
	granted_action_types = list(
		/datum/action/cooldown/zombie/feast,
		/datum/action/cooldown/zombie/melt_wall,
	)

/datum/action/cooldown/zombie/melt_wall/corrosion
	name = "Stomach Acid"
	desc = "Drench an object in stomach acid, destroying it over time."
	button_icon_state = "alien_acid"
	c

/datum/action/cooldown/zombie/melt_wall/set_click_ability(mob/on_who)
	. = ..()
	if(!.)
		return

	to_chat(on_who, span_notice("You prepare to vomit. <b>Click a target to puke on it!</b>"))
	on_who.update_icons()

/datum/action/cooldown/zombie/melt_wall/unset_click_ability(mob/on_who, refund_cooldown = TRUE)
	. = ..()
	if(!.)
		return

	if(refund_cooldown)
		to_chat(on_who, span_notice("You empty your mouth."))
	on_who.update_icons()

/datum/action/cooldown/zombie/melt_wall/PreActivate(atom/target)
	if(get_dist(owner, target) > 1)
		return FALSE
	if(ismob(target)) //If it could corrode mobs, it would one-shot them.
		owner.balloon_alert(owner, "doesn't work on mobs!")
		return FALSE

	return ..()

/datum/action/cooldown/zombie/melt_wall/Activate(atom/target)
	if(!target.acid_act(200, 1000))
		to_chat(owner, span_notice("You cannot dissolve this object."))
		return FALSE

	owner.visible_message(
		span_alert("[owner] vomits globs of vile stuff all over [target]. It begins to sizzle and melt under the bubbling mess of acid!"),
		span_notice("You vomit globs of acid over [target]. It begins to sizzle and melt."),
	)
	return TRUE
