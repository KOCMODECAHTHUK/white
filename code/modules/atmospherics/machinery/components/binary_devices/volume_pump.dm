// Every cycle, the pump uses the air in air_in to try and make air_out the perfect pressure.
//
// node1, air1, network1 correspond to input
// node2, air2, network2 correspond to output
//
// Thus, the two variables affect pump operation are set in New():
//   air1.volume
//     This is the volume of gas available to the pump that may be transfered to the output
//   air2.volume
//     Higher quantities of this cause more air to be perfected later
//     but overall network volume is also increased as this increases...

/obj/machinery/atmospherics/components/binary/volume_pump
	icon_state = "volpump_map-3"
	name = "объемный насос"
	desc = "Альтернативный вид насоса - он значительно медленнее обычного газового насоса, однако его главное преимущество в том, что он не ограничен давлением и продолжает закачку до максимального заполнения канистры или системы труб."

	can_unwrench = TRUE
	shift_underlay_only = FALSE

	var/transfer_rate = MAX_TRANSFER_RATE
	var/overclocked = FALSE

	var/frequency = 0
	var/id = null
	var/datum/radio_frequency/radio_connection

	construction_type = /obj/item/pipe/directional
	pipe_state = "volumepump"

/obj/machinery/atmospherics/components/binary/volume_pump/CtrlClick(mob/user)
	if(can_interact(user))
		on = !on
		investigate_log("was turned [on ? "on" : "off"] by [key_name(user)]", INVESTIGATE_ATMOS)
		update_icon()
	return ..()

/obj/machinery/atmospherics/components/binary/volume_pump/AltClick(mob/user)
	if(can_interact(user))
		transfer_rate = MAX_TRANSFER_RATE
		investigate_log("was set to [transfer_rate] L/s by [key_name(user)]", INVESTIGATE_ATMOS)
		to_chat(user, span_notice("Максимально выкручиваю силу потока в [src] на [transfer_rate] Л/с."))
		update_icon()
	return ..()

/obj/machinery/atmospherics/components/binary/volume_pump/Destroy()
	SSradio.remove_object(src,frequency)
	return ..()

/obj/machinery/atmospherics/components/binary/volume_pump/update_icon_nopipes()
	icon_state = on && is_operational ? "volpump_on-[set_overlay_offset(piping_layer)]" : "volpump_off-[set_overlay_offset(piping_layer)]"

/obj/machinery/atmospherics/components/binary/volume_pump/process_atmos()
//	..()
	if(!on || !is_operational)
		return

	var/datum/gas_mixture/air1 = airs[1]
	var/datum/gas_mixture/air2 = airs[2]

// Pump mechanism just won't do anything if the pressure is too high/too low unless you overclock it.

	var/input_starting_pressure = air1.return_pressure()
	var/output_starting_pressure = air2.return_pressure()

	if((input_starting_pressure < 0.01) || ((output_starting_pressure > 9000))&&!overclocked)
		return

	if(overclocked && (output_starting_pressure-input_starting_pressure > 1000))//Overclocked pumps can only force gas a certain amount.
		return

	if(overclocked)//Some of the gas from the mixture leaks to the environment when overclocked
		var/turf/open/T = loc
		if(istype(T))
			var/datum/gas_mixture/leaked = air1.remove_ratio(VOLUME_PUMP_LEAK_AMOUNT)
			T.assume_air(leaked)
			T.air_update_turf()

	var/transfer_ratio = transfer_rate / air1.return_volume()
	air1.transfer_ratio_to(air2,transfer_ratio)

	update_parents()

/obj/machinery/atmospherics/components/binary/volume_pump/examine(mob/user)
	. = ..()
	if(overclocked)
		. += "<hr>Its warning light is on[on ? " and it's spewing gas!" : "."]"

/obj/machinery/atmospherics/components/binary/volume_pump/set_frequency(new_frequency)
	SSradio.remove_object(src, frequency)
	frequency = new_frequency
	if(frequency)
		radio_connection = SSradio.add_object(src, frequency)

