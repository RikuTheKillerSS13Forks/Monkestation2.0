/mob/living/basic/droid
	name = "droid"
	desc = "This one seems... inert. So inert that you should ahelp it."
	melee_attack_cooldown = CLICK_CD_MELEE
	mob_biotypes = MOB_HUMANOID | MOB_ROBOTIC
	sentience_type = SENTIENCE_ARTIFICIAL

/mob/living/basic/droid/emp_reaction(severity)
	visible_message(
		message = span_danger("\The [src] locks up as sparks fly from its circuits!"),
		self_message = span_userdanger("EL*CT#OM#GNE*IC INTE*FE#ENCE DE*ECT- BZ*Z#*T"),
		blind_message = span_hear("You hear sparking."),
	)
	playsound(src, SFX_SPARKS, vol = 75, vary = TRUE)

	Stun(2 SECONDS)
	apply_damage(40 / severity)
