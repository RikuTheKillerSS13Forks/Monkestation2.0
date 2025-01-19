#define FORMAT_VAMPIRE_HUD_TEXT(value, color) MAPTEXT("<div align='center' valign='middle' style='position:relative; top:0px; left:6px'><font color='[color]'>[ceil(value)]</font></div>")

#define LIFEFORCE_MEDIUM (LIFEFORCE_MAXIMUM * 0.5)
#define LIFEFORCE_LOW (LIFEFORCE_MAXIMUM * 0.25)

/atom/movable/screen/vampire
	icon = 'monkestation/icons/vampires/vampire_actions.dmi'

/atom/movable/screen/vampire/lifeforce_display
	name = "Lifeforce"
	icon_state = "blood_display"
	screen_loc = "WEST:6,CENTER+0.5:0" // 0.5 tiles up.

/atom/movable/screen/vampire/rank_display
	name = "Rank"
	icon_state = "rank"
	screen_loc = "WEST:6,CENTER-0.5:-5" // 0.5 tiles down.

/datum/antagonist/vampire
	var/atom/movable/screen/vampire/lifeforce_display/lifeforce_display = null
	var/atom/movable/screen/vampire/rank_display/rank_display = null

/datum/antagonist/vampire/proc/create_hud()
	SIGNAL_HANDLER
	var/datum/hud/hud = user.hud_used

	lifeforce_display = new
	lifeforce_display.hud = hud
	hud.infodisplay += lifeforce_display

	rank_display = new
	rank_display.hud = hud
	hud.infodisplay += rank_display

	hud.show_hud(hud.hud_version)
	update_hud()

	UnregisterSignal(user, COMSIG_MOB_HUD_CREATED)

/datum/antagonist/vampire/proc/delete_hud()
	if (!user.hud_used)
		return

	user.hud_used.infodisplay -= lifeforce_display
	user.hud_used.infodisplay -= rank_display

	QDEL_NULL(lifeforce_display)
	QDEL_NULL(rank_display)

/// Updates HUD displays for lifeforce and rank.
/datum/antagonist/vampire/proc/update_hud()
	var/color

	switch (current_lifeforce)
		if (LIFEFORCE_MEDIUM to INFINITY)
			color = "#ffdddd"
		if (LIFEFORCE_LOW to LIFEFORCE_MEDIUM)
			color = "#ffaaaa"
		if (-INFINITY to LIFEFORCE_LOW)
			color = "#ff7070"

	lifeforce_display?.maptext = FORMAT_VAMPIRE_HUD_TEXT(current_lifeforce, color)

	color = BlendRGB("#ffffff", "#c941ff", current_rank / 8) // Fix this to use the clan-specific max rank once clans are in.

	rank_display?.maptext = FORMAT_VAMPIRE_HUD_TEXT(current_rank, color)

#undef FORMAT_VAMPIRE_HUD_TEXT
#undef LIFEFORCE_MEDIUM
#undef LIFEFORCE_LOW
