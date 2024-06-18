/datum/action/cooldown/spell/touch/sacrifice
	name = "Sacrifice"
	desc = "Lend your power to one of your brothers. Can revive a brother at the cost of your own life."

	background_icon = 'monkestation/icons/mob/actions/backgrounds.dmi'
	background_icon_state = "bg_syndie"
	button_icon = 'monkestation/icons/mob/actions/actions_bb.dmi'
	button_icon_state = "sacrifice"
	transparent_when_unavailable = TRUE

	sound = 'monkestation/sound/effects/cracklewhoosh.ogg'

	cooldown_time = 5 MINUTES

	school = SCHOOL_NECROMANCY
	antimagic_flags = MAGIC_RESISTANCE_MIND

	invocation = "S'C 'RA'TH!"
	invocation_type = INVOCATION_SHOUT
	spell_requirements = SPELL_CASTABLE_WITHOUT_INVOCATION

	hand_path = /obj/item/melee/touch_attack/sacrifice

	var/datum/antagonist/brother/bond
	var/datum/team/brother_team/team

/datum/action/cooldown/spell/touch/sacrifice/New(datum/antagonist/brother/target, original) // mm, repeat code
	if(!istype(target))
		CRASH("Attempted to create [type] without an associated antag datum!")
	bond = target
	team = target.get_team()
	return ..()

/datum/action/cooldown/spell/touch/sacrifice/IsAvailable(feedback)
	if(QDELETED(bond) || bond.owner != owner.mind)
		return FALSE
	if(QDELETED(team) || !(owner.mind in team.members))
		return FALSE
	if(length(team.members) < 2) // no point being able to use it when there's no one to use it on, also makes it match the others visually
		return FALSE
	if(HAS_TRAIT(owner, TRAIT_SACRIFICE))
		return FALSE
	return ..()

/datum/action/cooldown/spell/touch/sacrifice/cast_on_hand_hit(obj/item/melee/touch_attack/hand, atom/victim, mob/living/carbon/caster)
	var/mob/living/target = victim
	if(!istype(target))
		return

	if(HAS_TRAIT(target, TRAIT_SACRIFICE))
		return FALSE

	var/datum/antagonist/brother/target_bond = target.mind?.has_antag_datum(/datum/antagonist/brother)
	if(target_bond?.get_team() != team)
		return

	..() // it starts a cooldown and whatnot, the sacrifice proc overrides that

	if(target.stat == DEAD)
		true_sacrifice(target, target_bond)
	else
		sacrifice(target, target_bond)

	return TRUE

/datum/action/cooldown/spell/touch/sacrifice/proc/sacrifice(mob/living/target, datum/antagonist/brother/target_bond)
	var/mob/living/owner = src.owner
	var/datum/status_effect/sacrifice/owner_status = owner.apply_status_effect(/datum/status_effect/sacrifice/debuff)
	var/datum/status_effect/sacrifice/target_status = target.apply_status_effect(/datum/status_effect/sacrifice)
	owner_status.pair_ref = WEAKREF(target_status)
	target_status.pair_ref = WEAKREF(owner_status)

	owner.visible_message(
		message = span_danger("[owner] hits [target] with a glowing hand as a torrent of spiritual fire forms around each of them!"),
		self_message = span_boldnotice("You lend [target] some of your power!"),
		blind_message = span_hear("You hear a loud crackle."),
		ignored_mobs = list(target)
	)
	to_chat(target, span_boldnotice("[owner] lends some of [owner.p_their()] power to you!"))

