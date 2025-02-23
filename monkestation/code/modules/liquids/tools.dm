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

	var/volume = input(usr, "Enter the volume of liquid you want to add.", "Spawn Liquid: Choose Volume") as num
	if (!isnum(volume) || volume <= 0)
		return

	var/range = input(usr, "Enter the range in which you want to add liquid.", "Spawn Liquid: Choose Range") as num
	if (!isnum(range) || range < 0)
		return

	// Volume per turf multiplied by the surface area of the square of turfs we're spawning liquid on.
	if (volume * range * range > 100000)
		var/balls_to_the_walls = tgui_alert(
			user = usr,
			message = "Are you absolutely certain you want to spawn roughly over one hundred thousand units of liquid? The server will live, but the players may not.",
			title = "Spawn Liquid: Tread Carefully",
			buttons = list("Yes", "No"),
		)
		if (!balls_to_the_walls)
			to_chat(usr, span_green("You decide against flooding everything. Maybe that's for the best?"))
			return
		to_chat(usr, span_warning("Welp, that's going to be a tsunami. Not going to stop you, though."))

	for (var/turf/open/target_turf in range(range, mob))
		target_turf.add_liquid(choice, volume)

	message_admins("[key_name_admin(usr)] spawned liquid at [get_turf(mob)] ([choice] - [range] range - [volume] volume).")
	log_admin("[key_name(usr)] spawned liquid at [get_turf(mob)] ([choice] - [range] range - [volume] volume).")

/client/proc/remove_liquid()
	set name = "Remove Liquids"
	set category = "Admin.Fun"
	set desc = "Removes all liquids in a radius around your current location."

	var/range = input(usr, "Enter the range in which you want to remove liquids.", "Remove Liquid: Choose Range") as num
	if (!isnum(range) || range < 0)
		return

	for(var/turf/open/target_turf in range(range, mob))
		if(target_turf.liquid_group)
			target_turf.liquid_group.reagents.remove_all(target_turf.liquid_group.maximum_volume_per_turf)
			target_turf.liquid_group.remove_turf(target_turf)

	message_admins("[key_name_admin(usr)] removed liquids with range [range] at [get_turf(mob)]")
	log_game("[key_name(usr)] removed liquids with range [range] at [get_turf(mob)]")

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
