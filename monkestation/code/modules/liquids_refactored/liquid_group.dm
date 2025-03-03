/datum/liquid_group
	/// Associative list of all turfs in this liquid group.
	/// Format is "turfs[turf] = TRUE"
	var/list/turfs = list()

	/// Associative list of all cardinal edge turfs, including ones that can't spread anywhere. (turf = TRUE)
	/// Separate from the directions list so process_spread() doesn't do a 10000-unit for-each loop.
	/// Necessary for splitting turfs and such.
	var/list/edge_turfs = list()

	/// Associative list of all edge turfs in this liquid group. (turf = list of spread directions)
	/// From tests I've ran, this is currently the fastest way to handle liquid spread by far.
	var/list/edge_turf_spread_directions = list()

	/// The total number of spreads we're going to try on the next spread() call.
	/// You absolutely have to keep this in sync with edge_turf_spread_directions, else shit breaks.
	var/next_spread_count = 0

	/// Holder for all reagents in this liquid group.
	var/datum/reagents/reagents

	var/static/list/reagent_signals = list(
		COMSIG_REAGENTS_ADD_REAGENT,
		COMSIG_REAGENTS_REM_REAGENT,
		COMSIG_REAGENTS_NEW_REAGENT,
		COMSIG_REAGENTS_DEL_REAGENT,
	)

	/// Cached value of reagents.chem_temp from the last time reagent state was updated.
	/// Updated to the value of reagents.chem_temp if it differs by at least 1 degree in update_reagent_state()
	var/last_reagents_temperature = 0

	/// Used for seeing if the reagent holder has changed contents. (volume and/or types)
	/// Set back to FALSE in update_reagent_state() if it's TRUE.
	var/have_reagents_updated = FALSE

	/// Whether SSliquid_processing should call handle_reactions() on the next process.
	/// Set back to FALSE in SSliquid_processing.fire() if it's TRUE.
	var/handle_reactions_next_process = FALSE

	/// How much maximum volume this liquid group gets per turf.
	/// This is a cached value of LIQUID_GET_TURF_MAXIMUM_VOLUME(initial_turf)
	var/maximum_volume_per_turf = 0

	/// Cached value of length(turfs) that is set whenever update_liquid_state() is called.
	var/last_liquid_state_turf_count = 0

	/// Current liquid state (height level), refer to liquid_defines.dm for details.
	var/liquid_state = LIQUID_STATE_PUDDLE

	/// The precomputed color of the entire liquid group. Does not update immediately.
	var/liquid_color = "#FFFFFF"

	/// Associative list of all movable atoms exposed to this liquid group.
	/// The values are the liquid immersion overlays for the atoms.
	var/list/exposed_atoms = list()

/datum/liquid_group/New(turf/initial_turf) // I'm going to trust YOU to not create empty liquid groups. It's useful in some cases, as long as you're filling out the new one with turfs manually.
	reagents = new(0)
	reagents.flags |= NO_REACT // We handle reactions ourselves once every 2 seconds.

	RegisterSignal(reagents, COMSIG_REAGENTS_ADD_REAGENT, PROC_REF(on_reagent_added))
	RegisterSignal(reagents, COMSIG_REAGENTS_REM_REAGENT, PROC_REF(on_reagent_removed))
	RegisterSignal(reagents, COMSIG_REAGENTS_NEW_REAGENT, PROC_REF(on_reagent_type_added))
	RegisterSignal(reagents, COMSIG_REAGENTS_DEL_REAGENT, PROC_REF(on_reagent_type_removed))

	if (initial_turf)
		maximum_volume_per_turf = LIQUID_GET_TURF_MAXIMUM_VOLUME(initial_turf)
		add_turf(initial_turf)

	GLOB.liquid_groups += src

/datum/liquid_group/Destroy(force)
	GLOB.liquid_groups -= src
	GLOB.liquid_combine_queue -= src
	GLOB.liquid_split_queue -= src

	remove_all_turfs()

	UnregisterSignal(reagents, reagent_signals)

	QDEL_NULL(reagents)

	return ..()

