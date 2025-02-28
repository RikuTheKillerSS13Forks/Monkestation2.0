/// The amount of liquid a turf can contain by default.
/// Adjusted by height and possibly other factors.
#define LIQUID_BASE_TURF_MAXIMUM_VOLUME 1000

/// The amount of reagents per turf a liquid group needs before spreading.
#define LIQUID_SPREAD_VOLUME_THRESHOLD 10

/// The amount of reagents per turf a liquid group needs before causing currents to form when spreading.
#define LIQUID_CURRENTS_VOLUME_THRESHOLD LIQUID_VOLUME_PER_STATE * LIQUID_STATE_ANKLES

/// How quickly liquids evaporate, in units per second.
/// This is then multiplied by the number of turfs in a liquid group.
#define LIQUID_BASE_EVAPORATION_RATE 0.1

/// Gets the amount of liquid the given turf can contain.
/// This is the actual value, after adjustments. Must be consistent for the entire lifespan of the turf.
#define LIQUID_GET_TURF_MAXIMUM_VOLUME(_turf) (max(0, LIQUID_BASE_TURF_MAXIMUM_VOLUME - initial(_turf.turf_height) * 10))

#define LIQUID_GET_VOLUME_PER_TURF(_liquid_group) (length(_liquid_group.turfs) ? _liquid_group.reagents.total_volume / length(_liquid_group.turfs) : 0)

/// Updates the maximum volume of the liquid group based on maximum_volume_per_turf and length(turfs)
#define LIQUID_UPDATE_MAXIMUM_VOLUME(_liquid_group) _liquid_group.reagents.maximum_volume = length(_liquid_group.turfs) * _liquid_group.maximum_volume_per_turf

/// Whether the type of the given turf can hold liquid at all.
#define LIQUID_CAN_ENTER_TURF_TYPE(_turf) (isopenturf(_turf) && !isspaceturf(_turf))

/// Immediately calls liquid_group.update_edges(adjacent_turf) for all adjacent turfs, after doing sanity checks for each of them.
#define LIQUID_UPDATE_ADJACENT_EDGES(_turf) \
	for (var/turf/_adjacent_turf in orange(1, _turf)) { \
		_adjacent_turf?.liquid_group?.update_edges(_adjacent_turf); \
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

// Liquid States //

#define LIQUID_STATE_PUDDLE 0
#define LIQUID_STATE_ANKLES 1
#define LIQUID_STATE_WAIST 2
#define LIQUID_STATE_SHOULDERS 3
#define LIQUID_STATE_FULLTILE 4

#define LIQUID_VOLUME_PER_STATE 100

// Effect Macros //

/// Returns whether the liquid effect is a smoothed puddle or a rectangle.
#define LIQUID_EFFECT_IS_PUDDLE(_liquid_effect) (_liquid_effect.base_icon_state != null)

/// Sets base_icon_state to initial. Does not initiate a smooth.
/// Intended for mass-converting entire liquid groups of effects into puddles.
#define LIQUID_EFFECT_MAKE_PUDDLE(_liquid_effect) \
	_liquid_effect.base_icon_state = initial(_liquid_effect.base_icon_state); \

/// Sets base_icon_state to null and icon_state to "initial(base_icon_state)-255". Does not initiate a smooth.
/// Intended for mass-converting entire liquid groups of effects into fulltiles.
#define LIQUID_EFFECT_MAKE_FULLTILE(_liquid_effect) \
	_liquid_effect.base_icon_state = null; \
	_liquid_effect.icon_state = "[initial(_liquid_effect.base_icon_state)]-255"; \
