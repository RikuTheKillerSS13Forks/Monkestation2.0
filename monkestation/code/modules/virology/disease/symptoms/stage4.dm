/datum/symptom/spaceadapt
	name = "Space Adaptation Effect"
	desc = "Causes the host to secrete a thin thermally insulating and spaceproof barrier from their skin."
	badness = SYMPTOM_SEVERITY_GREAT
	minimum_potency = 1.3
	potency_scale = 0

/datum/symptom/spaceadapt/activate_passive_effect(mob/living/carbon/host, datum/disease/advanced/disease)
	host.add_traits(list(TRAIT_RESISTCOLD, TRAIT_RESISTHEAT, TRAIT_RESISTLOWPRESSURE, TRAIT_RESISTHIGHPRESSURE), SYMPTOM_TRAIT)

/datum/symptom/spaceadapt/deactivate_passive_effect(mob/living/carbon/host, datum/disease/advanced/disease)
	host.remove_traits(list(TRAIT_RESISTCOLD, TRAIT_RESISTHEAT, TRAIT_RESISTLOWPRESSURE, TRAIT_RESISTHIGHPRESSURE), SYMPTOM_TRAIT)

/datum/symptom/minttoxin
	name = "Creosote Syndrome"
	desc = "Causes the host to synthesize a wafer thin mint that reacts to high concentrations of lipids in the host."
	badness = SYMPTOM_SEVERITY_BAD
	minimum_potency = 0.8
	potency_scale = 0

/datum/symptom/minttoxin/process_active(mob/living/carbon/host, datum/disease/advanced/disease, potency, seconds_per_tick)
	if(host.reagents.get_reagent_amount(/datum/reagent/consumable/mintextract) < 5)
		to_chat(host, span_notice("You feel a minty freshness."))
		host.reagents.add_reagent(/datum/reagent/consumable/mintextract, 5)

/datum/symptom/deaf
	name = "Dead Ear Syndrome"
	desc = "Kills the host's aural senses."
	badness = SYMPTOM_SEVERITY_BAD
	potency_scale = 2

/datum/symptom/deaf/process_active(mob/living/carbon/host, datum/disease/advanced/disease, potency, seconds_per_tick)
	var/obj/item/organ/internal/ears/ears = host.get_organ_slot(ORGAN_SLOT_EARS)

	if(!ears)
		return

	if(ears.damage >= ears.maxHealth) // your ears are already fucked mate
		return

	ears.apply_organ_damage(potency * seconds_per_tick)

	if(!ears.deaf && SPT_PROB(potency * 5, seconds_per_tick))
		to_chat(host, span_bolddanger("Your ears pop and begin ringing loudly!"))
		ears.deaf = rand(10, 15) * potency

	if(potency >= 1 && !ears.deaf && SPT_PROB(potency, seconds_per_tick))
		to_chat(host, span_userdanger("Your ears pop painfully and start bleeding!"))
		host.emote("scream")
		ears.apply_organ_damage(ears.maxHealth)
		host.AdjustKnockdown((potency * 2) SECONDS)

/datum/symptom/killertoxins
	name = "Toxification Syndrome"
	desc = "Causes an advanced form of hyperacidity, resulting in rapid toxin buildup."
	badness = SYMPTOM_SEVERITY_HORRIBLE // this kills VERY quickly
	minimum_potency = 1
	potency_scale = 5 // extreme initial effect with low scaling

/datum/symptom/killertoxins/process_active(mob/living/carbon/host, datum/disease/advanced/disease, potency, seconds_per_tick)
	host.adjustToxLoss(potency * 5 * seconds_per_tick)

	if(potency >= 1.2) // this actually amounts to 2 due to potency_scale
		host.adjustOrganLoss(ORGAN_SLOT_LIVER, (potency - 0.7) * seconds_per_tick)

	if(SPT_PROB(potency * 2, seconds_per_tick))
		to_chat(host, span_warning("You feel like your organs are turning inside out."))
		host.vomit()

/datum/symptom/dna
	name = "Reverse Pattern Syndrome"
	desc = "Attacks the host's DNA, causing rapid and spontaneous mutations. This process creates heat, inhibiting the use of cryogenics."
	badness = SYMPTOM_SEVERITY_DEADLY
	potency_scale = 2

