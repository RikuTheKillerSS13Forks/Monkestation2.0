/obj/item/clothing/neck/necklace/garlic
	name = "garlic necklace"
	desc = "A basic necklace with a garlic onion attached to the end. It has a strong odor."
	icon = 'monkestation/icons/vampires/necklaces.dmi'
	icon_state = "garlic_necklace"
	worn_icon = 'monkestation/icons/vampires/necklaces.dmi'
	worn_icon_state = "garlic_necklace_worn"
	clothing_traits = list(TRAIT_FEED_PROTECTION)
	strip_delay = 10 SECONDS

/obj/item/clothing/neck/necklace/garlic/examine(mob/user)
	. = ..()
	. += span_notice("Protects the wearer from vampire bites.")

/obj/item/clothing/neck/necklace/cross
	name = "cross necklace"
	desc = "A well-made cross necklace made entirely out of silver. It emanates a holy aura."
	icon = 'monkestation/icons/vampires/necklaces.dmi'
	icon_state = "cross_necklace"
	worn_icon = 'monkestation/icons/vampires/necklaces.dmi'
	worn_icon_state = "cross_necklace_worn"
	clothing_traits = list(TRAIT_FEED_PROTECTION)
	strip_delay = 10 SECONDS

/obj/item/clothing/neck/necklace/cross/examine(mob/user)
	. = ..()
	. += span_notice("Protects the wearer from vampire bites.")
	. += span_notice("Can't be stripped off by vampires.")

/obj/item/clothing/neck/necklace/cross/canStrip(mob/stripper, mob/owner)
	return ..() && !IS_VAMPIRE(stripper)
