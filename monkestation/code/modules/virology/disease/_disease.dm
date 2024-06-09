GLOBAL_LIST_INIT(infected_contact_mobs, list())
GLOBAL_LIST_INIT(virusDB, list())

/datum/disease
	//the disease's antigens, that the body's immune_system will read to produce corresponding antibodies. Without antigens, a disease cannot be cured.
	var/list/antigen = list()
	//alters a pathogen's propensity to mutate. Set to FALSE to forbid a pathogen from ever mutating.
	var/mutation_modifier = TRUE
	///split category used for predefined diseases atm
	var/category = DISEASE_NORMAL

	//logging
	var/log = ""
	var/origin = "Unknown"
	var/logged_virusfood = FALSE
	var/fever_warning = FALSE

	//cosmetic
	var/color
	var/pattern = 1
	var/pattern_color

	//When an opportunity for the disease to spread_flags to a mob arrives, runs this percentage through prob()
	//Ignored if infected materials are ingested (injected with infected blood, eating infected meat)
	var/infectionchance = 20
	var/infectionchance_base = 20

	var/uniqueID = 0// 0000 to 9999, set when the pathogen gets initially created
	var/subID = 0// 000 to 9999, set if the pathogen underwent effect or antigen mutation
	var/childID = 0// 01 to 99, incremented as the pathogen gets analyzed after a mutation
	//bitflag showing which transmission types are allowed for this disease
	var/allowed_transmission = DISEASE_SPREAD_BLOOD | DISEASE_SPREAD_CONTACT_SKIN | DISEASE_SPREAD_CONTACT_FLUIDS | DISEASE_SPREAD_AIRBORNE

	/// How much the disease has progressed. This is a value from 0 to 1.
	var/progress = 0

	/// How much the disease progress changes by default every second.
	var/progress_rate = 0.01

	/// List of multipliers for progress rate.
	var/list/progress_rate_multipliers = list()

/proc/filter_disease_by_spread(list/diseases, required = NONE)
	if(!length(diseases))
		return list()

	var/list/viable = list()
	for(var/datum/disease/advanced/disease as anything in diseases)
		if(!(disease.spread_flags & required))
			continue
		viable += disease
	return viable

/// Returns the full ID of this disease.
/// Does string manipulation so cache it please.
/datum/disease/advanced/proc/get_id()
	return "[uniqueID]-[subID]" // this was originally manually written out like 80 times wtf

/// Randomizes the appearance of the disease.
/datum/disease/advanced/proc/randomize_appearance()
	var/list/random_hexes = list("8","9","a","b","c","d","e")
	color = random_string(6, random_hexes)
	pattern = rand(1, 6)
	pattern_color = random_string(6, random_hexes)

/datum/disease/advanced/proc/update_global_log()
	if (get_id() in GLOB.inspectable_diseases)
		return
	GLOB.inspectable_diseases[get_id()] = Copy()

/datum/disease/advanced/proc/clean_global_log()
	var/ID = get_id()
	if (ID in GLOB.virusDB)
		return

	for (var/mob/living/L in GLOB.mob_list)
		if(!length(L.diseases))
			continue
		for(var/datum/disease/advanced/D as anything in L.diseases)
			if (ID == D.get_id())
				return

	for (var/obj/item/I in GLOB.infected_items)
		for(var/datum/disease/advanced/D as anything in I.viruses)
			if (ID == D.get_id())
				return

	var/dishes = 0
	for (var/obj/item/weapon/virusdish/dish in GLOB.virusdishes)
		if (dish.contained_virus)
			if (ID == dish.contained_virus.get_id())
				dishes++
				if (dishes > 1)//counting the dish we're in currently
					return
	//If a pathogen that isn't in the database mutates, we check whether it infected anything, and remove it from the disease list if it didn't
	//so we don't clog up the Diseases Panel with irrelevant mutations
	GLOB.inspectable_diseases -= ID

/datum/disease/advanced/proc/AddToGoggleView(mob/living/infectedMob)
	if (spread_flags & DISEASE_SPREAD_CONTACT_SKIN)
		GLOB.infected_contact_mobs |= infectedMob
		if (!infectedMob.pathogen)
			infectedMob.pathogen = image('monkestation/code/modules/virology/icons/effects.dmi',infectedMob,"pathogen_contact")
			infectedMob.pathogen.plane = HUD_PLANE
			infectedMob.pathogen.appearance_flags = RESET_COLOR|RESET_ALPHA
		for (var/mob/living/L in GLOB.science_goggles_wearers)
			if (L.client)
				L.client.images |= infectedMob.pathogen
		return

	if (spread_flags & DISEASE_SPREAD_BLOOD)
		GLOB.infected_contact_mobs |= infectedMob
		if (!infectedMob.pathogen)
			infectedMob.pathogen = image('monkestation/code/modules/virology/icons/effects.dmi',infectedMob,"pathogen_blood")
			infectedMob.pathogen.plane = HUD_PLANE
			infectedMob.pathogen.appearance_flags = RESET_COLOR|RESET_ALPHA
		for (var/mob/living/L in GLOB.science_goggles_wearers)
			if (L.client)
				L.client.images |= infectedMob.pathogen
		return

