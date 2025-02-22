/// The amount of liquid a turf can contain by default.
/// Adjusted by height and possibly other factors.
#define LIQUID_BASE_TURF_MAXIMUM_VOLUME 1000

/// Gets the amount of liquid the given turf can contain.
/// This is the actual value, after adjustments.
#define LIQUID_GET_TURF_MAXIMUM_VOLUME(turf) (max(0, LIQUID_BASE_TURF_MAXIMUM_VOLUME - turf.turf_height * 10))

/// Whether the given turf can hold liquid at all. Assumes it's an open turf.
/// If you try to use this to check whether a non-open turf can hold liquid I'll laugh at you.
#define LIQUID_CAN_ENTER_TURF(turf) (!isopenspaceturf(turf) && !isspaceturf(turf))
