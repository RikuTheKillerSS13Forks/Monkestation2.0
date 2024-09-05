/obj/item/clothing/glasses/pathology
	name = "viral analyzer goggles"
	desc = "A pair of goggles fitted with an analyzer for viral particles and reagents. Comes with a handy toggle for avoiding visual overload."

	icon = 'monkestation/icons/obj/clothing/glasses.dmi'
	worn_icon = 'monkestation/icons/obj/clothing/eyes.dmi'
	inhand_icon_state = "glasses"

	clothing_traits = list(TRAIT_REAGENT_SCANNER)

/obj/item/clothing/glasses/pathology/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/pathology_glasses, icon_state_on = "pathology_on", icon_state_off = "pathology_off")