/// Adds a turf to the liquid group.
/// Returns whether adding the turf was successful.
/datum/liquid_group/proc/add_turf(turf/target_turf)
	if (isopenspaceturf(target_turf)) // Needed because a turf could get replaced by openspace.
		var/turf/multiz_turf = try_spread_multiz(target_turf)
		transfer_reagents_to(multiz_turf?.liquid_group, LIQUID_GET_VOLUME_PER_TURF(src))
		return FALSE
	if (!LIQUID_CAN_ENTER_TURF_TYPE(target_turf))
		return FALSE
	if (target_turf.liquid_group)
		CRASH("A liquid group tried to add a turf that is already in a liquid group.")

	turfs[target_turf] = TRUE

	target_turf.liquid_group = src
	target_turf.liquid_effect ||= new(target_turf, src) // This is the only place that should be creating liquid effects.

	update_edges(target_turf) // Has to happen immediately or else spreading/receding will break, splitting will break, etc...
	LIQUID_UPDATE_ADJACENT_EDGES(target_turf) // Same here.

	LIQUID_UPDATE_MAXIMUM_VOLUME(src)

	return TRUE

/// Removes a turf from the liquid group. Does barely any sanity checks.
/// Only use this when you intend to remove turfs without destroying the whole group.
/// If you want to destroy the whole group, then just qdel it instead. (it's way faster)
/datum/liquid_group/proc/remove_turf(turf/target_turf)
	if (!turfs[target_turf])
		CRASH("A liquid group tried to remove a turf that isn't even in it.")

	check_split(target_turf) // Has to happen first, before we update edges or get removed from the turf lists.

	turfs -= target_turf
	edge_turfs -= target_turf

	if (edge_turf_spread_directions[target_turf])
		next_spread_count -= length(edge_turf_spread_directions[target_turf])
		edge_turf_spread_directions -= target_turf

	target_turf.liquid_group = null

	QUEUE_SMOOTH_NEIGHBORS(target_turf.liquid_effect)
	QDEL_NULL(target_turf.liquid_effect) // This is the only place that should be deleting liquid effects.

	LIQUID_UPDATE_ADJACENT_EDGES(target_turf) // Has to happen immediately or else spreading/receding will break, splitting will break, etc...

	LIQUID_UPDATE_MAXIMUM_VOLUME(src)

	if (reagents.total_volume > reagents.maximum_volume) // Total volume should never exceed maximum volume.
		reagents.remove_all(reagents.total_volume - reagents.maximum_volume) // So we obliterate the excess.

/// Removes all turfs from the liquid group. Very very fast.
/// Not perfect and will break smoothing for adjacent liquid groups.
/// But that is the price we pay for faster group combination and splitting.
/// This is guaranteed to destroy the liquid group by the way. So keep that in mind.
/datum/liquid_group/proc/remove_all_turfs()
	for (var/turf/target_turf as anything in turfs)
		QDEL_NULL(target_turf.liquid_effect)
		target_turf.liquid_group = null

	for (var/atom/movable/exposed_atom in exposed_atoms)
		qdel(exposed_atoms[exposed_atom])

	turfs = list()
	edge_turfs = list()
	edge_turf_spread_directions = list()
	next_spread_count = 0
	exposed_atoms = list()

	if (!QDELING(src))
		qdel(src)

