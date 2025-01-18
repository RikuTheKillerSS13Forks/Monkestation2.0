// This is what makes someone a vampiric thrall.

/obj/item/organ/internal/flesh_bud
	name = "flesh bud"
	desc = "An abominable and sickly looking ball of flesh. It has tendrils jutting out from all sides."
	zone = BODY_ZONE_HEAD
	slot = ORGAN_SLOT_VAMPIRE_FLESH_BUD

	var/datum/antagonist/vampire/master_vampire

/obj/item/organ/internal/flesh_bud/on_insert(mob/living/carbon/organ_owner, special)
	. = ..()
	RegisterSignal(organ_owner, COMSIG_MOB_MIND_TRANSFERRED_INTO, PROC_REF(on_mind_transferred_into_owner))
	if (organ_owner.mind)
		add_thrall_datum(organ_owner.mind)

/obj/item/organ/internal/flesh_bud/on_remove(mob/living/carbon/organ_owner, special)
	. = ..()
	UnregisterSignal(organ_owner, COMSIG_MOB_MIND_TRANSFERRED_INTO)
	if (organ_owner.mind)
		remove_thrall_datum(organ_owner.mind)

/obj/item/organ/internal/flesh_bud/proc/add_thrall_datum(datum/mind/mind)
	mind.add_antag_datum(/datum/antagonist/vampire/thrall)
	RegisterSignals(mind, list(COMSIG_MIND_TRANSFERRED, COMSIG_QDELETING), PROC_REF(on_mind_removed_from_owner))

/obj/item/organ/internal/flesh_bud/proc/remove_thrall_datum(datum/mind/mind)
	mind.remove_antag_datum(/datum/antagonist/vampire/thrall)
	UnregisterSignal(mind, list(COMSIG_MIND_TRANSFERRED, COMSIG_QDELETING), PROC_REF(on_mind_removed_from_owner))

/obj/item/organ/internal/flesh_bud/proc/on_mind_transferred_into_owner(mob/living/carbon/owner)
	SIGNAL_HANDLER
	add_thrall_datum(owner.mind)

/obj/item/organ/internal/flesh_bud/proc/on_mind_removed_from_owner(datum/mind/mind)
	SIGNAL_HANDLER
	remove_thrall_datum(mind)
