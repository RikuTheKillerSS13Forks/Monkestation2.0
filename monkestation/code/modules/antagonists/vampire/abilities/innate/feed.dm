/datum/action/cooldown/vampire/feed
	. = ..()
	name = "Feed"
	desc = "Drink the blood of a victim, a more aggressive grab drinks directly from the carotid artery, stunning the victim"
	button_icon_state = "absorb_dna"
	life_cost = 0
	cooldown = 1 SECOND
	///if we're currently drinking, used for sanity
	var/is_drinking = FALSE
	var/blood_taken = 0
	///The amount of Blood a target has since our last feed, this loops and lets us not spam alerts of low blood.
	var/warning_target_bloodvol = BLOOD_VOLUME_MAX_LETHAL
	///Reference to the target we've fed off of
	var/datum/weakref/target_ref
	/// Whether the target was alive or not when we started feeding.
	var/started_alive = TRUE
	///Are we feeding with passive grab or not?
	var/silent_feed = TRUE

/datum/action/cooldown/vampire/feed/check_use(mob/living/carbon/owner)
	var/mob/living/carbon/target = owner.pulling
	if(!..())
		return

	if(is_drinking)
		owner.balloon_alert(owner, "already drinking!")
		return

	if(!target || !iscarbon(target))
		owner.balloon_alert(owner, "needs grab!")
		return
	if(owner_grab_state = GRAB_AGGRESSIVE)
		return WRIST_FEED
	if(owner_grab_state = GRAB_AGGRESSIVE)
		return NECK_FEED
	if(owner_grab_state = GRAB_KILL)
		return MESSY_FEED