/datum/disease/advanced/proc/makerandom(var/list/str = list(), var/list/rob = list(), var/list/anti = list(), var/list/bad = list(), var/atom/source = null)
	//ID
	uniqueID = rand(0,9999)
	subID = rand(0,9999)

	//base stats
	strength = rand(str[1],str[2])
	robustness = rand(rob[1],rob[2])
	roll_antigen(anti)

	//effects
	for(var/i = 1; i <= max_stages; i++)
		var/selected_badness = pick(
			bad[EFFECT_DANGER_HELPFUL];EFFECT_DANGER_HELPFUL,
			bad[EFFECT_DANGER_FLAVOR];EFFECT_DANGER_FLAVOR,
			bad[EFFECT_DANGER_ANNOYING];EFFECT_DANGER_ANNOYING,
			bad[EFFECT_DANGER_HINDRANCE];EFFECT_DANGER_HINDRANCE,
			bad[EFFECT_DANGER_HARMFUL];EFFECT_DANGER_HARMFUL,
			bad[EFFECT_DANGER_DEADLY];EFFECT_DANGER_DEADLY,
			)
		var/datum/symptom/e = new_effect(text2num(selected_badness), i)
		symptoms += e
		log += "<br />[ROUND_TIME()] Added effect [e.name] ([e.chance]% Occurence)."

	//slightly randomized infection chance
	var/variance = initial(infectionchance)/10
	infectionchance = rand(initial(infectionchance)-variance,initial(infectionchance)+variance)
	infectionchance_base = infectionchance

	//cosmetic petri dish stuff - if set beforehand, will not be randomized
	if (!color)
		randomize_appearance()

	//spreading vectors - if set beforehand, will not be randomized
	if (!spread_flags)
		randomize_spread()

	//logging
	log += "<br />[ROUND_TIME()] Created and Randomized<br>"

	//admin panel
	if (origin == "Unknown")
		if (istype(source,/obj/item/weapon/virusdish))
			if (isturf(source.loc))
				var/turf/T = source.loc
				if (istype(T.loc,/area/centcom))
					origin = "Centcom"
				else if (istype(T.loc,/area/station/medical/virology))
					origin = "Pathology"
	update_global_log()

/datum/disease/advanced/proc/new_effect(badness = 2, stage = 0)
	var/list/datum/symptom/list = list()
	var/list/to_choose = subtypesof(/datum/symptom)
	for(var/e in to_choose)
		var/datum/symptom/f = new e
		if(!f.restricted && f.stage == stage && text2num(f.badness) == badness)
			list += f
	if (list.len <= 0)
		return new_random_effect(badness+1,badness-1,stage)
	else
		var/datum/symptom/e = pick(list)
		e.chance = rand(1, e.max_chance)
		return e

/datum/disease/advanced/proc/new_random_effect(var/max_badness = 5, var/min_badness = 0, var/stage = 0, var/old_effect)
	var/list/datum/symptom/list = list()
	var/list/to_choose = subtypesof(/datum/symptom)
	if(old_effect) //So it doesn't just evolve right back into the previous virus type
		to_choose.Remove(old_effect)
	for(var/e in to_choose)
		var/datum/symptom/f = new e
		if(!f.restricted && f.stage == stage && text2num(f.badness) <= max_badness && text2num(f.badness) >= min_badness)
			list += f
	if (list.len <= 0)
		return new_random_effect(min(max_badness+1,5),max(0,min_badness-1),stage)
	else
		var/datum/symptom/e = pick(list)
		e.chance = rand(1, e.max_chance)
		return e

/datum/disease/advanced/proc/randomize_spread()
	spread_flags = DISEASE_SPREAD_BLOOD	//without blood spread_flags, the disease cannot be extracted or cured, we don't want that for regular diseases
	if (prob(5))			//5% chance of spreading through both contact and the air.
		spread_flags |= DISEASE_SPREAD_CONTACT_SKIN
		spread_flags |= DISEASE_SPREAD_AIRBORNE
	else if (prob(40))		//38% chance of spreading through the air only.
		spread_flags |= DISEASE_SPREAD_AIRBORNE
	else if (prob(60))		//34,2% chance of spreading through contact only.
		spread_flags |= DISEASE_SPREAD_CONTACT_SKIN
							//22,8% chance of staying in blood