/// Updates all edge lists for the given turf.
/// Can also initiate a combination, so be careful.
/datum/liquid_group/proc/update_edges(turf/target_turf)
	var/list/spread_directions = list() // Only used for marking edge turfs that can spread and where they can spread.
	var/is_edge_turf = FALSE // Exists because splitting uses edge turfs as well. (and needs non-spreading edge turfs marked as well!)

	next_spread_count -= length(edge_turf_spread_directions[target_turf])

	for (var/direction in GLOB.cardinals)
		var/turf/adjacent_turf = get_step(target_turf, direction)

		if (turfs[adjacent_turf])
			continue
		if (QDELETED(adjacent_turf) || !TURFS_CAN_SHARE(target_turf, adjacent_turf))
			is_edge_turf = TRUE
		else if (!adjacent_turf.liquid_group)
			spread_directions += direction
			next_spread_count++
			is_edge_turf = TRUE
		else // We don't set this as an edge when combining. This is because combination does not update edges and happens instantly after this. (so act as if we already combined)
			LIQUID_QUEUE_COMBINE(target_turf)

	if (length(spread_directions))
		edge_turf_spread_directions[target_turf] = spread_directions
	else
		edge_turf_spread_directions -= target_turf

	if (is_edge_turf)
		edge_turfs[target_turf] = TRUE
	else
		edge_turfs -= target_turf

/// Checks whether removing the given turf could cause a split.
/// If so, queues a full split for SSliquid_spread to handle.
/datum/liquid_group/proc/check_split(turf/target_turf)
	if (!edge_turfs[target_turf])
		var/is_adjacent_to_edge = FALSE // Don't try to cache this into diagonal_edge_turfs or whatever, I tried. And the game HARD CRASHED FOR INEXPLICABLE REASONS. IT'S CURSED.
		for (var/direction in GLOB.cardinals)
			if (edge_turfs[get_step(target_turf, direction)]) // If the target turf is not a cardinal edge, but it's adjacent to one, then it's a diagonal edge.
				is_adjacent_to_edge = TRUE
				break
		if (!is_adjacent_to_edge) // If it's not a cardinal or diagonal edge, then it can't possibly split the group.
			return

	// Okay, this could cause a split, but we're not going to give up that easily.
	// Instead of immediately queuing a full DFT, we're going to do a localized DFS first.
	// This is to check if all turfs in this liquid group cardinally adjacent to us remain connected to each other.
	// Because if they don't, then we're going to have to resort to a full DFT. But we're gonna try to stave it off.

	var/list/cardinal_liquid_turfs = list() // Associative list of all turfs in this liquid group that are cardinally adjacent to us, used for the DFT checks. (adjacent_liquid_turfs[turf] = has_not_been_visited)

	for (var/direction in GLOB.cardinals) // First the cardinals, for the upcoming check.
		var/turf/adjacent_turf = get_step(target_turf, direction)
		if (turfs[adjacent_turf])
			cardinal_liquid_turfs[adjacent_turf] = TRUE // TRUE = has not been visited

	if (length(cardinal_liquid_turfs) <= 1) // If we only have one adjacent cardinal, then removing us can't cause a split. (nothing is depending on us for a connection)
		return

	var/list/diagonal_liquid_turfs = list() // Associative list of all turfs in this liquid group that are diagonally adjacent to us, used for the DFT checks. (adjacent_liquid_turfs[turf] = has_not_been_visited)

	for (var/direction in GLOB.diagonals) // And now the diagonals get to join in.
		var/turf/adjacent_turf = get_step(target_turf, direction)
		if (turfs[adjacent_turf])
			diagonal_liquid_turfs[adjacent_turf] = TRUE // TRUE = has not been visited

	var/list/turf_stack = list(cardinal_liquid_turfs[1]) // List of turfs to propagate from on the next DFS (Depth-First Search) iteration. Start from a cardinal.
	var/total_cardinals_visited = 0

	while (length(turf_stack))
		var/turf/current_turf = turf_stack[length(turf_stack)]
		turf_stack.len--

		for (var/direction in GLOB.cardinals)
			var/turf/adjacent_turf = get_step(current_turf, direction)

			if (!adjacent_turf || !TURFS_CAN_SHARE(current_turf, adjacent_turf))
				continue

			if (cardinal_liquid_turfs[adjacent_turf]) // Serves a dual purpose, making sure the turf is an adjacent liquid turf and that it hasn't been visited.
				cardinal_liquid_turfs[adjacent_turf] = FALSE // FALSE = has been visited
				turf_stack += adjacent_turf
				total_cardinals_visited++

				if (total_cardinals_visited >= length(cardinal_liquid_turfs))
					return // All cardinals visited, removing us can't cause a split.
			else if (diagonal_liquid_turfs[adjacent_turf])
				diagonal_liquid_turfs[adjacent_turf] = FALSE
				turf_stack += adjacent_turf

	LIQUID_QUEUE_SPLIT(src) // Welp, we have to eat the full cost of a group-wide DFT.

