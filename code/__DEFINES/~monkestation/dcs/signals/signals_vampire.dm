/// Sent by the vampire antag datum when it enters/leaves masquerade. (new_state, old_state)
#define COMSIG_VAMPIRE_MASQUERADE "vampire_masquerade"

/// Sent by the vampire antag datum when the amount of lifeforce it holds changes. (new_amount, old_amount)
#define COMSIG_VAMPIRE_LIFEFORCE_CHANGED "vampire_lifeforce_changed"

/// Sent by the vampire antag datum when it's removed from a mob.
#define COMSIG_VAMPIRE_CLEANUP "vampire_cleanup"

/// Sent by a mob when fed from by a vampire. Amount is in blood. Only sent when feeding via blood, not lifeforce directly. (mob/living/carbon/human/vampire, amount)
#define COMSIG_MOB_FED_FROM "mob_fed_from"