/datum/disease/advanced/proc/minormutate(index)
	var/datum/symptom/e = get_effect(index)
	e.minormutate()
	infectionchance = min(50,infectionchance + rand(0,10))
	log += "<br />[ROUND_TIME()] Infection chance now [infectionchance]%"

/datum/disease/advanced/proc/minorstrength(index)
	var/datum/symptom/e = get_effect(index)
	e.multiplier_tweak(0.1)

/datum/disease/advanced/proc/minorweak(index)
	var/datum/symptom/e = get_effect(index)
	e.multiplier_tweak(-0.1)

/datum/disease/advanced/proc/get_effect(index)
	if(!index)
		return pick(symptoms)
	return symptoms[clamp(index,0,symptoms.len)]

/datum/disease/advanced/proc/antigenmutate()
	clean_global_log()
	subID = rand(0,9999)
	var/old_dat = get_antigen_string()
	roll_antigen()
	log += "<br />[ROUND_TIME()] Mutated antigen [old_dat] into [get_antigen_string()]."
	update_global_log()

/datum/disease/advanced/proc/get_antigen_string()
	var/dat = ""
	for (var/A in antigen)
		dat += "[A]"
	return dat

/datum/disease/advanced/proc/roll_antigen(list/factors = list())
	if (factors.len <= 0)
		antigen = list(pick(GLOB.all_antigens))
		antigen |= pick(GLOB.all_antigens)
	else
		var/selected_first_antigen = pick(
			factors[ANTIGEN_BLOOD];ANTIGEN_BLOOD,
			factors[ANTIGEN_COMMON];ANTIGEN_COMMON,
			factors[ANTIGEN_RARE];ANTIGEN_RARE,
			factors[ANTIGEN_ALIEN];ANTIGEN_ALIEN,
			)

		antigen = list(pick(antigen_family(selected_first_antigen)))

		var/selected_second_antigen = pick(
			factors[ANTIGEN_BLOOD];ANTIGEN_BLOOD,
			factors[ANTIGEN_COMMON];ANTIGEN_COMMON,
			factors[ANTIGEN_RARE];ANTIGEN_RARE,
			factors[ANTIGEN_ALIEN];ANTIGEN_ALIEN,
			)

		antigen |= pick(antigen_family(selected_second_antigen))

/datum/disease/advanced/proc/adjust_progress(amount)
	set_progress(progress + amount)

/datum/disease/advanced/proc/set_progress(amount)
	progress = clamp(amount, 0, 1)

/datum/disease/advanced/proc/get_base_potency()
	return max(0, progress - length(symptoms) * 0.1)

/datum/disease/advanced/proc/activate(mob/living/carbon/host, starved = FALSE, seconds_per_tick)
	if((host.stat == DEAD) && !process_dead)
		return

	if(!(infectable_biotypes & host.mob_biotypes))
		return

	if(!host.immune_system.CanInfect(src))
		cure(host)
		return

	var/final_progress_rate = progress_rate

	for(var/multiplier as anything in progress_rate_multipliers)
		final_progress_rate *= multiplier

	adjust_progress(final_progress_rate)

	for(var/datum/symptom/symptom as anything in symptoms)
		symptom.try_run_effect(host, src, seconds_per_tick)

/proc/virus_copylist(list/list)
	if(!length(list))
		return list()
	var/list/L = list()
	for(var/datum/disease/advanced/D as anything in list)
		L += D.Copy()
	return L

/datum/disease/advanced/cure(mob/living/carbon/mob, condition=0)
	/* TODO
	switch (condition)
		if (0)
			log_debug("[form] [uniqueID]-[subID] in [key_name(mob)] has been cured, and is being removed from their body.")
		if (1)
			log_debug("[form] [uniqueID]-[subID] in [key_name(mob)] has died from extreme temperature inside their host, and is being removed from their body.")
		if (2)
			log_debug("[form] [uniqueID]-[subID] in [key_name(mob)] has been wiped out by an immunity overload.")
	*/
	for(var/datum/symptom/e in symptoms)
		e.disable_effect(mob, src)
	mob.diseases -= src
	logger.Log(LOG_CATEGORY_VIRUS, "[mob.name] was cured of virus [real_name()] at [loc_name(mob.loc)]", list("disease_data" = admin_details(), "location" = loc_name(mob.loc)))
	//--Plague Stuff--
	/*
	var/datum/faction/plague_mice/plague = find_active_faction_by_type(/datum/faction/plague_mice)
	if (plague && (get_id() == plague.diseaseID))
		plague.update_hud_icons()
	*/
	//----------------
	var/list/V = filter_disease_by_spread(mob.diseases, required = DISEASE_SPREAD_CONTACT_SKIN)
	if (V && V.len <= 0)
		GLOB.infected_contact_mobs -= mob
		if (mob.pathogen)
			for (var/mob/living/L in GLOB.science_goggles_wearers)
				if (L.client)
					L.client.images -= mob.pathogen


