/// Sent by the vampire antag datum when the amount of lifeforce it has changes. Can be sent even if it hits 0, right before being dusted. (old_amount)
#define COMSIG_VAMPIRE_LIFEFORCE_CHANGED "lifeforce_changed"
/// Sent by the vampire antag datum when it's vampire rank changes. New rank is always higher than the old. (old_rank)
#define COMSIG_VAMPIRE_RANK_CHANGED "vampire_rank_changed"
/// Sent by the vampire antag datum when one of it's stat amounts changes. New stat is always higher than the old. (stat, old_amount, new_amount)
#define COMSIG_VAMPIRE_STAT_CHANGED "vampire_stat_changed"
