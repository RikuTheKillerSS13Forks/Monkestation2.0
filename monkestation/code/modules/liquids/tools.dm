/client/proc/spawn_liquid()
	set category = "Admin.Fun"
	set name = "Spawn Liquid"
	set desc = "Spawns a liquid of your choice in a radius around your current location."

	var/choice = stripped_input(usr, "Enter the ID of the reagent you want to add.", "Spawn Liquid: Choose Reagent")
	if (isnull(choice)) // Check if they canceled.
		return
	if (!ispath(text2path(choice)))
		choice = pick_closest_path(choice, make_types_fancy(subtypesof(/datum/reagent)))
		if (!ispath(choice))
			to_chat(usr, span_warning("A reagent with that ID doesn't exist!"))
			return

	var/volume = input(usr, "Enter the volume of liquid you want to add. More than [LIQUID_BASE_TURF_MAXIMUM_VOLUME]u may get culled.", "Spawn Liquid: Choose Volume") as num
	if (!isnum(volume) || volume <= 0)
		return

	var/range = input(usr, "Enter the range in which you want to add liquid.", "Spawn Liquid: Choose Range") as num
	if (!isnum(range) || range < 0)
		return

	for (var/turf/target_turf in range(range, mob))
		target_turf.add_liquid(choice, volume)

	message_admins("[key_name_admin(usr)] spawned liquid at [get_turf(mob)] ([choice] - [range] range - [volume] volume).")
	log_admin("[key_name(usr)] spawned liquid at [get_turf(mob)] ([choice] - [range] range - [volume] volume).")

/client/proc/remove_liquids()
	set name = "Remove Liquids"
	set category = "Admin.Fun"
	set desc = "Removes all liquids in a radius around your current location."

	var/range = input(usr, "Enter the range in which you want to remove liquids.", "Remove Liquid: Choose Range") as num
	if (!isnum(range) || range < 0)
		return

	for(var/turf/target_turf in range(range, mob))
		target_turf.remove_all_liquid()

	message_admins("[key_name_admin(usr)] removed liquids with range [range] at [get_turf(mob)]")
	log_game("[key_name(usr)] removed liquids with range [range] at [get_turf(mob)]")

/client/proc/remove_all_liquids()
	set name = "Remove All Liquids"
	set category = "Admin.Fun"
	set desc = "Removes all liquids on the map."

	for (var/datum/liquid_group/liquid_group as anything in GLOB.liquid_groups)
		qdel(liquid_group) // Yeah. You can just delete a whole group. And it runs remove_all_turfs() meaning it's blazing fast.

/client/proc/change_ocean()
	set category = "Admin.Fun"
	set name = "Change Ocean Liquid"
	set desc = "Changes the reagent of the ocean."

	/* /// LIQUID REFACTOR IN PROGRESS ///
	var/choice = tgui_input_list(usr, "Choose a reagent", "Ocean Reagent", subtypesof(/datum/reagent))
	if(!choice)
		return
	var/datum/reagent/chosen_reagent = choice
	var/rebuilt = FALSE
	for(var/turf/open/floor/plating/ocean/listed_ocean as anything in SSliquids.ocean_turfs)
		if(!rebuilt)
			listed_ocean.ocean_reagents = list()
			listed_ocean.ocean_reagents[chosen_reagent] = 10
			listed_ocean.static_overlay.mix_colors(listed_ocean.ocean_reagents)
			for(var/area/ocean/ocean_types in GLOB.initalized_ocean_areas)
				ocean_types.base_lighting_color = listed_ocean.static_overlay.color
				ocean_types.update_base_lighting()
			rebuilt = TRUE
	*/ /// LIQUID REFACTOR IN PROGRESS ///