/datum/symptom/dna/process_active(mob/living/carbon/host, datum/disease/advanced/disease, potency, seconds_per_tick)
	if(host.bodytemperature < 350)
		host.bodytemperature = min(host.bodytemperature + potency * 50 * seconds_per_tick, 350)

	scramble_dna(host, TRUE, TRUE, TRUE, 100 * SPT_PROB_RATE(potency * 0.1, seconds_per_tick))
	host.adjustCloneLoss(potency * 0.1 * seconds_per_tick)

/datum/symptom/immortal
	name = "Longevity Syndrome"
	desc = "Grants functional immortality to the infected by healing external damage and wounds. Causes severe backlash when deactivated."
	badness = SYMPTOM_SEVERITY_AWESOME
	minimum_potency = 2 // scales normally, but takes one hell of a lot of effort to keep active (thus making backlash a pain)
	var/backlash = 0

/datum/symptom/immortal/process_active(mob/living/carbon/host, datum/disease/advanced/disease, potency, seconds_per_tick)
	for(var/datum/wound/wound as anything in host.all_wounds)
		if(!SPT_PROB(potency * 5, seconds_per_tick))
			continue
		to_chat(host, span_notice("You feel the [wound] in your [wound.limb] heal itself."))
		wound.remove_wound()
		break

	var/heal_amt = potency * 5 * seconds_per_tick
	backlash += heal_amt * 0.2 // you are only delaying the inevitable
	host.adjustBruteLoss(-heal_amt)
	host.adjustFireLoss(-heal_amt)

/datum/symptom/immortal/deactivate_passive_effect(mob/living/carbon/host, datum/disease/advanced/disease)
	to_chat(host, backlash < 50 ? span_warning("You suddenly feel hurt and old...") : span_userdanger("You feel a sudden wave of pain and decay!"))

	if(ishuman(host))
		var/mob/living/carbon/human/human = host
		human.age += round(backlash * 0.2)

	var/split = rand(0, 1)
	host.adjustBruteLoss(backlash * split)
	host.adjustFireLoss(backlash * (1 - split))

	backlash = 0

/datum/symptom/bones
	name = "Fragile Person Syndrome"
	desc = "Tricks the host's immune system into attacking its own bodily structures, resulting in frailty."
	badness = SYMPTOM_SEVERITY_BAD

/datum/symptom/bones/process_active(mob/living/carbon/host, datum/disease/advanced/disease, potency, seconds_per_tick)
	for (var/obj/item/bodypart/part in host.bodyparts)
		part.wound_resistance += previous_potency * 10
		part.wound_resistance -= potency * 10

/datum/symptom/bones/deactivate_passive_effect(mob/living/carbon/host, datum/disease/advanced/disease)
	for (var/obj/item/bodypart/part in host.bodyparts)
		part.wound_resistance += previous_potency * 10

/datum/symptom/fizzle
	name = "Fizzle Effect"
	desc = "Causes an ill, though harmless, sensation in the host's throat."
	badness = SYMPTOM_SEVERITY_ANNOYING

/datum/symptom/fizzle/activate_passive_effect(mob/living/carbon/host, datum/disease/advanced/disease)
	host.add_mood_event(name, /datum/mood_event/fizzle)

/datum/symptom/fizzle/deactivate_passive_effect(mob/living/carbon/host, datum/disease/advanced/disease)
	host.clear_mood_event(name)

/datum/symptom/fizzle/process_active(mob/living/carbon/host, datum/disease/advanced/disease, potency, seconds_per_tick)
	if(SPT_PROB(potency * 5, seconds_per_tick))
		host.emote(pick("cough", "sniffle"))

/datum/symptom/delightful
	name = "Delightful Effect"
	desc = "Causes the host to feel delightful. May cause severe depression when deactivated."
	badness = SYMPTOM_SEVERITY_OKAY // the depression is pretty bad, but usually its good (mood isnt that impactful)
	potency_scale = 2
	var/backlash

/datum/symptom/delightful/activate_passive_effect(mob/living/carbon/host, datum/disease/advanced/disease)
	to_chat(host, span_boldnotice("You feel delightful!"))

/datum/symptom/delightful/deactivate_passive_effect(mob/living/carbon/host, datum/disease/advanced/disease)
	if(SPT_PROB(1, backlash)) // never a 100% chance
		to_chat(host, span_boldwarning("You feel fucking horrible.")) // not gonna sugarcoat it
		host.add_mood_event(name, /datum/mood_event/delightful_depression)