/datum/action/cooldown/spell/touch/sacrifice/proc/true_sacrifice(mob/living/target, datum/antagonist/brother/target_bond)
	var/mob/living/owner = src.owner
	var/datum/status_effect/sacrifice/target_status = target.apply_status_effect(/datum/status_effect/sacrifice/true)

	owner.visible_message(
		message = span_bolddanger("[owner] hits [target] with a glowing hand and burns to ashes as a glorious torrent of spiritual fire forms around [target]!"),
		self_message = span_userdanger("You sacrifice yourself for [target]!"),
		blind_message = span_hear("You hear a loud crackle."),
		ignored_mobs = list(target)
	)

	REMOVE_TRAIT(target, TRAIT_KNOCKEDOUT, STAT_TRAIT)
	REMOVE_TRAIT(target, TRAIT_KNOCKEDOUT, CRIT_HEALTH_TRAIT)
	REMOVE_TRAIT(target, TRAIT_KNOCKEDOUT, OXYLOSS_TRAIT)

	target.set_stat(CONSCIOUS) // bypasses can_be_revived, also used by nooartrium
	target.updatehealth()
	target.update_sight()
	target.set_resting(FALSE, silent = TRUE, instant = TRUE) // wake up bro i kms to fix your ass
	target.SetAllImmobility(0)
	target.grab_ghost(force = FALSE)
	target.emote("gasp")

	to_chat(target, span_userdanger("[owner] sacrificed [owner.p_them()]self for you!"))

	owner.ghostize(can_reenter_corpse = FALSE) // bypasses the "x is no longer your brother!" message
	owner.dust(just_ash = TRUE, drop_items = TRUE, force = TRUE) // goodbye

	var/mob/living/carbon/human/user = target
	if(!istype(user))
		return

	if(user.handcuffed)
		var/obj/restraints = user.get_item_by_slot(ITEM_SLOT_HANDCUFFED)
		if(!istype(restraints))
			return
		user.visible_message(
			message = span_danger("[user]'s [restraints] blow[restraints.p_s()] apart!"),
			self_message = span_boldnotice("Your [restraints] blow[restraints.p_s()] apart!"),
			blind_message = span_hear("You hear a snap.")
		)
		playsound(user, 'sound/effects/snap.ogg', 100, TRUE)

	if(user.legcuffed)
		var/obj/restraints = user.get_item_by_slot(ITEM_SLOT_LEGCUFFED)
		if(!istype(restraints))
			return
		user.visible_message(
			message = span_danger("[user]'s [restraints] blow[restraints.p_s()] apart!"),
			self_message = span_boldnotice("Your [restraints] blow[restraints.p_s()] apart!"),
			blind_message = span_hear("You hear a snap.")
		)
		playsound(user, 'sound/effects/snap.ogg', 100, TRUE)

	if(user.wear_suit && user.wear_suit.breakouttime)
		var/obj/item/clothing/suit/restraints = user.get_item_by_slot(ITEM_SLOT_OCLOTHING)
		if(!istype(restraints))
			return
		user.visible_message(
			message = span_danger("[user]'s [restraints] rip[restraints.p_s()] apart!"),
			self_message = span_boldnotice("Your [restraints] rip[restraints.p_s()] apart!"),
			blind_message = span_hear("You hear a rip.")
		)
		playsound(user, 'sound/effects/cloth_rip.ogg', 100, TRUE)

/obj/item/melee/touch_attack/sacrifice
	name = "Sacrifice"
	desc = "A soft, yet fierce glow emanates from it. \
		When used on one of your brothers, grants them power at the cost of your own. \
		If used on a dead brother you'll sacrifice your life to revive them. \
		Revival grants an <b>extremely</b> powerful boost."
	icon = 'monkestation/icons/obj/weapons/hand.dmi'
	icon_state = "sacrifice"

/datum/status_effect/sacrifice
	id = "sacrifice"
	duration = 1 MINUTE
	alert_type = /atom/movable/screen/alert/status_effect/sacrifice
	tick_interval = 0 // this heals so fast i just had to
	status_type = STATUS_EFFECT_REPLACE

	var/datum/weakref/pair_ref
	var/strength = 0.3

	var/outline_color = "#c60000"

/datum/status_effect/sacrifice/on_creation(mob/living/new_owner, duration_override)
	. = ..()
	if(duration_override != null)
		duration = duration_override
	var/datum/antagonist/brother/bond = owner.mind?.has_antag_datum(/datum/antagonist/brother)
	bond?.sacrifice_action?.StartCooldown(duration) // do not move this, it's here for a reason

