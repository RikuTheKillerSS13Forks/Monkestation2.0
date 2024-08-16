/datum/action/cooldown/vampire/masquerade
	name = "Masquerade"
	desc = "Hide your true nature from the prying eyes of the mortals. Drains lifeforce while active."
	button_icon_state = "power_human"
	cooldown_time = 1 SECOND
	toggleable = TRUE // constant_life_cost is handled in set_masquerade

/datum/action/cooldown/vampire/masquerade/on_toggle_on()
	vampire.set_masquerade(TRUE)

	owner.visible_message(
		message = span_danger("[owner]'s appearance suddenly morphs to that of a normal person. Was what you saw earlier just an illusion?"),
		self_message = span_notice("You hide your true nature, skin turning vibrant and eyes no longer glowing. You can easily pass for a mortal now.")
	)

	build_all_button_icons()

/datum/action/cooldown/vampire/masquerade/on_toggle_off()
	vampire.set_masquerade(FALSE)

	owner.visible_message(
		message = span_danger("[owner]'s skin suddenly turns a pale grey, [owner.p_their()] eyes begin to glow and a set of ferocious fangs extends from [owner.p_their()] mouth!"),
		self_message = span_notice("You return to your icy pallor, silently hoping to never have to fool another mortal again. Alas, such is the life of our kin.")
	)

	build_all_button_icons()

/datum/action/cooldown/vampire/masquerade/is_active()
	return vampire.masquerade_enabled