/datum/symptom/delightful/process_active(mob/living/carbon/host, datum/disease/advanced/disease, potency, seconds_per_tick)
	host.clear_mood_event(name)
	host.add_mood_event(name, /datum/mood_event/delightful, potency * 5)

/datum/symptom/spawner
	name = "Arachnogenesis Effect"
	desc = "Converts the host's stomach to begin producing creatures of the arachnid variety."
	badness = SYMPTOM_SEVERITY_HORRIBLE // as it turns out, turning into a giant spider spawner is pretty damn bad
	potency_scale = 2
	var/spawn_type = /mob/living/basic/spider/growing/spiderling/guard

/datum/symptom/spawner/process_active(mob/living/carbon/host, datum/disease/advanced/disease, potency, seconds_per_tick)
	if(!SPT_PROB(potency * 2, seconds_per_tick))
		return

	playsound(host.loc, 'sound/effects/splat.ogg', 50, 1)
	var/mob/living/spawned_mob = new spawn_type(get_turf(host))
	host.emote("me", 1, "vomits up a live [spawned_mob.name]!")

	if(potency < 2)
		addtimer(CALLBACK(src, PROC_REF(kill_mob), spawned_mob), 1 MINUTE)

/datum/symptom/spawner/proc/kill_mob(mob/living/basic/target)
	target.visible_message(span_warning("The [target] falls apart!"), span_userdanger("You fall apart!"))
	target.death()

/datum/symptom/spawner/roach
	name = "Blattogenesis Effect"
	desc = "Converts the host's stomach to begin producing creatures of the blattid variety."
	badness = SYMPTOM_SEVERITY_BAD
	spawn_type = /mob/living/basic/cockroach

/datum/symptom/gregarious
	name = "Gregarious Impetus"
	desc = "Infests the social structures of the host's brain, causing them to feel better in crowds of other potential victims, and punishing them for being alone."
	badness = SYMPTOM_SEVERITY_DEADLY
	potency_scale = 2

	var/required_victims = 1
	var/max_required_victims = 4
	var/satisfied = TRUE

/datum/symptom/gregarious/process_active(mob/living/carbon/host, datum/disease/advanced/disease, potency, seconds_per_tick)
	var/others_count = 0
	for(var/mob/living/carbon/m in oview(5, host))
		others_count++

	if (others_count >= required_victims)
		if (!satisfied)
			to_chat(host, span_notice("A friendly sensation is satisfied with how many are near you - for now."))
			satisfied = TRUE

		host.adjustOrganLoss(ORGAN_SLOT_BRAIN, -potency * seconds_per_tick)
		host.add_mood_event(name, /datum/mood_event/gregarious_positive)

		required_victims = min(required_victims + 0.15 * potency * seconds_per_tick, max_required_victims) // it hungers
		return

	if (satisfied)
		to_chat(host, span_warning("A hostile sensation in your brain stings you... it wants more of the living near you."))
		satisfied = FALSE

	host.adjustOrganLoss(ORGAN_SLOT_BRAIN, potency * 2 * seconds_per_tick)
	host.add_mood_event(name, /datum/mood_event/gregarious_negative)

	if (SPT_PROB(potency * 5, seconds_per_tick))
		host.visible_message(
			message = span_danger("[host] collapses and clasps their head in pain!"),
			self_message = span_userdanger("A massive wave of pain washes over your head!"),
			blind_message = span_hear("You hear a thud.")
		)
		host.AdjustParalyzed(2 SECONDS)
		host.emote("scream")

	required_victims = max(required_victims - 0.3 / potency * seconds_per_tick, 1) // finally some good fucking food

/datum/symptom/gregarious/deactivate_passive_effect(mob/living/carbon/host, datum/disease/advanced/disease)
	host.clear_mood_event(name)

/datum/symptom/magnitis
	name = "Magnitis"
	desc = "Creates strong magnetic fields around the host. Iron can act as a conduit for the fields, nullifying their external effects."
	badness = SYMPTOM_SEVERITY_HORRIBLE
	potency_scale = 3

