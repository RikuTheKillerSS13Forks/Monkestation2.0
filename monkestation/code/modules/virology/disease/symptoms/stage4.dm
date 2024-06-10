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

	if(SPT_PROB(potency, seconds_per_tick))
		to_chat(host, span_warning("You feel like your organs are turning inside out."))

/datum/symptom/dna
	name = "Reverse Pattern Syndrome"
	desc = "Attacks the host's DNA, causing rapid and spontaneous mutations. Also tries to keep the host above the required temperatures for cryogenics."
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
	badness = SYMPTOM_SEVERITY_OKAY // the depression is pretty bad
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

/datum/symptom/spawn
	name = "Arachnogenesis Effect"
	desc = "Converts the infected's stomach to begin producing creatures of the arachnid variety."
	stage = 4
	max_multiplier = 7
	badness = EFFECT_DANGER_HARMFUL
	var/spawn_type= /mob/living/basic/spider/growing/spiderling/guard
	var/spawn_name="spiderling"

/datum/symptom/spawn/process_active(mob/living/carbon/host, datum/disease/advanced/disease, potency, seconds_per_tick)
	playsound(mob.loc, 'sound/effects/splat.ogg', 50, 1)
	var/mob/living/spawned_mob = new spawn_type(get_turf(mob))
	mob.emote("me",1,"vomits up a live [spawn_name]!")
	if(multiplier < 4)
		addtimer(CALLBACK(src, PROC_REF(kill_mob), spawned_mob), 1 MINUTES)

/datum/symptom/spawn/proc/kill_mob(mob/living/basic/mob)
	mob.visible_message(span_warning("The [mob] falls apart!"), span_warning("You fall apart"))
	mob.death()

/datum/symptom/spawn/roach
	name = "Blattogenesis Effect"
	desc = "Converts the infected's stomach to begin producing creatures of the blattid variety."
	stage = 4
	badness = EFFECT_DANGER_HINDRANCE
	spawn_type=/mob/living/basic/cockroach
	spawn_name="cockroach"

/datum/symptom/gregarious
	name = "Gregarious Impetus"
	desc = "Infests the social structures of the infected's brain, causing them to feel better in crowds of other potential victims, and punishing them for being alone."
	stage = 4
	badness = EFFECT_DANGER_HINDRANCE
	max_chance = 25
	max_multiplier = 4

/datum/symptom/gregarious/process_active(mob/living/carbon/host, datum/disease/advanced/disease, potency, seconds_per_tick)
	var/others_count = 0
	for(var/mob/living/carbon/m in oview(5, mob))
		others_count += 1

	if (others_count >= multiplier)
		to_chat(mob, span_notice("A friendly sensation is satisfied with how many are near you - for now."))
		mob.adjustOrganLoss(ORGAN_SLOT_BRAIN, -multiplier)
		mob.reagents.add_reagent(/datum/reagent/drug/happiness, multiplier) // ADDICTED TO HAVING FRIENDS
		if (multiplier < max_multiplier)
			multiplier += 0.15 // The virus gets greedier
	else
		to_chat(mob, span_warning("A hostile sensation in your brain stings you... it wants more of the living near you."))
		mob.adjustOrganLoss(ORGAN_SLOT_BRAIN, multiplier / 2)
		mob.AdjustParalyzed(multiplier) // This practically permaparalyzes you at higher multipliers but
		mob.AdjustKnockdown(multiplier) // that's your fucking fault for not being near enough people
		mob.AdjustStun(multiplier)   // You'll have to wait until the multiplier gets low enough
		if (multiplier > 1)
			multiplier -= 0.3 // The virus tempers expectations

/datum/symptom/magnitis
	name = "Magnitis"
	desc = "This disease disrupts the magnetic field of the body, making it act as if a powerful magnet."
	stage = 4
	badness = EFFECT_DANGER_DEADLY
	chance = 5
	max_chance = 20

/datum/symptom/magnitis/process_active(mob/living/carbon/host, datum/disease/advanced/disease, potency, seconds_per_tick)
	if(mob.reagents.has_reagent(/datum/reagent/iron))
		return

	var/intensity = 1 + (count > 10) + (count > 20)
	if (prob(20))
		to_chat(mob, span_warning("You feel a [intensity < 3 ? "slight" : "powerful"] shock course through your body."))
	for(var/obj/M in orange(3 * intensity,mob))
		if(!M.anchored)
			var/iter = rand(1,intensity)
			for(var/i=0,i<iter,i++)
				step_towards(M,mob)
	for(var/mob/living/silicon/S in orange(3 * intensity,mob))
		if(istype(S, /mob/living/silicon/ai))
			continue
		var/iter = rand(1,intensity)
		for(var/i=0,i<iter,i++)
			step_towards(S,mob)

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
	name = "Retrovirus"
	desc = "A DNA-altering retrovirus that scrambles the structural and unique enzymes of a host constantly."
	max_multiplier = 4
	stage = 4
	badness = EFFECT_DANGER_HARMFUL

