/datum/antagonist/vampire
	var/static/list/innate_crafting_recipes = list(
		/datum/crafting_recipe/meatcoffin,
		/datum/crafting_recipe/metalcoffin,
		/datum/crafting_recipe/securecoffin,
		//datum/crafting_recipe/vassalrack,
		//datum/crafting_recipe/candelabrum,
		//datum/crafting_recipe/bloodthrone,
	)

/datum/antagonist/vampire/proc/teach_recipes()
	for (var/crafting_recipe in innate_crafting_recipes)
		owner.teach_crafting_recipe(crafting_recipe)

/datum/antagonist/vampire/proc/forget_recipes()
	for (var/crafting_recipe in innate_crafting_recipes)
		owner.forget_crafting_recipe(crafting_recipe)
