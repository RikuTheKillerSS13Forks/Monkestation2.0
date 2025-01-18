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
