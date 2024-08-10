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
