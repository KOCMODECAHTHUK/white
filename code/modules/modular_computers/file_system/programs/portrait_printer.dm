
///how much paper it takes from the printer to create a canvas.
#define CANVAS_PAPER_COST 10


/**
 * ## portrait printer!
 *
 * Program that lets the curator browse all of the portraits in the database
 * They are free to print them out as they please.
 */
/datum/computer_file/program/portrait_printer
	filename = "PortraitPrinter"
	filedesc = "Картины Марлоу Треби"
	category = PROGRAM_CATEGORY_CREW
	program_icon_state = "dummy"
	extended_desc = "Эта программа подключается к художественному сайту сообщества, находящегося в секторе Спинвард, для просмотра и печати произведений искусства."
	transfer_access = list(ACCESS_LIBRARY)
	usage_flags = PROGRAM_CONSOLE
	requires_ntnet = TRUE
	size = 9
	tgui_id = "NtosPortraitPrinter"
	program_icon = "paint-brush"
	/**
	* The last input in the search tab, stored here and reused in the UI to show successive users if
	* the current list of paintings is limited to the results of a search or not.
	*/
	var/search_string
	/// Whether the search function will check the title of the painting or the author's name.
	var/search_mode = PAINTINGS_FILTER_SEARCH_TITLE
	/// Stores the result of the search, for later access.
	var/list/matching_paintings

/datum/computer_file/program/portrait_printer/ui_data(mob/user)
	var/list/data = list()
	data["paintings"] = matching_paintings || SSpersistent_paintings.painting_ui_data()
	data["search_string"] = search_string
	data["search_mode"] = search_mode == PAINTINGS_FILTER_SEARCH_TITLE ? "Title" : "Author"
	return data

/datum/computer_file/program/portrait_printer/ui_assets(mob/user)
	return list(
		get_asset_datum(/datum/asset/simple/portraits)
	)

/datum/computer_file/program/portrait_printer/ui_act(action, params)
	. = ..()
	if(.)
		return
	switch(action)
		if("search")
			if(search_string != params["to_search"])
				search_string = params["to_search"]
				generate_matching_paintings_list()
			. = TRUE
		if("change_search_mode")
			search_mode = search_mode == PAINTINGS_FILTER_SEARCH_TITLE ? PAINTINGS_FILTER_SEARCH_CREATOR : PAINTINGS_FILTER_SEARCH_TITLE
			generate_matching_paintings_list()
			. = TRUE
		if("select")
			print_painting(params["selected"])

/datum/computer_file/program/portrait_printer/proc/generate_matching_paintings_list()
	matching_paintings = null
	if(!search_string)
		return
	matching_paintings = SSpersistent_paintings.painting_ui_data(filter = search_mode, search_text = search_string)

/datum/computer_file/program/portrait_printer/proc/print_painting(selected_painting)
	if(computer.stored_paper < CANVAS_PAPER_COST)
		to_chat(usr, span_notice("Ошибка печати: Вашему принтеру требуется не менее [CANVAS_PAPER_COST] листов бумаги для печати картины."))
		return
	computer.stored_paper -= CANVAS_PAPER_COST

	//canvas printing!
	var/datum/painting/chosen_portrait = locate(selected_painting) in SSpersistent_paintings.paintings

	var/png = "data/paintings/images/[chosen_portrait.md5].png"
	var/icon/art_icon = new(png)
	var/obj/item/canvas/printed_canvas
	var/art_width = art_icon.Width()
	var/art_height = art_icon.Height()
	for(var/canvas_type in typesof(/obj/item/canvas))
		printed_canvas = canvas_type
		if(initial(printed_canvas.width) == art_width && initial(printed_canvas.height) == art_height)
			printed_canvas = new canvas_type(get_turf(computer.physical))
			break
		printed_canvas = null
	if(!printed_canvas)
		return
	printed_canvas.painting_metadata = chosen_portrait
	printed_canvas.fill_grid_from_icon(art_icon)
	printed_canvas.generated_icon = art_icon
	printed_canvas.icon_generated = TRUE
	printed_canvas.finalized = TRUE
	printed_canvas.name = "картина - [chosen_portrait.title]"
	///this is a copy of something that is already in the database- it should not be able to be saved.
	printed_canvas.no_save = TRUE
	printed_canvas.update_icon()
	to_chat(usr, span_notice("Печатаю [chosen_portrait.title] на новом холсте."))
	playsound(computer.physical, 'sound/items/poster_being_created.ogg', 100, TRUE)

#undef CANVAS_PAPER_COST