/datum/symptom/magnitis/process_active(mob/living/carbon/host, datum/disease/advanced/disease, potency, seconds_per_tick)
	if (host.reagents.has_reagent(/datum/reagent/iron))
		if (SPT_PROB(potency * 2, seconds_per_tick))
			to_chat(host, span_warning("You feel a painful prickling sensation under your skin."))
		host.adjustBruteLoss(potency * 0.5) // gives you plenty of time to work out countermeasures... usually
		return

	var/intensity = (1 + min(2, current_cycles * 0.1)) * potency // every time it attracts, it gets slightly stronger, then resets when deactivated

	if (SPT_PROB(intensity, seconds_per_tick))
		to_chat(host, span_warning("You feel a [intensity < 3 ? "slight" : "powerful"] shock course through your body."))
		playsound(host, SFX_SPARKS, 100, TRUE, SHORT_RANGE_SOUND_EXTRARANGE)
		host.do_jitter_animation(10)

	var/list/nearby_stuff = orange(intensity, host)
	var/move_force = intensity * MOVE_FORCE_STRONG

	for (var/obj/nearby in nearby_stuff)
		if (nearby.anchored)
			continue
		if (nearby.move_resist > move_force)
			continue
		var/steps = rand(1, intensity)
		for(var/i = 0, i < steps, i++)
			step_towards(nearby, host)

	for (var/mob/living/silicon/silicon in nearby_stuff)
		if (silicon.move_resist > move_force)
			continue
		var/steps = rand(1, intensity)
		for(var/i = 0, i < steps, i++)
			step_towards(silicon, host)

/*/datum/symptom/dnaspread //commented out due to causing enough problems to turn random people into monkies apon curing.
	name = "Retrotransposis"
	desc = "This symptom transplants the genetic code of the intial vector into new hosts."
	badness = EFFECT_DANGER_HARMFUL
	stage = 4
	var/datum/dna/saved_dna
	var/original_name
	var/activated = 0
	///old info
	var/datum/dna/old_dna
	var/old_name

/datum/symptom/dnaspread/process_active(mob/living/carbon/host, datum/disease/advanced/disease, potency, seconds_per_tick)
	if(!activated)
		to_chat(mob, span_warning("You don't feel like yourself.."))
		old_dna = new
		C.dna.copy_dna(old_dna)
		old_name = C.real_name

	if(!iscarbon(mob))
		return
	var/mob/living/carbon/C = mob
	if(!saved_dna)
		saved_dna = new
		original_name = C.real_name
		C.dna.copy_dna(saved_dna)
	C.regenerate_icons()
	saved_dna.copy_dna(C.dna)
	C.real_name = original_name
	activated = TRUE

/datum/symptom/dnaspread/process_inactive(mob/living/carbon/host, datum/disease/advanced/disease, seconds_per_tick)
	activated = FALSE
	if(!old_dna)
		return
	old_dna.copy_dna(C.dna)
	C.real_name = old_name

/datum/symptom/dnaspread/Copy(datum/disease/advanced/disease)
	var/datum/symptom/dnaspread/new_e = ..(disease)
	new_e.original_name = original_name
	new_e.saved_dna = saved_dna
	return new_e

/datum/symptom/species
	name = "Lizarditis"
	desc = "Turns you into a Lizard."
	badness = EFFECT_DANGER_HARMFUL
	stage = 4
	var/datum/species/old_species
	var/datum/species/new_species = /datum/species/lizard
	max_count = 1
	max_chance = 24

/datum/symptom/species/process_active(mob/living/carbon/host, datum/disease/advanced/disease, potency, seconds_per_tick)
	var/mob/living/carbon/human/victim = mob
	if(!ishuman(victim))
		return
	old_species = mob.dna.species
	if(!old_species)
		return
	victim.set_species(new_species)

/datum/symptom/species/process_inactive(mob/living/carbon/host, datum/disease/advanced/disease, seconds_per_tick)
	var/mob/living/carbon/human/victim = mob
	if(!ishuman(victim))
		return
	if(!old_species)
		return
	victim.set_species(old_species)

/datum/symptom/species/moth
	name = "Mothification"
	desc = "Turns you into a Moth."
	new_species = /datum/species/moth
*/
/datum/symptom/retrovirus
	name = "Retrovirus" // I CAN DO ANYTHING
	desc = "A DNA-altering retrovirus that scrambles the structural and unique enzymes of a host constantly, causing completely unpredictable symptoms."
	badness = SYMPTOM_SEVERITY_HORRIBLE
	potency_scale = 2

