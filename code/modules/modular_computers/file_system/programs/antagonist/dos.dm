/datum/computer_file/program/ntnet_dos
	filename = "ntn_dos"
	filedesc = "Генератор ДДОС Трафика"
	category = PROGRAM_CATEGORY_MISC
	program_icon_state = "hostile"
	extended_desc = "Этот продвинутая программа может выполнять ДДОС атаки против квантовых реле сети НТ. Вмешательство в систему, вероятно, будет замечено системным администратором. Несколько устройств могут запускать эту программу вместе против одного и того же реле для усиления эффекта."
	size = 20
	requires_ntnet = TRUE
	available_on_ntnet = FALSE
	available_on_syndinet = TRUE
	tgui_id = "NtosNetDos"
	program_icon = "satellite-dish"

	var/obj/machinery/ntnet_relay/target = null
	var/dos_speed = 0
	var/error = ""
	var/executed = 0

/datum/computer_file/program/ntnet_dos/process_tick(delta_time)
	dos_speed = 0
	switch(ntnet_status)
		if(1)
			dos_speed = NTNETSPEED_LOWSIGNAL * 10
		if(2)
			dos_speed = NTNETSPEED_HIGHSIGNAL * 10
		if(3)
			dos_speed = NTNETSPEED_ETHERNET * 10
	if(target && executed)
		target.dos_overload += dos_speed
		if(!target.is_operational)
			target.dos_sources.Remove(src)
			target = null
			error = "Подключение к реле потеряно."

/datum/computer_file/program/ntnet_dos/kill_program(forced = FALSE)
	if(target)
		target.dos_sources.Remove(src)
	target = null
	executed = FALSE

	..()

/datum/computer_file/program/ntnet_dos/ui_act(action, params)
	. = ..()
	if(.)
		return
	switch(action)
		if("PRG_target_relay")
			for(var/obj/machinery/ntnet_relay/R in SSnetworks.relays)
				if(R.uid == params["targid"])
					target = R
					break
			return TRUE
		if("PRG_reset")
			if(target)
				target.dos_sources.Remove(src)
				target = null
			executed = FALSE
			error = ""
			return TRUE
		if("PRG_execute")
			if(target)
				executed = TRUE
				target.dos_sources.Add(src)
				if(SSnetworks.station_network.intrusion_detection_enabled)
					SSnetworks.add_log("ТРЕВОГА - Зарегистрирована ДДОС атака на реле [target.uid] исходящее из устройства: [computer.name]")
					SSnetworks.station_network.intrusion_detection_alarm = TRUE
			return TRUE

/datum/computer_file/program/ntnet_dos/ui_data(mob/user)
	if(!SSnetworks.station_network)
		return

	var/list/data = get_header_data()

	data["error"] = error
	if(target && executed)
		data["target"] = TRUE
		data["speed"] = dos_speed

		data["overload"] = target.dos_overload
		data["capacity"] = target.dos_capacity
	else
		data["target"] = FALSE
		data["relays"] = list()
		for(var/obj/machinery/ntnet_relay/R in SSnetworks.relays)
			data["relays"] += list(list("id" = R.uid))
		data["focus"] = target ? target.uid : null

	return data
