//Station Shield
// A chain of satellites encircles the station
// Satellites be actived to generate a shield that will block unorganic matter from passing it.
/datum/station_goal/station_shield
	name = "Станционный щит"
	var/coverage_goal = 5000

/datum/station_goal/station_shield/get_report()
	return {"\nСтанция находится в зоне, заполненной космическим мусором.
		\nУ нас есть прототип системы защиты, которую требуется развернуть, чтобы уменьшить количество аварий, связанных с столкновениями.
		\n
		\nМожно заказать спутники и системы управления в грузовом отсеке.
		"}


/datum/station_goal/station_shield/on_report()
	//Unlock
	var/datum/supply_pack/P = SSshuttle.supply_packs[/datum/supply_pack/engineering/shield_sat]
	P.special_enabled = TRUE

	P = SSshuttle.supply_packs[/datum/supply_pack/engineering/shield_sat_control]
	P.special_enabled = TRUE

/datum/station_goal/station_shield/check_completion()
	if(..())
		return TRUE
	if(get_coverage() >= coverage_goal)
		return TRUE
	return FALSE

/datum/station_goal/proc/get_coverage()
	var/list/coverage = list()
	for(var/obj/machinery/satellite/meteor_shield/A in GLOB.machines)
		if(!A.active || !is_station_level(A.z))
			continue
		coverage |= view(A.kill_range,A)
	return coverage.len

/obj/machinery/computer/sat_control
	name = "Управление щитами"
	desc = "Используется для управления массивом защитных спутников."
	circuit = /obj/item/circuitboard/computer/sat_control
	var/notice

/obj/machinery/computer/sat_control/ui_interact(mob/user, datum/tgui/ui)
	. = ..()
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "SatelliteControl", name)
		ui.open()

/obj/machinery/computer/sat_control/ui_act(action, params)
	. = ..()
	if(.)
		return

	switch(action)
		if("toggle")
			toggle(text2num(params["id"]))
			update_static_data(usr)
			. = TRUE
		if("toggle_all")
			toggle_all()
			update_static_data(usr)
			. = TRUE

/obj/machinery/computer/sat_control/proc/toggle(id)
	for(var/obj/machinery/satellite/S in GLOB.machines)
		if(S.id == id && S.z == z)
			S.toggle()

/obj/machinery/computer/sat_control/proc/toggle_all()
	for(var/obj/machinery/satellite/S in GLOB.machines)
		if(S.z == z)
			S.toggle()

/obj/machinery/computer/sat_control/ui_static_data()
	var/list/data = list()

	data["satellites"] = list()
	for(var/obj/machinery/satellite/S in GLOB.machines)
		if(S.z != z)
			continue
		data["satellites"] += list(list(
			"id" = S.id,
			"active" = S.active,
			"mode" = S.mode
		))
	data["notice"] = notice


	var/datum/station_goal/station_shield/G = locate() in SSticker.mode.station_goals
	if(G)
		data["meteor_shield"] = 1
		data["meteor_shield_coverage"] = G.get_coverage()
		data["meteor_shield_coverage_max"] = G.coverage_goal
	return data


/obj/machinery/satellite
	name = "Повреждённый спутник"
	desc = ""
	icon = 'icons/obj/machines/satellite.dmi'
	icon_state = "sat_inactive"
	anchored = FALSE
	density = TRUE
	use_power = NO_POWER_USE
	var/mode = "NTPROBEV0.8"
	var/active = FALSE
	var/static/gid = 0
	var/id = 0

/obj/machinery/satellite/Initialize(mapload)
	. = ..()
	id = gid++

/obj/machinery/satellite/interact(mob/user)
	toggle(user)

/obj/machinery/satellite/set_anchored(anchorvalue)
	. = ..()
	if(isnull(.))
		return //no need to process if we didn't change anything.
	active = anchorvalue
	if(anchorvalue)
		begin_processing()
		animate(src, pixel_y = 2, time = 10, loop = -1)
	else
		end_processing()
		animate(src, pixel_y = 0, time = 10)
	update_icon()

/obj/machinery/satellite/proc/toggle(mob/user)
	if(!active && !isinspace())
		if(user)
			to_chat(user, span_warning("Активировать [src.name] получится только в космосе."))
		return FALSE
	if(user)
		to_chat(user, span_notice("[active ? "Деактивирую": "Активирую"] [src.name]."))
	set_anchored(!anchored)
	return TRUE

/obj/machinery/satellite/update_icon_state()
	. = ..()
	icon_state = active ? "sat_active" : "sat_inactive"

/obj/machinery/satellite/multitool_act(mob/living/user, obj/item/I)
	..()
	to_chat(user, span_notice("// NTSAT-[id] // Режим: [active ? "РАБОТА" : "ОЖИДАНИЕ"] //[(obj_flags & EMAGGED) ? "DEBUG_MODE //" : ""]"))
	return TRUE

/obj/machinery/satellite/meteor_shield
	name = "Защитный спутник"
	desc = "Противометеоритная защита для всей семьи."
	mode = "M-SHIELD"
	processing_flags = START_PROCESSING_MANUALLY
	subsystem_type = /datum/controller/subsystem/processing/fastprocess
	var/kill_range = 14

/obj/machinery/satellite/meteor_shield/proc/space_los(meteor)
	for(var/turf/T in get_line(src,meteor))
		if(!isspaceturf(T) && !isopenspace(T))
			return FALSE
	return TRUE

/obj/machinery/satellite/meteor_shield/process()
	if(!active)
		return
	for(var/obj/effect/meteor/M in GLOB.meteor_list)
		if(M.z != z)
			continue
		if(get_dist(M,src) > kill_range)
			continue
		if(!(obj_flags & EMAGGED) && space_los(M))
			Beam(get_turf(M),icon_state="sat_beam", time = 5)
			qdel(M)

/obj/machinery/satellite/meteor_shield/toggle(user)
	if(!..(user))
		return FALSE
	if(obj_flags & EMAGGED)
		if(active)
			change_meteor_chance(2)
		else
			change_meteor_chance(0.5)

/obj/machinery/satellite/meteor_shield/proc/change_meteor_chance(mod)
	// Update the weight of all meteor events
	for(var/datum/round_event_control/meteor_wave/meteors in SSevents.control)
		meteors.weight *= mod

/obj/machinery/satellite/meteor_shield/Destroy()
	. = ..()
	if(active && (obj_flags & EMAGGED))
		change_meteor_chance(0.5)

/obj/machinery/satellite/meteor_shield/emag_act(mob/user)
	if(obj_flags & EMAGGED)
		return
	obj_flags |= EMAGGED
	to_chat(user, span_notice("Взламываю защиту и увеличиваю шанс удара метеоритом."))
	if(active)
		change_meteor_chance(2)