/datum/disease/advanced/proc/GetImmuneData(mob/living/mob)
	var/lowest_stage = stage
	var/highest_concentration = 0

	if (mob.immune_system)
		var/immune_system = mob.immune_system.GetImmunity()
		var/list/antibodies = immune_system[2]
		var/subdivision = (strength - ((robustness * strength) / 100)) / max_stages
		//for each antigen, we measure the corresponding antibody concentration in the carrier's immune system
		//the less robust the pathogen, the more likely that further stages' effects won't activate at a given concentration
		for (var/A in antigen)
			var/concentration = antibodies[A]
			highest_concentration = max(highest_concentration,concentration)
			var/i = lowest_stage
			while (i > 0)
				if (concentration > (strength - i * subdivision))
					lowest_stage = i-1
				i--

	return list(lowest_stage,highest_concentration)

/datum/disease/advanced/proc/name(override=FALSE)
	.= "[form] #["[uniqueID]"][childID ? "-["[childID]"]" : ""]"

	if (!override && (get_id() in GLOB.virusDB))
		var/datum/data/record/V = GLOB.virusDB[get_id()]
		.= V.fields["name"]

/datum/disease/advanced/proc/real_name()
	.= "[form] #["[uniqueID]"]-["[subID]"]"
	if (get_id() in GLOB.virusDB)
		var/datum/data/record/v = GLOB.virusDB[get_id()]
		var/nickname = v.fields["nickname"] ? " \"[v.fields["nickname"]]\"" : ""
		. += nickname

/datum/disease/advanced/proc/get_subdivisions_string()
	var/subdivision = (strength - ((robustness * strength) / 100)) / max_stages
	var/dat = "("
	for (var/i = 1 to max_stages)
		dat += "[round(strength - i * subdivision)]"
		if (i < max_stages)
			dat += ", "
	dat += ")"
	return dat

/datum/disease/advanced/proc/get_info()
	var/r = "GNAv3 [name()]"
	r += "<BR>Strength / Robustness : <b>[strength]% / [robustness]%</b> - [get_subdivisions_string()]"
	r += "<BR>Infectability : <b>[infectionchance]%</b>"
	r += "<BR>Spread forms : <b>[get_spread_string()]</b>"
	r += "<BR>Progress Speed : <b>[stageprob]%</b>"
	r += "<dl>"
	for(var/datum/symptom/e in symptoms)
		r += "<dt> &#x25CF; <b>Stage [e.stage] - [e.name]</b> (Danger: [e.badness]). Strength: <b>[e.multiplier]</b>. Occurrence: <b>[e.chance]%</b>.</dt>"
		r += "<dd>[e.desc]</dd>"
	r += "</dl>"
	r += "<BR>Antigen pattern: [get_antigen_string()]"
	r += "<BR><i>last analyzed at: [worldtime2text()]</i>"
	return r

/datum/disease/advanced/proc/get_spread_string()
	var/dat = ""
	var/check = 0
	if (spread_flags & DISEASE_SPREAD_BLOOD)
		dat += "Blood"
		check += DISEASE_SPREAD_BLOOD
		if (spread_flags > check)
			dat += ", "
	if (spread_flags & DISEASE_SPREAD_CONTACT_SKIN)
		dat += "Skin Contact"
		check += DISEASE_SPREAD_CONTACT_SKIN
		if (spread_flags > check)
			dat += ", "
	if (spread_flags & DISEASE_SPREAD_AIRBORNE)
		dat += "Airborne"
		check += DISEASE_SPREAD_AIRBORNE
		if (spread_flags > check)
			dat += ", "
	if (spread_flags & DISEASE_SPREAD_CONTACT_FLUIDS)
		dat += "Fluid Contact"
		check += DISEASE_SPREAD_CONTACT_FLUIDS
		if(spread_flags > check)
			dat += ", "
	if (spread_flags & DISEASE_SPREAD_NON_CONTAGIOUS)
		dat += "Non Contagious"
		check += DISEASE_SPREAD_NON_CONTAGIOUS
		if(spread_flags > check)
			dat += ", "
	if (spread_flags & DISEASE_SPREAD_SPECIAL)
		dat += "UNKNOWN SPREAD"
		check += DISEASE_SPREAD_SPECIAL
		if(spread_flags > check)
			dat += ", "
	/*
	if (spread_flags & SPREAD_COLONY)
		dat += "Colonizing"
		check += SPREAD_COLONY
		if (spread_flags > check)
			dat += ", "
	if (spread_flags & SPREAD_MEMETIC)
		dat += "Memetic"
		check += SPREAD_MEMETIC
		if (spread_flags > check)
			dat += ", "
	*/
	return dat

