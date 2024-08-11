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
 * Lifeforce
 */
/// The maximum amount of lifeforce a vampire can carry. This is a soft cap.
#define LIFEFORCE_MAXIMUM 200
/// How much lifeforce one human is roughly worth. Can vary wildly sometimes.
#define LIFEFORCE_PER_HUMAN 100
/// How much lifeforce is lost per second by default. 20 min/human
#define LIFEFORCE_DRAIN_BASE LIFEFORCE_PER_HUMAN / -1200
/// Multiply lifeforce by this to get an equivalent amount of blood.
#define LIFEFORCE_TO_BLOOD BLOOD_VOLUME_NORMAL / LIFEFORCE_PER_HUMAN
/// Multiply blood by this to get an equivalent amount of lifeforce.
#define BLOOD_TO_LIFEFORCE LIFEFORCE_PER_HUMAN / BLOOD_VOLUME_NORMAL

/**
 * Lifeforce Change Sources
 */
#define LIFEFORCE_CHANGE_THIRST "thirst"

/**
 * Vampire Rank
 */
#define VAMPIRE_RANK_MAX 6