/datum/symptom/retrovirus/activate(mob/living/carbon/affected_mob)
	if(!iscarbon(affected_mob))
		return
	switch(multiplier)
		if(1)
			if(prob(4))
				to_chat(affected_mob, span_danger("Your head hurts."))
			if(prob(4.5))
				to_chat(affected_mob, span_danger("You feel a tingling sensation in your chest."))
			if(prob(4.5))
				to_chat(affected_mob, span_danger("You feel angry."))
		if(2)
			if(prob(4))
				to_chat(affected_mob, span_danger("Your skin feels loose."))
			if(prob(5))
				to_chat(affected_mob, span_danger("You feel very strange."))
			if(prob(2))
				to_chat(affected_mob, span_danger("You feel a stabbing pain in your head!"))
				affected_mob.Unconscious(40)
			if(prob(2))
				to_chat(affected_mob, span_danger("Your stomach churns."))
		if(3)
			if(prob(5))
				to_chat(affected_mob, span_danger("Your entire body vibrates."))
			if(prob(19))
				switch(rand(1,3))
					if(1)
						scramble_dna(affected_mob, 1, 0, 0, rand(15,45))
					if(2)
						scramble_dna(affected_mob, 0, 1, 0, rand(15,45))
					if(3)
						scramble_dna(affected_mob, 0, 0, 1, rand(15,45))
		if(4)
			if(prob(37))
				switch(rand(1,3))
					if(1)
						scramble_dna(affected_mob, 1, 0, 0, rand(50,75))
					if(2)
						scramble_dna(affected_mob, 0, 1, 0, rand(50,75))
					if(3)
						scramble_dna(affected_mob, 0, 0, 1, rand(50,75))

/datum/symptom/rhumba_beat
	name = "The Rhumba Beat"
	desc = "Chick Chicky Boom!"
	max_multiplier = 5
	stage = 4
	badness = EFFECT_DANGER_DEADLY

/datum/symptom/rhumba_beat/activate(mob/living/carbon/affected_mob)
	if(ismouse(affected_mob))
		affected_mob.gib()
		return
	multiplier += 0.1

	switch(round(multiplier))
		if(2)
			if(prob(26))
				affected_mob.adjustFireLoss(5, FALSE)
			if(prob(0.5))
				to_chat(affected_mob, span_danger("You feel strange..."))
		if(3)
			if(prob(2.5))
				to_chat(affected_mob, span_danger("You feel the urge to dance..."))
			else if(prob(2.5))
				affected_mob.emote("gasp")
			else if(prob(5))
				to_chat(affected_mob, span_danger("You feel the need to chick chicky boom..."))
		if(4)
			if(prob(10))
				if(prob(50))
					affected_mob.adjust_fire_stacks(2)
					affected_mob.ignite_mob()
				else
					affected_mob.emote("gasp")
					to_chat(affected_mob, span_danger("You feel a burning beat inside..."))
		if(5)
			to_chat(affected_mob, span_danger("Your body is unable to contain the Rhumba Beat..."))
			if(prob(29))
				explosion(affected_mob, devastation_range = -1, light_impact_range = 2, flame_range = 2, flash_range = 3, adminlog = FALSE, explosion_cause = src) // This is equivalent to a lvl 1 fireball
				multiplier -= 3


/datum/symptom/adaptation
	name = "Inorganic Biology"
	desc = "The virus can survive and replicate even in an inorganic environment, increasing its resistance and infection rate."
	max_count = 1
	stage = 4
	badness = EFFECT_DANGER_FLAVOR
	var/biotypes = MOB_MINERAL | MOB_ROBOTIC

/datum/symptom/adaptation/process_active(mob/living/carbon/host, datum/disease/advanced/disease, seconds_per_tick, datum/disease/advanced/disease)
	disease.infectable_biotypes |= biotypes

/datum/symptom/adaptation/process_inactive(mob/living/carbon/host, datum/disease/advanced/disease, seconds_per_tick, datum/disease/advanced/disease)
	disease.infectable_biotypes &= ~(biotypes)

/datum/symptom/adaptation/undead
	name = "Necrotic Metabolism"
	desc = "The virus is able to thrive and act even within dead hosts."
	biotypes = MOB_UNDEAD

/datum/symptom/adaptation/undead/process_active(mob/living/carbon/host, datum/disease/advanced/disease, seconds_per_tick, datum/disease/advanced/disease)
	.=..()
	disease.process_dead = TRUE

/datum/symptom/adaptation/undead/process_inactive(mob/living/carbon/host, datum/disease/advanced/disease, seconds_per_tick, datum/disease/advanced/disease)
	.=..()
	disease.process_dead = FALSE

/datum/symptom/oxygen
	name = "Self-Respiration"
	desc = "The virus synthesizes oxygen, which can remove the need for breathing at high symptom strength."
	stage = 4
	max_multiplier = 5
	badness = EFFECT_DANGER_HELPFUL
	var/breathing = TRUE

/datum/symptom/oxygen/process_active(mob/living/carbon/host, datum/disease/advanced/disease, seconds_per_tick, datum/disease/advanced/disease)
	mob.losebreath = max(0, mob.losebreath - multiplier)
	mob.adjustOxyLoss(-2 * multiplier)
	if(multiplier >= 4)
		to_chat(mob, span_notice("[pick("Your lungs feel great.", "You realize you haven't been breathing.", "You don't feel the need to breathe.")]"))
		if(breathing)
			breathing = FALSE
			ADD_TRAIT(mob, TRAIT_NOBREATH, DISEASE_TRAIT)

/datum/symptom/oxygen/process_inactive(mob/living/carbon/host, datum/disease/advanced/disease, seconds_per_tick, datum/disease/advanced/disease)
	if(!breathing)
		breathing = TRUE
		REMOVE_TRAIT(mob, TRAIT_NOBREATH, DISEASE_TRAIT)
		mob.emote("gasp")
		to_chat(mob, span_notice("You feel the need to breathe again."))