/datum/status_effect/sacrifice/on_apply()
	owner.add_filter(id, 2, outline_filter(color = outline_color, size = 1))

	ADD_TRAIT(owner, TRAIT_SACRIFICE, REF(src))

	RegisterSignal(owner, COMSIG_LIVING_DEATH, PROC_REF(on_death))
	RegisterSignal(owner.mind, COMSIG_MIND_TRANSFERRED, PROC_REF(on_mind_transferred))

	owner.add_or_update_variable_movespeed_modifier(/datum/movespeed_modifier/status_effect/sacrifice, multiplicative_slowdown = -strength)
	owner.add_or_update_variable_actionspeed_modifier(/datum/actionspeed_modifier/status_effect/sacrifice, multiplicative_slowdown = -strength)

	var/mob/living/carbon/human/human_owner = owner
	if(!istype(human_owner))
		return TRUE
	var/datum/physiology/physiology = human_owner.physiology

	var/multiplier = 1 - strength
	physiology.brute_mod *= multiplier
	physiology.burn_mod *= multiplier
	physiology.tox_mod *= multiplier
	physiology.oxy_mod *= multiplier
	physiology.stun_mod *= multiplier
	physiology.stamina_mod *= multiplier
	physiology.bleed_mod *= multiplier

	return TRUE

/datum/status_effect/sacrifice/on_remove(wait_for_transfer)
	owner.remove_filter(id)

	REMOVE_TRAITS_IN(owner, REF(src))

	UnregisterSignal(owner, COMSIG_LIVING_DEATH)

	if(!wait_for_transfer)
		UnregisterSignal(owner.mind, COMSIG_MIND_TRANSFERRED)

	owner.remove_movespeed_modifier(/datum/movespeed_modifier/status_effect/sacrifice)
	owner.remove_actionspeed_modifier(/datum/actionspeed_modifier/status_effect/sacrifice)

	var/mob/living/carbon/human/human_owner = owner
	if(!istype(human_owner))
		return
	var/datum/physiology/physiology = human_owner.physiology

	var/multiplier = 1 - strength
	physiology.brute_mod /= multiplier
	physiology.burn_mod /= multiplier
	physiology.tox_mod /= multiplier
	physiology.oxy_mod /= multiplier
	physiology.stun_mod /= multiplier
	physiology.stamina_mod /= multiplier
	physiology.bleed_mod /= multiplier

	var/datum/antagonist/brother/bond = owner.mind?.has_antag_datum(/datum/antagonist/brother)
	bond?.sacrifice_action?.StartCooldown() // real cooldown

/datum/status_effect/sacrifice/be_replaced()
	on_remove(wait_for_transfer = TRUE)
	INVOKE_ASYNC(src, PROC_REF(wait_for_transfer))

/datum/status_effect/sacrifice/proc/wait_for_transfer() // this is jank, but it's the most sane way i could think of
	var/datum/mind/mind = owner.mind
	sleep(1) // if you SOMEHOW swap twice within this time, good fucking job, you broke it!
	UnregisterSignal(mind, COMSIG_MIND_TRANSFERRED)

/datum/status_effect/sacrifice/proc/on_death(mob/living/corpse)
	SIGNAL_HANDLER
	corpse.remove_status_effect(type)
	var/datum/status_effect/sacrifice/pair = pair_ref?.resolve()
	pair?.owner?.remove_status_effect(pair.type)

/datum/status_effect/sacrifice/proc/on_mind_transferred(datum/mind/mind, mob/living/previous_body)
	SIGNAL_HANDLER
	if(!QDELETED(src))
		previous_body?.remove_status_effect(type)
	var/datum/status_effect/new_effect = mind.current.apply_status_effect(type, duration)
	var/datum/status_effect/sacrifice/pair = pair_ref?.resolve()
	pair?.pair_ref = WEAKREF(new_effect)

/datum/status_effect/sacrifice/debuff
	alert_type = /atom/movable/screen/alert/status_effect/sacrifice/debuff
	strength = -0.3
	outline_color = "#00afc6"

/datum/status_effect/sacrifice/true  // now, you'd think this is too much effort, but considering you have to round remove yourself to activate this, i just had to reward em ya know?
	duration = 30 SECONDS // shorter, but way, way stronger
	alert_type = /atom/movable/screen/alert/status_effect/sacrifice/true
	strength = 0.5
	outline_color = "#e40000"

	var/regrow_progress = 0

/datum/status_effect/sacrifice/true/on_apply()
	. = ..()

	owner.add_traits(list(
		TRAIT_NODEATH, // There is no immediate heal. That's why you get this instead.
		TRAIT_NOCRITDAMAGE,
		TRAIT_NOHARDCRIT,
		TRAIT_NOSOFTCRIT,
		TRAIT_NOCRITOVERLAY,
		TRAIT_IGNOREDAMAGESLOWDOWN,
		TRAIT_STABLEHEART, // I don't CARE if your heart can't beat, just live without it, dumbass.
		TRAIT_STABLELIVER, // You get to ignore your drinking problem, at least temporarily.
		TRAIT_NOLIMBDISABLE, // Imagine if they got revived only to be fucking handicapped. That'd suck.
		TRAIT_SLEEPIMMUNE, // This would probably be the worst out of all of them if I let it happen.
	), REF(src))

