/// 1 tile up.
#define UI_LIFEFORCE_DISPLAY "WEST:6,CENTER+1:0"
/// 1 tile down.
#define UI_VAMPRANK_DISPLAY "WEST:6,CENTER-1:-5"

/// Maptext define for Bloodsucker HUDs.
#define FORMAT_BLOODSUCKER_HUD_TEXT(value, color) MAPTEXT("<div align='center' valign='middle' style='position:relative; top:0px; left:6px'><font color='[color]'>[round(value,1)]</font></div>")

/atom/movable/screen/vampire
	icon = 'monkestation/icons/vampire/actions_vampire.dmi'

/atom/movable/screen/vampire/lifeforce_counter
	name = "Life Force"
	icon_state = "blood_display"
	screen_loc = UI_LIFEFORCE_DISPLAY

/atom/movable/screen/vampire/rank_counter
	name = "Vampire Rank"
	icon_state = "rank"
	screen_loc = UI_VAMPRANK_DISPLAY
