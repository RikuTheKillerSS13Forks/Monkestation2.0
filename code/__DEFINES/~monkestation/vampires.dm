#define IS_VAMPIRE(mob) (mob?.mind?.has_antag_datum(/datum/antagonist/vampire))
#define IS_THRALL(mob) (mob?.mind?.has_antag_datum(/datum/antagonist/vampire/thrall))

/// The maximum amount of lifeforce a vampire can have.
#define LIFEFORCE_MAXIMUM 200

/// The amount of lifeforce a vampire gets from one human.
#define LIFEFORCE_PER_HUMAN 100

/// Multiply blood by this to get lifeforce.
#define LIFEFORCE_TO_BLOOD (LIFEFORCE_PER_HUMAN / BLOOD_VOLUME_NORMAL)

/// Multiply lifeforce by this to get blood.
#define BLOOD_TO_LIFEFORCE (BLOOD_VOLUME_NORMAL / LIFEFORCE_PER_HUMAN)

/// The amount of lifeforce that a vampire loses per second by default.
#define LIFEFORCE_THIRST (LIFEFORCE_PER_HUMAN / 3600)

/// The ability checks whether the vampire has enough lifeforce to use it.
#define VAMPIRE_AC_LIFEFORCE (1 << 0)
/// The ability can't be used while using masquerade.
#define VAMPIRE_AC_MASQUERADE (1 << 1)
/// The ability can't be used while in a frenzy.
#define VAMPIRE_AC_FRENZY (1 << 2)