/datum/disease/advanced/proc/addToDB()
	if (get_id() in GLOB.virusDB)
		return 0
	childID = 0
	for (var/virus_file in GLOB.virusDB)
		var/datum/data/record/v = GLOB.virusDB[virus_file]
		if (v.fields["id"] == uniqueID)
			childID++
	var/datum/data/record/v = new()
	v.fields["id"] = uniqueID
	v.fields["sub"] = subID
	v.fields["child"] = childID
	v.fields["form"] = form
	v.fields["name"] = name()
	v.fields["nickname"] = ""
	v.fields["description"] = get_info()
	v.fields["description_hidden"] = get_info(TRUE)
	v.fields["custom_desc"] = "No comments yet."
	v.fields["antigen"] = get_antigen_string()
	v.fields["spread_flags_type"] = get_spread_string()
	v.fields["danger"] = "Undetermined"
	GLOB.virusDB[get_id()] = v
	return 1

/datum/disease/advanced/virus
	form = "Virus"
	max_stages = 4
	infectionchance = 20
	infectionchance_base = 20
	stageprob = 10
	stage_variance = -1
	can_kill = list("Bacteria")

/datum/disease/advanced/bacteria//faster spread_flags and progression, but only 3 stages max, and reset to stage 1 on every spread_flags
	form = "Bacteria"
	max_stages = 3
	infectionchance = 30
	infectionchance_base = 30
	stageprob = 30
	stage_variance = -4
	can_kill = list("Parasite")

/datum/disease/advanced/parasite//slower spread_flags. stage preserved on spread_flags
	form = "Parasite"
	infectionchance = 15
	infectionchance_base = 15
	stageprob = 10
	stage_variance = 0
	can_kill = list("Virus")

/datum/disease/advanced/prion//very fast progression, but very slow spread_flags and resets to stage 1.
	form = "Prion"
	infectionchance = 3
	infectionchance_base = 3
	stageprob = 80
	stage_variance = -10
	can_kill = list()


/datum/disease/advanced/vv_get_dropdown()
	. = ..()
	VV_DROPDOWN_OPTION("","------")
	VV_DROPDOWN_OPTION(VV_HK_VIEW_DISEASE_DATA, "View Disease Data")

/datum/disease/advanced/vv_do_topic(list/href_list)
	. = ..()
	if(href_list[VV_HK_VIEW_DISEASE_DATA])
		create_disease_info_pane(usr)

/datum/disease/advanced/proc/create_disease_info_pane(mob/user)
	var/datum/browser/popup = new(user, "\ref[src]", "GNAv3 [form] #[get_id()]", 600, 500, src)
	var/content = get_info()
	content += "<BR><b>LOGS</b></BR>"
	content += log
	popup.set_content(content)
	popup.open()

/*
/client/proc/view_disease_data()
	set category = "Admin.Logging"
	set name = "View Disease List"
	set desc = "views disease list and on selection opens the data"

	if(!holder)
		return
	var/list/diseases = list()
	for(var/datum/disease/advanced/disease as anything in GLOB.inspectable_diseases)
		if(!disease || !istype(disease))
			continue
		if(disease.affected_mob)
			diseases["GNAv3 [disease.form] #[disease.uniqueID]-[disease.subID]-[disease.childID] [disease.affected_mob]"] = disease
		else
			diseases["GNAv3 [disease.form] #[disease.uniqueID]-[disease.subID]-[disease.childID]"] = disease
	var/disease = input("Choose a disease", "Diseases") as null|anything in sort_list(diseases, /proc/cmp_typepaths_asc)
	if(!disease)
		return
	var/datum/disease/advanced/actual_disease = diseases[disease]
	if(!actual_disease)
		return
	actual_disease.create_disease_info_pane(usr)
*/