/// Spreads the liquid group out by one turf at its edges.
/datum/liquid_group/proc/spread(seconds_per_tick)
	// Estimation of how much we'll have after we're done spreading.
	// Not fully accurate since spreads can fail, mainly inter-group ones.
	var/liquid_per_turf = reagents.total_volume / (length(turfs) + next_spread_count)

	// The number of times we tried to spread into space.
	// Done this way because remove_all() costs a good bit of CPU.
	var/total_space_spreads = 0

	// Associative list of other liquid groups to the turfs in those liquid groups we've spread to. (liquid group = inter-group turfs we've spread to)
	// Done this way to avoid duplicating liquid splash effects and reagent transfer costs.
	var/list/inter_group_transfers = list()

	// Whether we cause a liquid splash effect and push objects back when spreading.
	var/cause_currents = liquid_per_turf >= LIQUID_CURRENTS_VOLUME_THRESHOLD
	var/currents_glide_size = DELAY_TO_GLIDE_SIZE(seconds_per_tick SECONDS)

	// Associative list of edge turfs to what directions they'll push things towards.
	var/currents_directions = cause_currents ? get_currents_directions() : list()

	for (var/turf/edge_turf as anything in edge_turf_spread_directions)
		for (var/direction in edge_turf_spread_directions[edge_turf])
			var/turf/adjacent_turf = get_step(edge_turf, direction)

			if (isspaceturf(adjacent_turf))
				total_space_spreads++
			else if (isopenspaceturf(adjacent_turf)) // NEVER LET LIQUID ACTUALLY SPREAD ON OPENSPACE IT OPENS PANDORA'S BOX
				var/turf/multiz_turf = try_spread_multiz(adjacent_turf)
				if (multiz_turf)
					if (inter_group_transfers[multiz_turf.liquid_group])
						inter_group_transfers[multiz_turf.liquid_group] |= multiz_turf // No duplicates please.
					else
						inter_group_transfers[multiz_turf.liquid_group] = list(multiz_turf)
				continue // Multi-z handles liquid splashes later down the line.
			else if (!add_turf(adjacent_turf))
				continue // Mission failed, we'll get em next time.

			if (cause_currents)
				new /obj/effect/temp_visual/liquid_currents(adjacent_turf, liquid_color)

		if (cause_currents)
			var/knockback_direction = currents_directions[edge_turf]
			var/turf/knockback_turf = get_step(edge_turf, knockback_direction)
			for (var/atom/movable/movable as anything in edge_turf)
				if (!movable.anchored && movable.move_resist <= MOVE_FORCE_STRONG)
					movable.Move(knockback_turf, knockback_direction, currents_glide_size)
				if (!isliving(movable))
					continue

				var/mob/living/victim = movable
				if (victim.AmountParalyzed() <= 1 SECOND)
					victim.SetParalyzed(2 SECONDS)
					to_chat(victim, span_danger("You're knocked down by the currents!"))

	for (var/datum/liquid_group/other_group in inter_group_transfers)
		var/list/other_group_turfs = inter_group_transfers[other_group]
		transfer_reagents_to(other_group, liquid_per_turf * length(other_group_turfs))

		if (!cause_currents || locate(/obj/effect/temp_visual/liquid_currents) in other_group_turfs[1]) // Don't duplicate effects, it looks wack and costs performance. Also forcefully keeps the check in sync for the group.
			continue

		for (var/turf/other_group_turf as anything in other_group_turfs)
			new /obj/effect/temp_visual/liquid_currents(other_group_turf, liquid_color)

	if (total_space_spreads)
		reagents.remove_all(total_space_spreads * liquid_per_turf)

