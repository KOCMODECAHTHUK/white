/datum/buildmode_mode/area_edit
	key = "areaedit"
	use_corner_selection = TRUE
	var/area/storedarea
	var/image/areaimage

/datum/buildmode_mode/area_edit/New()
	areaimage = image('icons/turf/areas.dmi', null, "yellow")
	..()

/datum/buildmode_mode/area_edit/enter_mode(datum/buildmode/BM)
	BM.holder.images += areaimage

/datum/buildmode_mode/area_edit/exit_mode(datum/buildmode/BM)
	areaimage.loc = null // de-color the area
	BM.holder.images -= areaimage
	return ..()

/datum/buildmode_mode/area_edit/Destroy()
	QDEL_NULL(areaimage)
	storedarea = null
	return ..()

/datum/buildmode_mode/area_edit/show_help(client/c)
	to_chat(c, span_notice("***********************************************************"))
	to_chat(c, span_notice("Left Mouse Button on obj/turf/mob = Select corner"))
	to_chat(c, "<span class='notice'>Left Mouse Button + Alt on turf/obj/mob = Paint area/span>")
	to_chat(c, span_notice("Right Mouse Button on obj/turf/mob = Select area to paint"))
	to_chat(c, span_notice("Right Mouse Button on buildmode button = Create new area"))
	to_chat(c, span_notice("***********************************************************"))

/datum/buildmode_mode/area_edit/change_settings(client/c)
	var/target_path = tgui_input_text(c, "Enter typepath:", "Typepath", "/area")
	var/areatype = text2path(target_path)
	if(ispath(areatype,/area))
		var/areaname = tgui_input_text(c, "Enter area name:", "Area name", "Area")
		if(!areaname || !length(areaname))
			return
		storedarea = new areatype
		storedarea.power_equip = 0
		storedarea.power_light = 0
		storedarea.power_environ = 0
		storedarea.always_unpowered = 0
		storedarea.name = areaname
		areaimage.loc = storedarea // color our area

/datum/buildmode_mode/area_edit/handle_click(client/c, params, object)
	var/list/pa = params2list(params)
	var/left_click = pa.Find("left")
	var/right_click = pa.Find("right")
	var/alt_click = pa.Find("alt")

	if(left_click)
		if(!storedarea)
			to_chat(c, span_warning("Configure or select the area you want to paint first!"))
			return
		if(alt_click)
			var/turf/T = get_turf(object)
			if(get_area(T) != storedarea)
				log_admin("Build Mode: [key_name(c)] added [AREACOORD(T)] to [storedarea]")
				storedarea.contents.Add(T)
			return
		return ..()
	else if(right_click)
		var/turf/T = get_turf(object)
		storedarea = get_area(T)
		areaimage.loc = storedarea // color our area

/datum/buildmode_mode/area_edit/handle_selected_area(client/c, params)
	var/list/pa = params2list(params)
	var/left_click = pa.Find("left")

	if(left_click)
		var/choice = tgui_alert(usr, "Are you sure you want to fill area?", "Area Fill Confirmation", list("Yes", "No"))
		if(choice != "Yes")
			return
		for(var/turf/T in block(get_turf(cornerA),get_turf(cornerB)))
			storedarea.contents.Add(T)
		log_admin("Build Mode: [key_name(c)] set the area of the region from [AREACOORD(cornerA)] through [AREACOORD(cornerB)] to [storedarea].")

