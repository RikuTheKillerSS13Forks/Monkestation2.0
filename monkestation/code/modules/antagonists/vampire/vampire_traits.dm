/datum/antagonist/vampire
	/// Traits that vampires always have.
	var/static/list/innate_traits = list(
		TRAIT_NOBLOOD,
		TRAIT_NOBREATH,
		TRAIT_NOHUNGER,
		TRAIT_STABLEHEART,
		TRAIT_GENELESS,
		TRAIT_ANALGESIA,
		TRAIT_ABATES_SHOCK,
		TRAIT_NO_PAIN_EFFECTS,
		TRAIT_NO_SHOCK_BUILDUP,
		TRAIT_NOCRITDAMAGE,
		TRAIT_RESISTCOLD, // Otherwise you can chuck vamps into space to permanently kill them, and they also get massive debuffs in space to compensate for this.
		TRAIT_RESISTLOWPRESSURE, // Ditto.
		TRAIT_NO_ORGAN_DECAY,
	)

	/// Traits that vampires only have while out of masquerade.
	var/static/list/visible_traits = list(
		TRAIT_NO_ORGAN_DECAY, // I don't want doctors just immediately going like "Huh, this guy has no organ decay... and no formaldehyde, oh it's a vamp!" even OOCly.
		TRAIT_NO_MIRROR_REFLECTION,
		TRAIT_COLD_BLOODED,
	)

	/// Traits that vampires only have while in masquerade.
	var/static/list/masquerade_traits = list(
		// add fake blood and fake genes here later
	)
