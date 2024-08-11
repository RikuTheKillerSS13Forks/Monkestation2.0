/datum/antagonist/vampire/proc/set_rank(var/rank_to_set)
	vampire_rank = rank_to_set

/datum/antagonist/vampire/proc/rank_up()
	vampire_rank = ++vampire_rank

/datum/antagonist/vampire/thrall
	var/datum/mob/living/carbon/master_atom = null //should be set when drank dry or on_gain
	starting_rank = 0



/datum/antagonist/vampire/admin_add(datum/mind/new_owner,mob/admin)
	new_owner.add_antag_datum(src)
	message_admins("[key_name_admin(admin)] has turned [key_name_admin(new_owner)] into a vampire.")
	log_admin("[key_name_admin(admin)] has turned [key_name_admin(new_owner)] into a vampire.")

/datum/antagonist/vampire/on_gain()
	. = ..()
	set_rank(starting_rank)
	owner.current.log_message("has been converted into a vampire!", LOG_ATTACK, color="#960000")

/datum/antagonist/vampire/on_removal()
	. = ..()
