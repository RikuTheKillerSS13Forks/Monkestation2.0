/// Maptext define for vampire HUDs.
#define FORMAT_VAMPIRE_HUD_TEXT(value, color) MAPTEXT("<div align='center' valign='middle' style='position:relative; top:0px; left:6px'><font color='[color]'>[round(value,1)]</font></div>")

/atom/movable/screen/vampire
	icon = 'monkestation/icons/vampires/actions_vampire.dmi'

/atom/movable/screen/vampire/lifeforce_counter
	name = "Life Force"
	icon_state = "blood_display"
	screen_loc = "WEST:6,CENTER+0.5:0" // 0.5 tiles up.

/atom/movable/screen/vampire/rank_counter
	name = "Vampire Rank"
	icon_state = "rank"
	screen_loc = "WEST:6,CENTER-0.5:-5" // 0.5 tiles down.

/datum/antagonist/vampire/proc/on_hud_created(datum/source)
	SIGNAL_HANDLER
	var/datum/hud/hud = owner.current.hud_used

	lifeforce_display = new /atom/movable/screen/vampire/lifeforce_counter()
	lifeforce_display.hud = hud
	hud.infodisplay += lifeforce_display

	rank_display = new /atom/movable/screen/vampire/rank_counter()
	rank_display.hud = hud
	hud.infodisplay += rank_display

	hud.show_hud(hud.hud_version)
	UnregisterSignal(owner.current, COMSIG_MOB_HUD_CREATED)

/// Updates HUD displays for lifeforce and rank.
/datum/antagonist/vampire/proc/update_hud()
	var/color
	if(life_force > 50)
		color = "#ffdddd"
	else if(life_force > 25)
		color = "#ffaaaa"

	lifeforce_display?.maptext = FORMAT_VAMPIRE_HUD_TEXT(color, life_force)

	color = BlendRGB("#ffffff", "#ffd700", vampire_rank / VAMPIRE_RANK_MAX)

	rank_display?.maptext = FORMAT_VAMPIRE_HUD_TEXT(color, vampire_rank)