/proc/make_custom_virus(client/C, mob/living/infectedMob)
	if(!istype(C) || !C.holder)
		return 0

	var/datum/disease/advanced/D = new /datum/disease/advanced()
	D.origin = "Badmin"

	var/list/known_forms = list()
	for (var/disease_type in subtypesof(/datum/disease/advanced))
		var/datum/disease/advanced/d_type = disease_type
		known_forms[initial(d_type.form)] = d_type

	known_forms += "custom"

	/*
	if (islist(GLOB.inspectable_diseases) && GLOB.inspectable_diseases.len > 0)
		known_forms += "infect with an already existing pathogen"
	*/

	var/chosen_form = input(C, "Choose a form for your pathogen", "Choose a form") as null | anything in known_forms
	if (!chosen_form)
		qdel(D)
		return

	if (chosen_form == "infect with an already existing pathogen")
		var/list/existing_pathogen = list()
		for(var/datum/disease/advanced/dis as anything in GLOB.inspectable_diseases)
			existing_pathogen += dis
		var/chosen_pathogen = input(C, "Choose a pathogen", "Choose a pathogen") as null | anything in existing_pathogen
		if (!chosen_pathogen)
			qdel(D)
			return
		var/datum/disease/advanced/dis = chosen_pathogen
		D = dis.Copy()
		D.origin = "[D.origin] (Badmin)"
	else
		if (chosen_form == "custom")
			var/form_name = copytext(sanitize(input(C, "Give your custom form a name", "Name your form", "Pathogen")  as null | text),1,MAX_NAME_LEN)
			if (!form_name)
				qdel(D)
				return
			D.form = form_name
			D.max_stages = input(C, "How many stages will your pathogen have?", "Custom Pathogen", D.max_stages) as num
			D.max_stages = clamp(D.max_stages,1,99)
			D.infectionchance = input(C, "What will be your pathogen's infection chance?", "Custom Pathogen", D.infectionchance) as num
			D.infectionchance = clamp(D.infectionchance,0,100)
			D.infectionchance_base = D.infectionchance
			D.stageprob = input(C, "What will be your pathogen's progression speed?", "Custom Pathogen", D.stageprob) as num
			D.stageprob = clamp(D.stageprob,0,100)
			D.stage_variance = input(C, "What will be your pathogen's stage variance?", "Custom Pathogen", D.stage_variance) as num
			D.stageprob = clamp(D.stageprob,-1*D.max_stages,0)
			//D.can_kill = something something a while loop but probably not worth the effort. If you need it for your bus code it yourself.
		else
			var/d_type = known_forms[chosen_form]
			var/datum/disease/advanced/d_inst = new d_type
			D.form = chosen_form
			D.max_stages = d_inst.max_stages
			D.infectionchance = d_inst.infectionchance
			D.stageprob = d_inst.stageprob
			D.stage_variance = d_inst.stage_variance
			D.can_kill = d_inst.can_kill.Copy()
			qdel(d_inst)

		D.strength = input(C, "What will be your pathogen's strength? (1-50 is trivial to cure. 50-100 requires a bit more effort)", "Pathogen Strength", D.infectionchance) as num
		D.strength = clamp(D.strength,0,100)

		D.robustness = input(C, "What will be your pathogen's robustness? (1-100) Lower values mean that infected can carry the pathogen without getting affected by its symptoms.", "Pathogen Robustness", D.infectionchance) as num
		D.robustness = clamp(D.strength,0,100)

		D.uniqueID = clamp(input(C, "You can specify the 4 number ID for your Pathogen, or just use this randomly generated one.", "Pick a unique ID", rand(0,9999)) as num, 0, 9999)

		D.subID = rand(0,9999)
		D.childID = 0

		for(var/i = 1; i <= D.max_stages; i++)  // run through this loop until everything is set
			var/datum/symptom/symptom = input(C, "Choose a symptom for your disease's stage [i] (out of [D.max_stages])", "Choose a Symptom") as null | anything in (subtypesof(/datum/symptom))
			if (!symptom)
				return 0

			var/datum/symptom/e = new symptom(D)
			e.stage = i
			e.chance = input(C, "Choose the default chance for this effect to activate", "Effect", e.chance) as null | num
			e.chance = clamp(e.chance,0,100)
			e.max_chance = input(C, "Choose the maximum chance for this effect to activate", "Effect", e.max_chance) as null | num
			e.max_chance = clamp(e.max_chance,0,100)
			e.multiplier = input(C, "Choose the default strength for this effect", "Effect", e.multiplier) as null | num
			e.multiplier = clamp(e.multiplier,0,100)
			e.max_multiplier = input(C, "Choose the maximum strength for this effect", "Effect", e.max_multiplier) as null | num
			e.max_multiplier = clamp(e.max_multiplier,0,100)

			D.log += "Added [e.name] at [e.chance]% chance and [e.multiplier] strength<br>"
			D.symptoms += e

		if (alert("Do you want to specify which antigen are selected?","Choose your Antigen","Yes","No") == "Yes")
			D.antigen = list(input(C, "Choose your first antigen", "Choose your Antigen") as null | anything in GLOB.all_antigens)
			if (!D.antigen)
				D.antigen = list(input(C, "Choose your second antigen", "Choose your Antigen") as null | anything in GLOB.all_antigens)
			else
				D.antigen |= input(C, "Choose your second antigen", "Choose your Antigen") as null | anything in GLOB.all_antigens
			if (!D.antigen)
				if (alert("Beware, your disease having no antigen means that it's incurable. We can still roll some random antigen for you. Are you sure you want your pathogen to have no antigen anyway?","Choose your Antigen","Yes","No") == "No")
					D.roll_antigen()
				else
					D.antigen = list()
		else
			D.roll_antigen()

		randomize_appearance()
		if (alert("Do you want to specify the appearance of your pathogen in a petri dish?","Choose your appearance","Yes","No") == "Yes")
			D.color = tgui_color_picker(C, "Choose the color of the dish", "Cosmetic")
			D.pattern = input(C, "Choose the shape of the pattern inside the dish (1 to 6)", "Cosmetic",rand(1,6)) as num
			D.pattern = clamp(D.pattern,1,6)
			D.pattern_color = tgui_color_picker(C, "Choose the color of the pattern", "Cosmetic")

		D.spread_flags = 0
		if (alert("Can this virus spread_flags into blood? (warning! if choosing No, this virus will be impossible to sample and analyse!)","Spreading Vectors","Yes","No") == "Yes")
			D.spread_flags |= DISEASE_SPREAD_BLOOD
		if(D.allowed_transmission & DISEASE_SPREAD_CONTACT_SKIN)
			if (alert("Can this virus spread_flags by contact, and on items?","Spreading Vectors","Yes","No") == "Yes")
				D.spread_flags |= DISEASE_SPREAD_CONTACT_SKIN
		if(D.allowed_transmission & DISEASE_SPREAD_AIRBORNE)
			if (alert("Can this virus spread_flags through the air?","Spreading Vectors","Yes","No") == "Yes")
				D.spread_flags |= DISEASE_SPREAD_AIRBORNE
		/*
		if(D.allowed_transmission & SPREAD_COLONY)
			if (alert("Does this fungus prefer suits? Exclusive with contact/air.","Spreading Vectors","Yes","No") == "Yes")
				D.spread_flags |= SPREAD_COLONY
				D.spread_flags &= ~(SPREAD_BLOOD|SPREAD_AIRBORNE)
		if(D.allowed_transmission & SPREAD_MEMETIC)
			if (alert("Can this virus spread_flags through words?","Spreading Vectors","Yes","No") == "Yes")
				D.spread_flags |= SPREAD_MEMETIC
		*/
		GLOB.inspectable_diseases -= "[D.get_id()]"//little odds of this happening thanks to subID but who knows
		D.update_global_log()

		if (alert("Lastly, do you want this pathogen to be added to the station's Database? (allows medical HUDs to locate infected mobs, among other things)","Pathogen Database","Yes","No") == "Yes")
			D.addToDB()

	if (istype(infectedMob))
		D.log += "<br />[ROUND_TIME()] Infected [key_name(infectedMob)]"
		if(!length(infectedMob.diseases))
			infectedMob.diseases = list()
		infectedMob.diseases += D
		var/nickname = ""
		if ("[D.get_id()]" in GLOB.virusDB)
			var/datum/data/record/v = GLOB.virusDB["[D.get_id()]"]
			nickname = v.fields["nickname"] ? " \"[v.fields["nickname"]]\"" : ""
		log_admin("[infectedMob] was infected with [D.form] #[D.get_id()][nickname] by [C.ckey]")
		message_admins("[infectedMob] was infected with  [D.form] #["[D.uniqueID]"]-["[D.subID]"][nickname] by [C.ckey]")
		D.AddToGoggleView(infectedMob)
	else
		var/obj/item/weapon/virusdish/dish = new(C.mob.loc)
		dish.contained_virus = D
		dish.growth = rand(5, 50)
		dish.name = "growth dish (Unknown [D.form])"
		if ("[D.get_id()]" in GLOB.virusDB)
			dish.name = "growth dish ([D.name(TRUE)])"
		dish.update_icon()

	return 1

