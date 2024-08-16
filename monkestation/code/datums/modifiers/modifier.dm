/// Dynamic value for source-based multipliers and increments.
/// Should be performant enough for 90% of applications.
/datum/modifier
	VAR_PRIVATE/base_value = 1

	/// Operation order. Refer to defines.
	VAR_PRIVATE/order = MODIFIER_ORDER_INCREMENT_FIRST

	/// Lazylist of multiplicatives.
	VAR_PRIVATE/list/multiplicative
	/// Lazylist of additives.
	VAR_PRIVATE/list/additive

	VAR_PRIVATE/cached_multiplier
	VAR_PRIVATE/cached_increment
	VAR_PRIVATE/cached_value

/datum/modifier/New(base_value = 1, order = MODIFIER_ORDER_INCREMENT_FIRST)
	src.base_value = base_value
	src.order = order
	cached_value = base_value

/// Sets the base value.
/datum/modifier/proc/set_base_value(value)
	if(base_value == value)
		return
	base_value = value
	decache_value()

/// Gets the base value.
/datum/modifier/proc/get_base_value()
	return base_value

/// Sets the value of a multiplicative.
/datum/modifier/proc/set_multiplicative(source, value)
	if(get_multiplicative(source) == value)
		return
	if(value == 1)
		clear_multiplicative(source)
	multiplicative[source] = value
	cached_multiplier = null
	decache_value()

/// Gets the value of a multiplicative. Defaults to 1.
/datum/modifier/proc/get_multiplicative(source)
	var/value = multiplicative[source]
	return isnull(value) ? 1 : value

/// Clears the value of a multiplicative.
/datum/modifier/proc/clear_multiplicative(source)
	if(!multiplicative[source])
		return
	multiplicative -= source
	cached_multiplier = null
	decache_value()

/// Sets the value of an additive.
/datum/modifier/proc/set_additive(source, value)
	if(get_additive(source) == value)
		return
	if(value == 0)
		clear_additive(source)
	additive[source] = value
	cached_increment = null
	decache_value()

/// Gets the value of an additive. Defaults to 0.
/datum/modifier/proc/get_additive(source)
	var/value = additive[source]
	return isnull(value) ? 0 : value

/// Clears the value of an additive.
/datum/modifier/proc/clear_additive(source)
	if(!additive[source])
		return
	additive -= source
	cached_increment = null
	decache_value()

/// Returns the final multiplier.
/datum/modifier/proc/get_multiplier()
	if(isnull(cached_multiplier))
		update_multiplier()
	return cached_multiplier

/// Updates the cached multiplier. Done automatically.
/datum/modifier/proc/update_multiplier()
	var/value = 1
	for(var/multiplier as anything in multiplicative)
		value *= multiplier
	cached_multiplier = value

/// Returns the final increment.
/datum/modifier/proc/get_increment()
	if(isnull(cached_increment))
		update_increment()
	return cached_increment

/// Updates the cached increment. Done automatically.
/datum/modifier/proc/update_increment()
	var/value = 0
	for(var/increment as anything in additive)
		value += increment
	cached_increment = value

/// Returns the final value.
/datum/modifier/proc/get_value()
	if(isnull(cached_value))
		update_value()
	return cached_value

/// Updates the cached value. Done automatically.
/datum/modifier/proc/update_value()
	var/value = base_value

	if(order == MODIFIER_ORDER_INCREMENT_FIRST)
		value += get_increment()
		value *= get_multiplier()
	else
		value *= get_multiplier()
		value += get_increment()

	cached_value = value

/// Invalidates the cached value. Done automatically.
/datum/modifier/proc/decache_value()
	PRIVATE_PROC(TRUE)

	var/old_value = cached_value
	cached_value = null

	SEND_SIGNAL(src, COMSIG_MODIFIER_VALUE_CHANGED, old_value)