/obj/machinery/atmospherics/components/binary/volume_pump/broadcast_status()
	if(!radio_connection)
		return

	var/datum/signal/signal = new(list(
		"tag" = id,
		"device" = "APV",
		"power" = on,
		"transfer_rate" = transfer_rate,
		"sigtype" = "status"
	))
	radio_connection.post_signal(src, signal)

/obj/machinery/atmospherics/components/binary/volume_pump/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "AtmosPump", name)
		ui.open()

/obj/machinery/atmospherics/components/binary/volume_pump/ui_data()
	var/data = list()
	data["on"] = on
	data["rate"] = round(transfer_rate)
	data["max_rate"] = round(MAX_TRANSFER_RATE)
	return data

/obj/machinery/atmospherics/components/binary/volume_pump/atmosinit()
	..()

	set_frequency(frequency)

/obj/machinery/atmospherics/components/binary/volume_pump/ui_act(action, params)
	. = ..()
	if(.)
		return
	switch(action)
		if("power")
			on = !on
			investigate_log("was turned [on ? "on" : "off"] by [key_name(usr)]", INVESTIGATE_ATMOS)
			. = TRUE
		if("rate")
			var/rate = params["rate"]
			if(rate == "max")
				rate = MAX_TRANSFER_RATE
				. = TRUE
			else if(text2num(rate) != null)
				rate = text2num(rate)
				. = TRUE
			if(.)
				transfer_rate = clamp(rate, 0, MAX_TRANSFER_RATE)
				investigate_log("was set to [transfer_rate] L/s by [key_name(usr)]", INVESTIGATE_ATMOS)
	update_icon()

/obj/machinery/atmospherics/components/binary/volume_pump/receive_signal(datum/signal/signal)
	if(!signal.data["tag"] || (signal.data["tag"] != id) || (signal.data["sigtype"]!="command"))
		return

	var/old_on = on //for logging

	if("power" in signal.data)
		on = text2num(signal.data["power"])

	if("power_toggle" in signal.data)
		on = !on

	if("set_transfer_rate" in signal.data)
		var/datum/gas_mixture/air1 = airs[1]
		transfer_rate = clamp(text2num(signal.data["set_transfer_rate"]),0,air1.return_volume())

	if(on != old_on)
		investigate_log("was turned [on ? "on" : "off"] by a remote signal", INVESTIGATE_ATMOS)

	if("status" in signal.data)
		broadcast_status()
		return //do not update_icon

	broadcast_status()
	update_icon()

/obj/machinery/atmospherics/components/binary/volume_pump/can_unwrench(mob/user)
	. = ..()
	if(. && on && is_operational)
		to_chat(user, span_warning("Не могу открутить [src.name], сначала нужно выключить это!"))
		return FALSE

/obj/machinery/atmospherics/components/binary/volume_pump/multitool_act(mob/living/user, obj/item/I)
	if(!overclocked)
		overclocked = TRUE
		to_chat(user, "Помпа начинает скрежетать и выпускать воздух как только ограничитель давления выключается.")
	else
		overclocked = FALSE
		to_chat(user, "Помпа затихает как только я включаю ограничитель давления.")
	return TRUE

// mapping

/obj/machinery/atmospherics/components/binary/volume_pump/layer2
	piping_layer = 2
	icon_state = "volpump_map-2"

/obj/machinery/atmospherics/components/binary/volume_pump/layer2
	piping_layer = 2
	icon_state = "volpump_map-2"

/obj/machinery/atmospherics/components/binary/volume_pump/on
	on = TRUE
	icon_state = "volpump_on_map"

/obj/machinery/atmospherics/components/binary/volume_pump/on/layer2
	piping_layer = 2
	icon_state = "volpump_map-2"

/obj/machinery/atmospherics/components/binary/volume_pump/on/layer4
	piping_layer = 4
	icon_state = "volpump_map-4"
