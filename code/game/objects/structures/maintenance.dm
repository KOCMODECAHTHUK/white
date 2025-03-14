/** This structure acts as a source of moisture loving cell lines,
as well as a location where a hidden item can somtimes be retrieved
at the cost of risking a vicious bite.**/
/obj/structure/moisture_trap
	name = "moisture trap"
	desc = "A device installed in order to control moisture in poorly ventilated areas.\nThe stagnant water inside basin seems to produce serious biofouling issues when improperly maintained.\nThis unit in particular seems to be teeming with life!\nWho thought mother Gaia could assert herself so vigoriously in this sterile and desolate place?"
	icon_state = "moisture_trap"
	anchored = TRUE
	density = FALSE
	///This var stores the hidden item that might be able to be retrieved from the trap
	var/obj/item/hidden_item
	///This var determines if there is a chance to recieve a bite when sticking your hand into the water.
	var/critter_infested = TRUE
	var/list/loot = list(
					/obj/item/food/meat/slab/human/mutant/skeleton = 35,
					/obj/item/food/meat/slab/human/mutant/zombie = 15,
					/obj/item/trash/can = 15,
					/obj/item/clothing/head/helmet/skull = 10,
					/obj/item/restraints/handcuffs = 4,
					/obj/item/restraints/handcuffs/cable/red = 1,
					/obj/item/restraints/handcuffs/cable/blue = 1,
					/obj/item/restraints/handcuffs/cable/green = 1,
					/obj/item/restraints/handcuffs/cable/pink = 1,
					/obj/item/restraints/handcuffs/alien = 2,
					/obj/item/coin/bananium = 9,
					/obj/item/kitchen/knife/butcher = 5,
					/obj/item/coin/mythril = 1) //the loot table isn't that great and should probably be improved and expanded later.


/obj/structure/moisture_trap/Initialize(mapload)
	. = ..()
	if(prob(40))
		critter_infested = FALSE
	if(prob(75))
		var/picked_item = pick_weight(loot)
		hidden_item = new picked_item(src)

	var/datum/fish_source/moisture_trap/fish_source = new
	if(prob(50)) // 50% chance there's another item to fish out of there
		var/picked_item = pick_weight(loot)
		fish_source.fish_table[picked_item] = 5
		fish_source.fish_counts[picked_item] = 1;
	AddComponent(/datum/component/fishing_spot, fish_source)

	loot = null
	AddElement(/datum/element/swabable, CELL_LINE_TABLE_MOIST, CELL_VIRUS_TABLE_GENERIC, rand(2,4), 20)

/obj/structure/moisture_trap/Destroy()
	if(hidden_item)
		QDEL_NULL(hidden_item)
	return ..()


///This proc checks if we are able to reach inside the trap to interact with it.
/obj/structure/moisture_trap/proc/CanReachInside(mob/user)
	if(!isliving(user))
		return FALSE
	var/mob/living/living_user = user
	if(living_user.body_position == STANDING_UP && ishuman(living_user)) //I dont think monkeys can crawl on command.
		return FALSE
	return TRUE


/obj/structure/moisture_trap/attack_hand(mob/user)
	. = ..()
	if(iscyborg(user) || isalien(user))
		return
	if(!CanReachInside(user))
		to_chat(user, span_warning("You need to lie down to reach into [src]."))
		return
	to_chat(user, span_notice("You reach down into the cold water of the basin."))
	if(!do_after(user, 2 SECONDS, target = src))
		return
	if(hidden_item)
		user.put_in_hands(hidden_item)
		to_chat(user, span_notice("As you poke around inside [src] you feel the contours of something hidden below the murky waters.</span>\n<span class='nicegreen'>You retrieve [hidden_item] from [src]."))
		hidden_item = null
		return
	if(critter_infested && prob(50) && iscarbon(user))
		var/mob/living/carbon/bite_victim = user
		var/obj/item/bodypart/affecting = bite_victim.get_bodypart("[(user.active_hand_index % 2 == 0) ? "r" : "l" ]_arm")
		if(affecting?.receive_damage(30))

			to_chat(user, span_danger("You feel a sharp as an unseen creature sinks it's [pick("fangs", "beak", "proboscis")] into your arm!"))
			bite_victim.update_damage_overlays()
			playsound(src,'sound/weapons/bite.ogg', 70, TRUE)
			return
	to_chat(user, span_warning("You find nothing of value..."))

/obj/structure/moisture_trap/attackby(obj/item/I, mob/user, params)
	if(iscyborg(user) || isalien(user) || !CanReachInside(user))
		return ..()
	add_fingerprint(user)
	if(istype(I, /obj/item/reagent_containers))
		if(istype(I, /obj/item/food/monkeycube))
			var/obj/item/food/monkeycube/cube = I
			cube.Expand()
			return
		var/obj/item/reagent_containers/reagent_container = I
		if(reagent_container.is_open_container())
			reagent_container.reagents.add_reagent(/datum/reagent/water, min(reagent_container.volume - reagent_container.reagents.total_volume, reagent_container.amount_per_transfer_from_this))
			to_chat(user, span_notice("You fill [reagent_container] from [src]."))
			return
	if(hidden_item)
		to_chat(user, span_warning("There is already something inside [src]."))
		return
	if(!user.transferItemToLoc(I, src))
		to_chat(user, span_warning("<b>[capitalize(I)]</b> is stuck to your hand, you cannot put it in [src]!"))
		return
	hidden_item = I
	to_chat(user, span_notice("You hide [I] inside the basin."))