/// Tries to spread us downward from the target_turf, assumes it's openspace.
/// Returns the turf below if we were able to do that, it will have a liquid group.
/datum/liquid_group/proc/try_spread_multiz(turf/target_turf)
	var/turf/multiz_turf = GET_TURF_BELOW(target_turf)

	if (multiz_turf?.zPassIn(DOWN) && target_turf.has_gravity() >= STANDARD_GRAVITY)
		if (!multiz_turf.liquid_group)
			new /datum/liquid_group(multiz_turf)
		return multiz_turf

/// Returns an associative list of edge turfs to their spread directions as a combined bitflag.
/// By combined bitflag I mean list(NORTH, SOUTH, EAST) becomes EAST because NORTH and SOUTH cancel out.
/// This works with diagonals too, list(NORTH, EAST) becomes NORTHEAST when passed through this proc.
/datum/liquid_group/proc/get_currents_directions()
	var/list/currents_directions = list()

	for (var/turf/edge_turf as anything in edge_turf_spread_directions)
		var/x = 0
		var/y = 0

		for (var/direction in edge_turf_spread_directions[edge_turf])
			switch (direction) // Tally up all the x and y offsets, we know there are no duplicate directions.
				if (NORTH)
					y++
				if (SOUTH)
					y--
				if (EAST)
					x++
				if (WEST)
					x--

		var/direction = NONE // NORTHEAST for example is just NORTH | EAST so this is fine.
		if (y > 0)
			direction |= NORTH
		else if (y < 0)
			direction |= SOUTH
		if (x > 0)
			direction |= EAST
		else if (x < 0)
			direction |= WEST

		currents_directions[edge_turf] = direction

	return currents_directions

/// Returns the number of turfs that will be evaporated if evaporate_edges() is run right now.
/datum/liquid_group/proc/get_evaporation_turf_count()
	return ceil(length(edge_turfs) * 0.5) // Ceil here because we want to always evaporate at least 1 turf.

/// Returns the number of turfs that won't be evaporated if evaporate_edges() is run right now.
/// Exists because evaporate_edges() actually works backwards from a copy of edge_turfs.
/datum/liquid_group/proc/get_inverse_evaporation_turf_count()
	return floor(length(edge_turfs) * 0.5) // Floor here because get_evaporation_turf_count() uses ceil.

/// Evaporates half of the liquid group's edges.
/datum/liquid_group/proc/evaporate_edges()
	var/list/turfs_to_evaporate = edge_turfs.Copy()
	for (var/i in 1 to get_inverse_evaporation_turf_count())
		turfs_to_evaporate -= pick(turfs_to_evaporate) // Work backwards, gives equal chances to all turfs without producing duplicates.
	for (var/turf/turf_to_evaporate in turfs_to_evaporate)
		remove_turf(turf_to_evaporate)

/// Recedes the liquid group back by one turf at its edges.
/datum/liquid_group/proc/recede()
	for (var/turf/edge_turf as anything in edge_turfs)
		remove_turf(edge_turf)

/datum/liquid_group/proc/update_liquid_state()
	last_liquid_state_turf_count = length(turfs)

	var/cached_liquid_state = liquid_state
	liquid_state = clamp(floor(LIQUID_GET_VOLUME_PER_TURF(src) / LIQUID_VOLUME_PER_STATE), LIQUID_STATE_PUDDLE, LIQUID_STATE_FULLTILE)

	if (cached_liquid_state == liquid_state)
		return

	if (cached_liquid_state == LIQUID_STATE_PUDDLE)
		for (var/turf/target_turf as anything in turfs)
			LIQUID_EFFECT_MAKE_FULLTILE(target_turf.liquid_effect)
	else if (liquid_state == LIQUID_STATE_PUDDLE)
		for (var/turf/target_turf as anything in turfs)
			LIQUID_EFFECT_MAKE_PUDDLE(target_turf.liquid_effect)
		for (var/turf/edge_turf as anything in edge_turfs)
			QUEUE_SMOOTH(edge_turf)
			QUEUE_SMOOTH_NEIGHBORS(edge_turf) // Look. It's not pretty. It's shit. But I can't cache diagonal edge turfs. THE GAME WONT LET ME. IT HARD CRASHES WHEN I TRY. WHAT THE FUCK.

	var/effect_icon_state = "stage[liquid_state]_bottom"
	for (var/atom/movable/exposed_atom in exposed_atoms)
		var/obj/effect/abstract/liquid_immersion/effect = exposed_atoms[exposed_atom]
		effect.icon_state = effect_icon_state

