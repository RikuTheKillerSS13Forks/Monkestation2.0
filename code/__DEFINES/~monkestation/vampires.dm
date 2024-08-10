/**
 * Roles
 */
#define ROLE_VAMPIRE "Vampire"
#define ROLE_VAMPIRICACCIDENT "Vampiric Accident"

/**
 * Traits
 */
/// The mob has special interactions with vampires and the occult.
#define TRAIT_OCCULTIST "occultist"
/// Hides signs of being a vampire, such as a total lack of blood.
#define TRAIT_MASQUERADE "masquerade"
/// Makes your body temperature follow room temperature. Doesn't make you immune to temperature changes.
#define TRAIT_COLDBLOODED "coldblooded"

/**
 * Sources
 */
/// Trait source for vampires.
#define VAMPIRE_TRAIT "vampire_trait"

/**
 * Macros
 */
/// Returns whether a mob is a vampire.
#define IS_VAMPIRE(mob) (mob?.mind?.has_antag_datum(/datum/antagonist/vampire))

/**
 * Life Force
 */
/// The maximum amount of life force a vampire can carry. This is a soft cap.
#define LIFE_FORCE_MAXIMUM 200
/// How much life force one human is roughly worth. Can vary wildly sometimes.
#define LIFE_FORCE_PER_HUMAN 100
/// How much life force is lost per second by default. 20 min/human
#define LIFE_FORCE_DRAIN_BASE LIFE_FORCE_PER_HUMAN / -1200
/// Multiply life force by this to get an equivalent amount of blood.
#define LIFE_FORCE_TO_BLOOD BLOOD_VOLUME_NORMAL / LIFE_FORCE_PER_HUMAN
/// Multiply blood by this to get an equivalent amount of life force.
#define BLOOD_TO_LIFE_FORCE LIFE_FORCE_PER_HUMAN / BLOOD_VOLUME_NORMAL

/**
 * Life Force Change Sources
 */
#define LIFE_FORCE_CHANGE_THIRST "thirst"