#define ALTAR_INACTIVE 0
#define ALTAR_STAGEONE 1
#define ALTAR_STAGETWO 2
#define ALTAR_STAGETHREE 3
#define ALTAR_TIME 9.5 SECONDS

/obj/structure/destructible/cult/pants_altar
	name = "strange structure"
	desc = "What is this? Who put it on this station? And why does it emanate <span class='hypnophrase'>strange energy?</span>"
	icon_state = "altar"
	cult_examine_tip = "Even you don't understand the eldritch magic behind this."
	break_message = "<span class='warning'>The structure shatters, leaving only a demonic screech!</span>"
	break_sound = 'sound/magic/demon_dies.ogg'
	light_color = LIGHT_COLOR_BLOOD_MAGIC
	light_range = 2
	use_cooldown_duration = 1 MINUTES
	/// Color of the pants that will come out
	var/pants_color = COLOR_WHITE
	/// Stage of the pants making process
	var/status = ALTAR_INACTIVE

/obj/structure/destructible/cult/pants_altar/attackby(obj/attacking_item, mob/user, params)
	if(istype(attacking_item, /obj/item/melee/cultblade/dagger) && IS_CULTIST(user) && status)
		to_chat(user, "<span class='notice'>[src] is creating something, you can't move it!</span>")
		return
	return ..()

/obj/structure/destructible/cult/pants_altar/attack_hand(mob/living/user, list/modifiers)
	. = ..()
	if(.)
		return
	var/list/altar_options = list(
		"Change Color" = image(icon = 'icons/hud/radial.dmi', icon_state = "radial_recolor"),
		"Create Artefact" = image(icon = 'icons/hud/radial.dmi', icon_state = "radial_create")
	)
	var/altar_result = show_radial_menu(user, src, altar_options, custom_check = CALLBACK(src, PROC_REF(check_menu), user), require_near = TRUE, tooltips = TRUE)
	switch(altar_result)
		if("Change Color")
			var/chosen_color = input(usr, "", "Choose Color", pants_color) as color|null
			if(!isnull(chosen_color) && user.canUseTopic(src, BE_CLOSE))
				pants_color = chosen_color
		if("Create Artefact")
			if(!COOLDOWN_FINISHED(src, use_cooldown_duration))
				to_chat(usr, "<span class='warning'>[src] is not ready to create something new yet...</span>")
				return
			pants_stageone()
	return TRUE

/obj/structure/destructible/cult/pants_altar/update_icon_state()
	. = ..()
	if(!COOLDOWN_FINISHED(src, use_cooldown))
		icon_state = "altar_off"
	else
		icon_state = "altar"

/obj/structure/destructible/cult/pants_altar/update_overlays()
	. = ..()
	var/overlayicon
	switch(status)
		if(ALTAR_INACTIVE)
			return
		if(ALTAR_STAGEONE)
			overlayicon = "altar_pants1"
		if(ALTAR_STAGETWO)
			overlayicon = "altar_pants2"
		if(ALTAR_STAGETHREE)
			overlayicon = "altar_pants3"
	var/mutable_appearance/pants_overlay = mutable_appearance(icon, overlayicon)
	pants_overlay.appearance_flags = RESET_COLOR
	pants_overlay.color = pants_color
	. += pants_overlay

/obj/structure/destructible/cult/pants_altar/proc/pants_stageone()
	status = ALTAR_STAGEONE
	update_icon()
	visible_message("<span class='warning'>[src] starts creating something...</span>")
	playsound(src, 'sound/magic/pantsaltar.ogg', 60)
	addtimer(CALLBACK(src, PROC_REF(pants_stagetwo)), ALTAR_TIME)

/obj/structure/destructible/cult/pants_altar/proc/pants_stagetwo()
	status = ALTAR_STAGETWO
	update_icon()
	visible_message("<span class='warning'>You start feeling nauseous...</span>")
	for(var/mob/living/mob in viewers(7, src))
		mob.blur_eyes(10)
		mob.add_confusion(10)
	addtimer(CALLBACK(src, PROC_REF(pants_stagethree)), ALTAR_TIME)

/obj/structure/destructible/cult/pants_altar/proc/pants_stagethree()
	status = ALTAR_STAGETHREE
	update_icon()
	visible_message("<span class='warning'>You start feeling horrible...</span>")
	for(var/mob/living/mob in viewers(7, src))
		mob.set_dizziness(200)
	addtimer(CALLBACK(src, PROC_REF(pants_create)), ALTAR_TIME)

/obj/structure/destructible/cult/pants_altar/proc/pants_create()
	status = ALTAR_INACTIVE
	update_icon()
	visible_message("<span class='warning'>[src] emits a flash of light and creates... pants?</span>")
	for(var/mob/living/mob in viewers(7, src))
		mob.flash_act()
	var/obj/item/clothing/under/pants/altar/pants = new(get_turf(src))
	pants.add_atom_colour(pants_color, ADMIN_COLOUR_PRIORITY)
	COOLDOWN_START(src, use_cooldown, use_cooldown_duration)
	addtimer(CALLBACK(src, TYPE_PROC_REF(/atom, update_icon)), 1 MINUTES + 0.1 SECONDS)
	update_icon()

/obj/item/clothing/under/pants/altar
	name = "strange pants"
	desc = "A pair of pants. They do not look natural. They smell like fresh blood."
	icon_state = "whitepants"

#undef ALTAR_INACTIVE
#undef ALTAR_STAGEONE
#undef ALTAR_STAGETWO
#undef ALTAR_STAGETHREE
#undef ALTAR_TIME
