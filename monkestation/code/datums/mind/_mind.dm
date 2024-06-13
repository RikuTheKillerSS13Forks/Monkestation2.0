/datum/mind
	/// The crew manifest entry for this crew member, if any.
	var/datum/record/crew/crewfile
	/// The locked manifest entry for this crew member, if any.
	var/datum/record/locked/lockfile

/datum/mind/proc/add_to_manifest(crew = TRUE, locked = FALSE)
	if(crew && !QDELETED(crewfile))
		GLOB.manifest.general |= crewfile
	if(locked && !QDELETED(lockfile))
		GLOB.manifest.locked |= lockfile

/datum/mind/proc/remove_from_manifest(crew = TRUE, locked = FALSE)
	if(crew && !QDELETED(crewfile))
		GLOB.manifest.general -= crewfile
	if(locked && !QDELETED(lockfile))
		GLOB.manifest.locked -= lockfile

/datum/mind/proc/swap_addictions(datum/mind/target)
	var/cached_points = addiction_points
	var/cached_active = active_addictions

	addiction_points = target.addiction_points
	target.addiction_points = cached_points

	active_addictions = target.active_addictions
	target.active_addictions = cached_active
