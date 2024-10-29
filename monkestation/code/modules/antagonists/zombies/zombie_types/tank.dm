/datum/species/zombie/infectious/tank
	name = "Tank Zombie"
	armor = 40
	maxhealthmod = 1.5
	heal_rate = 1 // Slightly higher regeneration rate.
	hand_path = /obj/item/mutant_hand/zombie/low_infection
	granted_action_types = list(
		/datum/action/cooldown/zombie/feast,
	)