/datum/liquid_group/proc/on_reagent_added()
	SIGNAL_HANDLER
	have_reagents_updated = TRUE
	handle_reactions_next_process = TRUE

/datum/liquid_group/proc/on_reagent_removed() // For some edge cases, 'handle_reactions_next_process' should be set to TRUE here, but it's way too costly.
	SIGNAL_HANDLER
	have_reagents_updated = TRUE

/datum/liquid_group/proc/on_reagent_type_added(datum/source, datum/reagent/reagent)
	SIGNAL_HANDLER
	have_reagents_updated = TRUE
	handle_reactions_next_process = TRUE

/datum/liquid_group/proc/on_reagent_type_removed(datum/source, datum/reagent/reagent) // For some edge cases, 'handle_reactions_next_process' should be set to TRUE here, but it's way too costly.
	SIGNAL_HANDLER
	have_reagents_updated = TRUE

/// Updates things directly reliant on the reagent holder.
/// Ideally don't call this outside of process_spread() it can stop update_liquid_state() from being called.
/// You're free to call both at once though, keep in mind the cost of doing that depending on what you're doing.
/datum/liquid_group/proc/update_reagent_state()
	if (LIQUID_TEMPERATURE_NEEDS_REAGENT_UPDATE(src))
		last_reagents_temperature = reagents.chem_temp
		handle_reactions_next_process = TRUE

	if (!have_reagents_updated)
		return
	have_reagents_updated = FALSE

	var/new_liquid_color = mix_color_from_reagents(reagents.reagent_list)
	if (new_liquid_color != liquid_color)
		liquid_color = new_liquid_color
		for (var/turf/target_turf as anything in turfs)
			target_turf.liquid_effect.color = liquid_color

/datum/liquid_group/proc/copy_reagents_to(datum/liquid_group/other_liquid_group, amount = reagents.total_volume, no_react = TRUE)
	if (!other_liquid_group)
		return 0

	return reagents.copy_to(other_liquid_group.reagents, amount, no_react = no_react)

/datum/liquid_group/proc/transfer_reagents_to(datum/liquid_group/other_liquid_group, amount, no_react = TRUE)
	if (!other_liquid_group)
		return 0

	. = reagents.copy_to(other_liquid_group.reagents, amount, no_react = no_react)

	if (. > 0)
		reagents.remove_all(.)

/// Checks whether the liquid group should exist.
/// Returns whether it should and deletes it automatically if not.
/// You generally don't need to call this, SSliquid_spread will handle it.
/datum/liquid_group/proc/check_should_exist()
	if (!QDELING(src) && length(turfs) && reagents.total_volume > 0)
		return TRUE
	qdel(src)

/datum/liquid_group/proc/add_atom(atom/movable/exposed)
	RegisterSignal(exposed, COMSIG_QDELETING, PROC_REF(remove_atom))

	exposed_atoms[exposed] = new /obj/effect/abstract/liquid_immersion(null, liquid_state)
	exposed.vis_contents += exposed_atoms[exposed]

	ADD_KEEP_TOGETHER(exposed, "liquid immersion")

/datum/liquid_group/proc/remove_atom(atom/movable/exposed)
	UnregisterSignal(exposed, COMSIG_QDELETING)

	qdel(exposed_atoms[exposed])
	exposed_atoms -= exposed

	REMOVE_KEEP_TOGETHER(exposed, "liquid immersion")