/datum/symptom/retrovirus/process_active(mob/living/carbon/host, datum/disease/advanced/disease, potency, seconds_per_tick)
	if(SPT_PROB(2, seconds_per_tick))
		to_chat(host, span_danger("Your head hurts."))
		host.add_mood_event("retro_headache", /datum/mood_event/retro_headache)
	if(SPT_PROB(1.5, seconds_per_tick))
		to_chat(host, span_danger("You feel a tingling sensation in your chest."))
		host.adjustOrganLoss(pick(ORGAN_SLOT_HEART, ORGAN_SLOT_LUNGS, ORGAN_SLOT_STOMACH, ORGAN_SLOT_LIVER), potency * 10)
	if(SPT_PROB(2.5, seconds_per_tick))
		to_chat(host, span_danger("You feel angry."))
		host.add_mood_event("retro_angry", /datum/mood_event/retro_angry)

	if(potency < 2)
		return

	if(SPT_PROB(3, seconds_per_tick) && !is_species(host, /datum/species/human/krokodil_addict))
		if(prob(30) && ishuman(host))
			to_chat(host, span_userdanger("Your skin falls off! What the fuck?!"))
			var/mob/living/carbon/human/human_host = host // CTRL + C and CTRL + V here we fucking go!
			human_host.facial_hairstyle = "Shaved"
			human_host.hairstyle = "Bald"
			human_host.update_body_parts()
			human_host.set_species(/datum/species/human/krokodil_addict)
			human_host.adjustBruteLoss(25 * potency)
			host.add_mood_event("retro_skin", /datum/mood_event/retro_skinoff)
		else
			to_chat(host, span_danger("Your skin feels loose."))
			host.add_mood_event("retro_skin", /datum/mood_event/retro_skinloose) // haha, skinloose? get it? cause sin- *dies*
	if(SPT_PROB(2, seconds_per_tick))
		to_chat(host, span_danger("You feel very strange."))
		host.adjust_hallucinations_up_to((5 * potency) SECONDS, 30 SECONDS)
	if(SPT_PROB(1.5, seconds_per_tick))
		to_chat(host, span_danger("You feel a stabbing pain in your head!"))
		host.emote("collapse")
	if(SPT_PROB(2.5, seconds_per_tick))
		to_chat(host, span_danger("Your stomach churns painfully!"))
		host.vomit(potency * 20)

	if(potency < 3)
		return

	if(SPT_PROB(3, seconds_per_tick))
		to_chat(host, span_danger("Your entire body vibrates."))
		host.do_jitter_animation(100)
		host.stamina.adjust(potency * -25)
	if(SPT_PROB(10, seconds_per_tick))
		switch(rand(1,3)) // now this, THIS is shitcode, except i cant figure out how to make it any better
			if(1)
				scramble_dna(host, 1, 0, 0, rand(15,45))
			if(2)
				scramble_dna(host, 0, 1, 0, rand(15,45))
			if(3)
				scramble_dna(host, 0, 0, 1, rand(15,45))

	if(potency < 4)
		return

	if(SPT_PROB(20, seconds_per_tick)) // oh good lord of mutations
		switch(rand(1,3))
			if(1)
				scramble_dna(host, 1, 0, 0, rand(50,75))
			if(2)
				scramble_dna(host, 0, 1, 0, rand(50,75))
			if(3)
				scramble_dna(host, 0, 0, 1, rand(50,75))

/datum/symptom/rhumba_beat
	name = "The Rhumba Beat"
	desc = "Chick Chicky Boom!"
	badness = SYMPTOM_SEVERITY_HORRIBLE
	potency_scale = 2
	minimum_potency = 2

	var/progress = 0

/datum/symptom/rhumba_beat/process_active(mob/living/carbon/host, datum/disease/advanced/disease, potency, seconds_per_tick)
	switch(progress)
		if(-INFINITY to 1)
			if(SPT_PROB(25, seconds_per_tick))
				host.adjustFireLoss(5 * potency, FALSE)
			if(SPT_PROB(1, seconds_per_tick))
				to_chat(host, span_danger("You feel strange..."))
		if(1 to 2)
			if(SPT_PROB(2, seconds_per_tick))
				to_chat(host, span_danger("You feel the urge to dance..."))
			else if(SPT_PROB(2, seconds_per_tick))
				host.emote("gasp")
			else if(SPT_PROB(5, seconds_per_tick))
				to_chat(host, span_danger("You feel the need to chick chicky boom..."))
		if(2 to 3)
			if(SPT_PROB(5, seconds_per_tick))
				if(prob(50))
					host.adjust_fire_stacks(potency * 2)
					host.ignite_mob()
				else
					host.emote("gasp")
					to_chat(host, span_danger("You feel a burning beat inside..."))
		if(4 to INFINITY)
			if(SPT_PROB(20, seconds_per_tick))
				to_chat(host, span_danger("Your body is unable to contain the Rhumba Beat..."))
				dyn_explosion(host, potency * 2, flame_range = 1.25, flash_range = 1.5, adminlog = FALSE, explosion_cause = src) // at potency 4, causes a devastating explosion
				progress = 0
	progress = min(progress + potency * 0.1 * seconds_per_tick, 5) // 5 so it has leeway

