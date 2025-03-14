//GUNCASES//
/obj/structure/guncase
	name = "шкаф с оружием"
	desc = "Хранит стволы в безопасности."
	icon = 'icons/obj/closet.dmi'
	icon_state = "shotguncase"
	anchored = FALSE
	density = TRUE
	opacity = FALSE
	var/case_type = ""
	var/gun_category = /obj/item/gun
	var/open = TRUE
	var/capacity = 4

/obj/structure/guncase/Initialize(mapload)
	. = ..()
	if(mapload)
		for(var/obj/item/I in loc.contents)
			if(istype(I, gun_category))
				I.forceMove(src)
			if(contents.len >= capacity)
				break
	update_icon()

/obj/structure/guncase/update_overlays()
	. = ..()
	if(case_type && LAZYLEN(contents))
		var/mutable_appearance/gun_overlay = mutable_appearance(icon, case_type)
		for(var/i in 1 to contents.len)
			gun_overlay.pixel_x = 3 * (i - 1)
			. += new /mutable_appearance(gun_overlay)
	if(open)
		. += "[icon_state]_open"
	else
		. += "[icon_state]_door"

/obj/structure/guncase/attackby(obj/item/I, mob/user, params)
	if(iscyborg(user) || isalien(user))
		return
	if(istype(I, gun_category) && open)
		if(LAZYLEN(contents) < capacity)
			if(!user.transferItemToLoc(I, src))
				return
			to_chat(user, span_notice("Убираю [I.name] в [src.name]."))
			update_icon()
		else
			to_chat(user, span_warning("[capitalize(src.name)] переполнен."))
		return

	else if(user.a_intent != INTENT_HARM)
		open = !open
		update_icon()
	else
		return ..()

/obj/structure/guncase/attack_hand(mob/user)
	. = ..()
	if(.)
		return
	if(iscyborg(user) || isalien(user))
		return
	if(contents.len && open)
		show_menu(user)
	else
		open = !open
		update_icon()

/**
 * show_menu: Shows a radial menu to a user consisting of an available weaponry for taking
 *
 * Arguments:
 * * user The mob to which we are showing the radial menu
 */
/obj/structure/guncase/proc/show_menu(mob/user)
	if(!LAZYLEN(contents))
		return

	var/list/display_names = list()
	var/list/items = list()
	for(var/i in 1 to length(contents))
		var/obj/item/thing = contents[i]
		display_names["[thing.name] ([i])"] = REF(thing)
		var/image/item_image = image(icon = thing.icon, icon_state = thing.icon_state)
		if(length(thing.overlays))
			item_image.copy_overlays(thing)
		items += list("[thing.name] ([i])" = item_image)

	var/pick = show_radial_menu(user, src, items, custom_check = CALLBACK(src, PROC_REF(check_menu), user), radius = 36, require_near = TRUE)
	if(!pick)
		return

	var/weapon_reference = display_names[pick]
	var/obj/item/weapon = locate(weapon_reference) in contents
	if(!istype(weapon))
		return
	if(!user.put_in_hands(weapon))
		weapon.forceMove(get_turf(src))
	update_icon()

/**
 * check_menu: Checks if we are allowed to interact with a radial menu
 *
 * Arguments:
 * * user The mob interacting with a menu
 */
/obj/structure/guncase/proc/check_menu(mob/living/carbon/human/user)
	if(!open)
		return FALSE
	if(!istype(user))
		return FALSE
	if(user.incapacitated())
		return FALSE
	return TRUE

/obj/structure/guncase/handle_atom_del(atom/A)
	update_icon()

/obj/structure/guncase/contents_explosion(severity, target)
	for(var/thing in contents)
		switch(severity)
			if(EXPLODE_DEVASTATE)
				SSexplosions.high_mov_atom += thing
			if(EXPLODE_HEAVY)
				SSexplosions.med_mov_atom += thing
			if(EXPLODE_LIGHT)
				SSexplosions.low_mov_atom += thing

/obj/structure/guncase/shotgun
	name = "шкаф с дробовиками"
	desc = "Шкаф, который хранит дробовики."
	case_type = "shotgun"
	gun_category = /obj/item/gun/ballistic/shotgun

/obj/structure/guncase/ecase
	name = "шкаф с е-ганами"
	desc = "Шкаф, который хранит энергетические винтовки."
	icon_state = "ecase"
	case_type = "egun"
	gun_category = /obj/item/gun/energy/e_gun
