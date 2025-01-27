/datum/action/cooldown/vampire/proc/handle_limb_regen(regen_rate)
	var/brute = user.getBruteLoss()
	var/burn = user.getFireLoss()
	var/toxin = user.getToxLoss()

	if (!brute && !burn && !toxin) // Optimization and also avoids divide-by-zero errors.
		return

	var/brute_healing = min(brute, 2 * regen_rate)
	var/burn_healing = min(burn, 2 * regen_rate)
	var/toxin_healing = min(toxin, regen_rate)

	var/total_healing = brute_healing + burn_healing + toxin_healing

	if (brute_healing)
		brute_healing *= brute_healing / total_healing
		user.adjustBruteLoss(-brute_healing, updating_health = FALSE)
	if (burn_healing)
		burn_healing *= burn_healing / total_healing
		user.adjustFireLoss(-burn_healing, updating_health = FALSE)
	if (toxin_healing)
		toxin_healing *= toxin_healing / total_healing
		user.adjustToxLoss(-toxin_healing, updating_health = FALSE, forced = TRUE)

	user.updatehealth() // We know it healed something.

	return total_healing * 0.02