/datum/status_effect/sacrifice/true/tick(seconds_per_tick, times_fired)
	var/delta_time = min(DELTA_WORLD_TIME(SSfastprocess), max(0, duration - world.time)) // i want it to heal exactly 600 damage total and also lag is lame

	REMOVE_TRAIT(owner, TRAIT_KNOCKEDOUT, CRIT_HEALTH_TRAIT) // copied from nooartrium, not entirely sure if they're needed but they're here anyway
	REMOVE_TRAIT(owner, TRAIT_KNOCKEDOUT, OXYLOSS_TRAIT)

	var/brute = owner.getBruteLoss()
	var/burn = owner.getFireLoss()
	var/tox = owner.getToxLoss()
	var/oxy = owner.getOxyLoss()
	var/clone = owner.getCloneLoss()
	var/divisor = (brute + burn + tox + oxy + clone) / 20 / delta_time // divide by whatever you want it to heal per second

	if(divisor > 0)
		owner.adjustBruteLoss(-brute / divisor, updating_health = FALSE)
		owner.adjustFireLoss(-burn / divisor, updating_health = FALSE)
		owner.adjustToxLoss(-tox / divisor, updating_health = FALSE, forced = TRUE)
		owner.adjustOxyLoss(-oxy / divisor, updating_health = FALSE)
		owner.adjustCloneLoss(-clone / divisor, updating_health = FALSE)
		owner.updatehealth()

	var/organ_heal = -5 * delta_time
	owner.adjustOrganLoss(ORGAN_SLOT_BRAIN, organ_heal * 2)
	owner.adjustOrganLoss(ORGAN_SLOT_EYES, organ_heal)
	owner.adjustOrganLoss(ORGAN_SLOT_EARS, organ_heal)
	owner.adjustOrganLoss(ORGAN_SLOT_HEART, organ_heal)
	owner.adjustOrganLoss(ORGAN_SLOT_LUNGS, organ_heal)
	owner.adjustOrganLoss(ORGAN_SLOT_STOMACH, organ_heal)
	owner.adjustOrganLoss(ORGAN_SLOT_LIVER, organ_heal)

	if(owner.blood_volume < BLOOD_VOLUME_NORMAL)
		owner.blood_volume = min(owner.blood_volume + 10 * delta_time, BLOOD_VOLUME_NORMAL)

	var/mob/living/carbon/user = owner
	if(!istype(user))
		return

	var/list/missing_limbs = user.get_missing_limbs()

	regrow_progress = min(regrow_progress + 0.15 * delta_time, length(missing_limbs)) // one limb every 6 or so seconds

	while(regrow_progress >= 1 && length(missing_limbs)) // making this nigh perfect is overkill but if you're gonna do it, then might as well go all the way
		var/picked = pick(missing_limbs)
		user.regenerate_limb(picked)
		missing_limbs -= picked
		regrow_progress--
		var/zone_name = parse_zone(picked)
		user.visible_message(
			message = span_danger("[user]'s [zone_name] regrows!"),
			self_message = span_green("Your [zone_name] regrows!"),
			blind_message = span_hear("You hear a wet crunch.")
		)
		playsound(user, 'sound/magic/demon_consume.ogg', 50, TRUE)

	for(var/datum/wound/wound as anything in user.all_wounds)
		wound.heal(rand(0.05, 0.15) * delta_time) // variance to avoid getting multiple messages at once

/atom/movable/screen/alert/status_effect/sacrifice
	name = "Sacrifice"
	desc = "You feel empowered!"
	icon = 'monkestation/icons/hud/screen_alert.dmi'
	icon_state = "sacrifice"

/atom/movable/screen/alert/status_effect/sacrifice/debuff
	name = "Sacrifice"
	desc = "You feel lethargic."
	icon_state = "sacrifice_debuff"

/atom/movable/screen/alert/status_effect/sacrifice/true
	name = "True Sacrifice"
	desc = span_bolddanger("ONE LAST STAND!!")
	icon_state = "sacrifice_true"