/mob/var/disease_view = FALSE
/client/proc/disease_view()
	set category = "Admin.Debug"
	set name = "Disease View"
	set desc = "See viro Overlay"

	if(!holder)
		return
	if(!mob)
		return
	if(mob.disease_view)
		mob.stopvirusView()
	else
		mob.virusView()
	mob.disease_view = !mob.disease_view

/client/proc/diseases_panel()
	set category = "Admin.Logging"
	set name = "Disease Panel"
	set desc = "See diseases and disease information"

	if(!holder)
		return
	holder.diseases_panel()

/datum/admins/var/viewingID

/datum/admins/proc/diseases_panel()
	if (!GLOB.inspectable_diseases || !length(GLOB.inspectable_diseases))
		alert("There are no pathogen in the round currently!")
		return
	var/list/logs = list()
	var/dat = {"<html>
		<head>
		<style>
		table,h2 {
		font-family: Arial, Helvetica, sans-serif;
		border-collapse: collapse;
		}
		td, th {
		border: 1px solid #dddddd;
		padding: 8px;
		}
		tr:nth-child(even) {
		background-color: #dddddd;
		}
		</style>
		</head>
		<body>
		<h2 style="text-align:center">Disease Panel</h2>
		<table>
		<tr>
		<th style="width:2%">Disease ID</th>
		<th style="width:1%">Origin</th>
		<th style="width:1%">in Database?</th>
		<th style="width:1%">Infected People</th>
		<th style="width:1%">Infected Items</th>
		<th style="width:1%">in Growth Dishes</th>
		</tr>
		"}

	for (var/ID in GLOB.inspectable_diseases)
		var/infctd_mobs = 0
		var/infctd_mobs_dead = 0
		var/infctd_items = 0
		var/dishes = 0
		for (var/mob/living/L in GLOB.mob_list)
			for(var/datum/disease/advanced/D as anything in L.diseases)
				if (ID == "[D.get_id()]")
					infctd_mobs++
					if (L.stat == DEAD)
						infctd_mobs_dead++
					if(!length(logs["[ID]"]))
						logs["[ID]"]= list()
					logs["[ID]"] += "[L]"
					logs["[ID]"]["[L]"] = D.log

		for (var/obj/item/I in GLOB.infected_items)
			for(var/datum/disease/advanced/D as anything in I.viruses)
				if (ID == "[D.get_id()]")
					infctd_items++
					if(!length(logs["[ID]"]))
						logs["[ID]"] = list()
					logs["[ID]"] += "[I]"
					logs["[ID]"]["[I]"] = D.log
		for (var/obj/item/weapon/virusdish/dish in GLOB.virusdishes)
			if (dish.contained_virus)
				if (ID == "[dish.contained_virus.get_id()]")
					dishes++
					if(!length(logs["[ID]"]))
						logs["[ID]"] = list()
					logs["[ID]"] += "[dish]"
					logs["[ID]"]["[dish]"] = dish.contained_virus.log

		var/datum/disease/advanced/D = GLOB.inspectable_diseases[ID]
		dat += {"<tr>
			<td><a href='?_src_=holder;[HrefToken(forceGlobal = TRUE)];diseasepanel_examine=["[D.uniqueID]"]-["[D.subID]"]'>[D.form] #["[D.uniqueID]"]-["[D.subID]"]</a></td>
			<td>[D.origin]</td>
			<td><a href='?_src_=holder;[HrefToken(forceGlobal = TRUE)];diseasepanel_toggledb=\ref[D]'>[(ID in GLOB.virusDB) ? "Yes" : "No"]</a></td>
			<td><a href='?_src_=holder;[HrefToken(forceGlobal = TRUE)];diseasepanel_infectedmobs=\ref[D]'>[infctd_mobs][infctd_mobs_dead ? " (including [infctd_mobs_dead] dead)" : "" ]</a></td>
			<td><a href='?_src_=holder;[HrefToken(forceGlobal = TRUE)];diseasepanel_infecteditems=\ref[D]'>[infctd_items]</a></td>
			<td><a href='?_src_=holder;[HrefToken(forceGlobal = TRUE)];diseasepanel_dishes=\ref[D]'>[dishes]</a></td>
			</tr>
			"}

	dat += {"</table>
		"}
	dat += {"<table>
		<tr>
		<th style="width:2%">Disease Logs</th>
		</tr>"}
	for(var/item in logs[viewingID])
		dat += {"<tr>
		<td><b>[item] - [viewingID]</b><br>[logs[viewingID][item]]
		</tr>
		"}
	dat += {"</table>
		</body>
		</html>
	"}
	usr << browse(dat, "window=diseasespanel;size=705x450")

/datum/admins/Topic(href, href_list)
	. = ..()
	if(href_list["diseasepanel_examine"])
		viewingID = href_list["diseasepanel_examine"]
		diseases_panel()