/datum/symptom/rhumba_beat/process_inactive(mob/living/carbon/host, datum/disease/advanced/disease, potency, seconds_per_tick)
	if(progress > 0 && SPT_PROB(2, seconds_per_tick))
		to_chat(host, span_notice("Your body seems to be calming down..."))
	progress = max(progress - 0.2 * seconds_per_tick, 0)

/datum/symptom/adaptation
	name = "Inorganic Biology"
	desc = "The pathogen can survive and replicate even in an inorganic environment."
	badness = SYMPTOM_SEVERITY_NEUTRAL
	minimum_potency = 0 // having it still causes a base potency malus

	var/biotypes = MOB_MINERAL | MOB_ROBOTIC

/datum/symptom/adaptation/activate_passive_effect(mob/living/carbon/host, datum/disease/advanced/disease)
	disease.infectable_biotypes |= biotypes

/datum/symptom/adaptation/deactivate_passive_effect(mob/living/carbon/host, datum/disease/advanced/disease)
	disease.infectable_biotypes &= ~(biotypes)

/datum/symptom/adaptation/undead
	name = "Necrotic Metabolism"
	desc = "The pathogen is able to thrive and act even within dead hosts."
	biotypes = MOB_UNDEAD

/datum/symptom/adaptation/undead/activate_passive_effect(mob/living/carbon/host, datum/disease/advanced/disease)
	. = ..()
	disease.process_dead = TRUE

/datum/symptom/adaptation/undead/deactivate_passive_effect(mob/living/carbon/host, datum/disease/advanced/disease)
	. = ..()
	disease.process_dead = FALSE

/datum/symptom/oxygen
	name = "Self-Respiration"
	desc = "The pathogen synthesizes oxygen, which can remove the need for breathing at high potency. Even higher potencies can result in rapid blood restoration."
	badness = SYMPTOM_SEVERITY_GREAT

	var/breathing = TRUE

/datum/symptom/oxygen/process_active(mob/living/carbon/host, datum/disease/advanced/disease, potency, seconds_per_tick)
	host.losebreath = max(0, host.losebreath - potency * seconds_per_tick)
	host.adjustOxyLoss(potency * -2 * seconds_per_tick)

	if(potency >= 2)
		if(SPT_PROB(5, seconds_per_tick) && current_cycles < 30)
			to_chat(host, span_notice(pick("Your lungs feel great.", "You realize you haven't been breathing.", "You don't feel the need to breathe.")))
		stop_breathing(host)
	else
		start_breathing(host)

	if(potency >= 3) // readds the legacy blood volume restoration threshold, albeit in a different form
		if(SPT_PROB(3, seconds_per_tick) && host.blood_volume < BLOOD_VOLUME_SAFE)
			to_chat(host, span_boldnotice("You feel a pleasant warmth that breaks through your clammy skin."))
		host.blood_volume = min(BLOOD_VOLUME_NORMAL, host.blood_volume + potency * seconds_per_tick)

/datum/symptom/oxygen/deactivate_passive_effect(mob/living/carbon/host, datum/disease/advanced/disease)
	start_breathing(host)

/datum/symptom/oxygen/proc/stop_breathing(mob/living/carbon/host)
	if (!breathing)
		return
	breathing = FALSE
	ADD_TRAIT(host, TRAIT_NOBREATH, DISEASE_TRAIT)

/datum/symptom/oxygen/proc/start_breathing(mob/living/carbon/host)
	if (breathing)
		return
	breathing = TRUE
	REMOVE_TRAIT(host, TRAIT_NOBREATH, DISEASE_TRAIT)
	host.emote("gasp")
	to_chat(host, span_danger("You feel the need to breathe again."))
