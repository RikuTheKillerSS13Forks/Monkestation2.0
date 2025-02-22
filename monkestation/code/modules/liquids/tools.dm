/client/proc/spawn_liquid()
	set category = "Admin.Fun"
	set name = "Spawn Liquid"
	set desc = "Spawns an amount of chosen liquid at your current location."

	var/choice = stripped_input(usr, "Enter the ID of the reagent you want to add.", "Spawn Liquid: Choose Reagent")
	if (isnull(choice)) // Check if they canceled.
		return
	if (!ispath(text2path(choice)))
		choice = pick_closest_path(choice, make_types_fancy(subtypesof(/datum/reagent)))
		if (!ispath(choice))
			to_chat(usr, span_warning("A reagent with that ID doesn't exist!"))
			return

	var/volume = input(usr, "Enter the volume of liquid you want to add. More than [LIQUID_BASE_TURF_MAXIMUM_VOLUME] is very likely to get culled.", "Spawn Liquid: Choose Volume") as num
	if (!isnum(volume) || volume <= 0)
		return

	var/range = input(usr, "Enter the range in which you want to add liquid.") as num
	if (!isnum(range) || range <= 0)
		return

	// General maximum liquid volume allowed per turf multiplied by the surface area of the square of turfs we're spawning liquid on.
	if (min(volume, LIQUID_BASE_TURF_MAXIMUM_VOLUME) * range * range > 100000)
		var/balls_to_the_walls = tgui_alert(
			user = usr,
			message = "Are you absolutely certain you want to spawn over one hundred thousand units of liquid? At least up to one million will be okay for the server.",
			title = "Spawn Liquid: Tread Carefully",
			buttons = list("Yes", "No"),
		)
		if (!balls_to_the_walls)
			to_chat(usr, span_green("You decide against flooding everything. Maybe that's for the best?"))
			return
		to_chat(usr, span_warning("Welp, that's going to be a tsunami. Not going to stop you, though."))

	for (var/turf/open/target_turf in range(range, mob))
		target_turf.add_liquid(choice, volume)

	message_admins("[ADMIN_LOOKUPFLW(usr)] spawned liquid at [get_turf(mob)] ([choice] - [range] range - [volume] volume).")
	log_admin("[key_name(usr)] spawned liquid at [get_turf(mob)] ([choice] - [range] range - [volume] volume).")

/client/proc/remove_liquid()
	set name = "Remove Liquids"
	set category = "Admin.Fun"
	set desc = "Fixes air in specified radius."

	/* /// LIQUID REFACTOR IN PROGRESS ///
	var/turf/epicenter = get_turf(mob)

	var/range = input(usr, "Enter range:", "Range selection", 2) as num

	for(var/obj/effect/abstract/liquid_turf/liquid in range(range, epicenter))
		liquid.liquid_group.remove_any(liquid, liquid.liquid_group.reagents_per_turf)
		qdel(liquid)

	message_admins("[key_name_admin(usr)] removed liquids with range [range] in [epicenter.loc.name]")
	log_game("[key_name_admin(usr)] removed liquids with range [range] in [epicenter.loc.name]")
	*/ /// LIQUID REFACTOR IN PROGRESS ///



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
