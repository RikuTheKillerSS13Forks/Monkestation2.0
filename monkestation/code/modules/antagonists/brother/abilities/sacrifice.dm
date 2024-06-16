/datum/action/cooldown/spell/touch/sacrifice
	name = "Sacrifice"
	desc = "Lend your power to one of your brothers. Can revive a brother at the cost of your own life."

	background_icon = 'monkestation/icons/mob/actions/backgrounds.dmi'
	background_icon_state = "bg_syndie"
	button_icon = 'monkestation/icons/mob/actions/actions_bb.dmi'
	button_icon_state = "sacrifice"
	transparent_when_unavailable = TRUE

	cooldown_time = 5 MINUTES

	school = SCHOOL_NECROMANCY
	antimagic_flags = MAGIC_RESISTANCE_MIND

	invocation = "S'C 'RA'TH!"
	invocation_type = INVOCATION_SHOUT
	spell_requirements = SPELL_CASTABLE_WITHOUT_INVOCATION

	hand_path = /obj/item/melee/touch_attack/sacrifice

/obj/item/melee/touch_attack/sacrifice
	name = "Sacrifice"
	desc = "A soft, yet fierce glow emanates from it. \
		When used on one of your brothers, grants them power at the cost of your own. \
		If that brother is dead, they will be revived and you will die, permanently."
	icon = 'monkestation/icons/obj/weapons/hand.dmi'
	icon_state = "sacrifice"
