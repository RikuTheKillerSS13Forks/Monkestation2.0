/datum/antagonist/brother
	var/datum/action/bb/comms/comms_action
	var/datum/action/bb/gear/gear_action
	var/datum/action/cooldown/brother/one_mind/swap_action

/datum/antagonist/brother/on_gain()
	. = ..()
	// stupid hack to ensure the whole "can't see objectives" thing doesn't happen
	if(!team.has_recruited())
		addtimer(CALLBACK(owner, TYPE_PROC_REF(/datum/mind, announce_objectives)), 5)

// Apply team-specific antag HUD.
/datum/antagonist/brother/apply_innate_effects(mob/living/mob_override)
	. = ..()
	if(QDELETED(comms_action))
		comms_action = new(src)
	if(QDELETED(gear_action) && !team.summoned_gear)
		gear_action = new(src)
	if(QDELETED(swap_action))
		swap_action = new(src)
	var/mob/living/target = mob_override || owner.current
	comms_action.Grant(target)
	gear_action?.Grant(target)
	swap_action.Grant(target)
	add_team_hud(target, /datum/antagonist/brother, REF(team))
	RegisterSignal(target, COMSIG_BB_CLEAR_ABILITIES, PROC_REF(clear_abilities))

/datum/antagonist/brother/remove_innate_effects(mob/living/mob_override)
	. = ..()
	var/mob/living/target = mob_override || owner.current
	if(!QDELETED(comms_action))
		comms_action.Remove(target)
	if(!QDELETED(gear_action))
		gear_action.Remove(target)
	if(!QDELETED(swap_action))
		swap_action.Remove(target)
	UnregisterSignal(target, COMSIG_BB_CLEAR_ABILITIES)

/datum/antagonist/brother/create_team(datum/team/brother_team/new_team)
	. = ..()
	if(new_team)
		set_hud_keys(REF(new_team))

/datum/antagonist/brother/antag_token(datum/mind/hosts_mind, mob/spender)
	if(isobserver(spender))
		var/mob/living/carbon/human/new_mob = spender.change_mob_type(/mob/living/carbon/human, delete_old_mob = TRUE)
		new_mob.equipOutfit(/datum/outfit/job/assistant)
		hosts_mind = new_mob.mind
	var/datum/team/brother_team/team = new
	team.add_member(hosts_mind)
	team.forge_brother_objectives()
	hosts_mind.add_antag_datum(/datum/antagonist/brother, team)

/datum/antagonist/brother/proc/communicate(message)
	if(!istext(message) || !length(message) || QDELETED(owner) || QDELETED(team))
		return
	owner.current.log_talk(html_decode(message), LOG_SAY, tag = "blood brother")
	var/formatted_msg = "<span class='cfc_red'><b><i>\[Blood Bond\]</i> [span_name("[owner.name]")]</b>: [message]</span>"
	for(var/datum/mind/brother as anything in team.members)
		var/mob/living/target = brother.current
		if(brother != owner)
			target.balloon_alert(target, "you hear a voice")
			target.playsound_local(get_turf(target), 'goon/sounds/radio_ai.ogg', vol = 25, vary = FALSE, pressure_affected = FALSE, use_reverb = FALSE)
		to_chat(target, formatted_msg, type = MESSAGE_TYPE_RADIO, avoid_highlighting = (brother == owner))
	for(var/dead_mob in GLOB.dead_mob_list)
		var/link = FOLLOW_LINK(dead_mob, owner.current)
		to_chat(dead_mob, "[link] [formatted_msg]", type = MESSAGE_TYPE_RADIO)

/datum/antagonist/brother/proc/clear_abilities(mob/living/target) // done to avoid action duplication with mind swap, it's a hack but whatever
	SIGNAL_HANDLER
	if(target.mind == owner)
		return
	remove_innate_effects(target)
	if(target.stat != DEAD && !LAZYLEN(target.mind?.antag_datums))
		target.remove_from_current_living_antags()
	var/datum/action/antag_info/info_button = info_button_ref?.resolve()
	info_button?.Remove(target)
