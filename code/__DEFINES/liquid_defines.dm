/// The amount of liquid a turf can contain by default.
/// Adjusted by height and possibly other factors.
#define LIQUID_BASE_TURF_MAXIMUM_VOLUME 1000

/// Gets the amount of liquid the given turf can contain.
/// This is the actual value, after adjustments. Must be consistent for the entire lifespan of the turf.
#define LIQUID_GET_TURF_MAXIMUM_VOLUME(turf) (max(0, LIQUID_BASE_TURF_MAXIMUM_VOLUME - initial(turf.turf_height) * 10))

/// Whether the type of the given turf can hold liquid at all. Does not assume it's an open turf.
/// Try not to make this the world's most expensive macro, it could get pretty hot. (and does when spawning large numbers of liquids)
#define LIQUID_CAN_ENTER_TURF_TYPE(turf) (isopenturf(turf) && !isspaceturf(turf) && !isopenspaceturf(turf))

/// Immediately calls liquid_group.update_edges(adjacent_turf) for all cardinally adjacent turfs, after doing sanity checks for each of them.
#define LIQUID_UPDATE_ADJACENT_EDGES(_turf) \
	for (var/_direction in GLOB.cardinals) { \
		var/turf/_adjacent_turf = get_step(_turf, _direction); \
		_adjacent_turf.liquid_group?.update_edges(_adjacent_turf); \
	}; \

/// Queues '_recessive_group' to combine with '_dominant_group' or whatever it's combining with. Also avoid queueing a combine with ourselves or into a group that is already queued to combine with us.
#define LIQUID_QUEUE_COMBINE(_recessive_group, _dominant_group) if (_recessive_group != _dominant_group && GLOB.liquid_combine_queue[_dominant_group] != _recessive_group) { GLOB.liquid_combine_queue[_recessive_group] ||= GLOB.liquid_combine_queue[_dominant_group] || _dominant_group }

/// Queues the given liquid group for a DFS split check by SSliquid_spread.
/// This is infamously expensive. Avoid splits whenever possible. They SUCK to do.
#define LIQUID_QUEUE_SPLIT(_liquid_group) GLOB.liquid_split_queue[_liquid_group] = TRUE

// Global Lists //
/// Contains all active liquid groups. This is a simple list.
GLOBAL_LIST_INIT(liquid_groups, list())
/// Contains all active liquid groups waiting for SSliquid_spread to combine them.
/// This is an associative list with a format of "liquid_combine_queue[recessive_turf] = dominant_turf"
GLOBAL_LIST_INIT(liquid_combine_queue, list())
/// Contains all active liquid groups waiting for SSliquid_spread to split them.
/// This is an associative list with a format of "liquid_split_queue[liquid_group] = TRUE"
GLOBAL_LIST_INIT(liquid_split_queue, list())
