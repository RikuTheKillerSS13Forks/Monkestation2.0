/obj/structure/persuasion_rack
	name = "persuasion rack"
	desc = "If this wasn't meant for torture, then someone has some fairly horrifying hobbies."
	icon = 'monkestation/icons/vampires/vampire_obj.dmi'
	icon_state = "vassalrack"
	anchored = TRUE
	density = TRUE
	can_buckle = TRUE
	buckle_lying = 180
	/// How many times the victim has been successfully tortured.
	var/progress = 0

/obj/structure/persuasion_rack/proc/torture(mob/living/user, mob/living/victim)
	if(QDELETED(user) || DOING_INTERACTION(user, DOAFTER_SOURCE_PERSUASION_RACK))
		return
	if(QDELETED(victim))
		balloon_alert(user, "nobody buckled!")
		return
	if(!victim.mind)
		balloon_alert(user, "no mind to break!")
		return
	if(IS_THRALL(victim))
		balloon_alert(user, "[victim.p_they()] [victim.p_are()] already a thrall!")
		return
	if(IS_VAMPIRE(victim))
		balloon_alert(user, "[victim.p_they()] [victim.p_are()] already a vampire!")
		return
	if(HAS_MIND_TRAIT(victim, TRAIT_UNCONVERTABLE))
		balloon_alert(user, "[victim.p_their()] mind cannot be broken!")
		return
	if(!HAS_TRAIT(victim, TRAIT_MINDSHIELD) || HAS_MIND_TRAIT(victim, TRAIT_MIND_BREAK))
		balloon_alert(user, "[victim.p_their()] mind is already vulnerable!")
		return
	var/obj/item/torture_tool = find_torture_tool(user)
	if(!torture_tool)
		balloon_alert(user, "you need a sharp or hot item to torture!")
		return

/obj/structure/persuasion_rack/proc/find_torture_tool(mob/living/user)
	var/obj/item/tool
	if(is_eligible_tool(tool = user.get_active_held_item()))
		return tool
	else if(is_eligible_tool(tool = user.get_inactive_held_item()))
		return tool
	else
		return null

/obj/structure/persuasion_rack/proc/is_eligible_tool(obj/item/tool)
	if(!isitem(tool) || QDELING(tool))
		return FALSE
	return (tool.get_temperature() > 0) || (tool.get_sharpness() > 0)

/obj/structure/persuasion_rack/buckle_mob(mob/living/M, force, check_loc)
	. = ..()
	if(.)
		progress = 0

/obj/structure/persuasion_rack/unbuckle_mob(mob/living/buckled_mob, force, can_fall)
	. = ..()
	if(.)
		progress = 0
