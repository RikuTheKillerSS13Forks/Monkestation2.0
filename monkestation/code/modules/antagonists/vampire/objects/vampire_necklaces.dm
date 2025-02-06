/obj/item/clothing/neck/cross_necklace
	name = "cross necklace"
	desc = "A well-made cross necklace made entirely out of silver. It emanates a holy aura."
	clothing_traits = list(TRAIT_FEED_PROTECTION)

/obj/item/clothing/neck/cross_necklace/examine(mob/user)
	. = ..()
	. += span_notice("Protects the wearer from vampire bites.")
	. += span_notice("Can't be removed by a vampire.")
