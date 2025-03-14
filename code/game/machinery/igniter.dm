/obj/machinery/igniter
	name = "igniter"
	desc = "It's useful for igniting plasma."
	icon = 'icons/obj/stationobjs.dmi'
	icon_state = "igniter0"
	plane = FLOOR_PLANE
	max_integrity = 300
	armor = list(MELEE = 50, BULLET = 30, LASER = 70, ENERGY = 50, BOMB = 20, BIO = 0, RAD = 0, FIRE = 100, ACID = 70)
	resistance_flags = FIRE_PROOF
	var/id = null
	var/on = FALSE

/obj/machinery/sparker/directional/north
	dir = SOUTH
	pixel_y = 26

/obj/machinery/sparker/directional/south
	dir = NORTH
	pixel_y = -26

/obj/machinery/sparker/directional/east
	dir = WEST
	pixel_x = 26

/obj/machinery/sparker/directional/west
	dir = EAST
	pixel_x = -26

/obj/machinery/igniter/incinerator_toxmix
	id = INCINERATOR_ORDMIX_IGNITER

/obj/machinery/igniter/incinerator_atmos
	id = INCINERATOR_ATMOS_IGNITER

/obj/machinery/igniter/incinerator_syndicatelava
	id = INCINERATOR_SYNDICATELAVA_IGNITER

/obj/machinery/igniter/on
	on = TRUE
	icon_state = "igniter1"

/obj/machinery/igniter/attack_hand(mob/user)
	. = ..()
	if(.)
		return
	add_fingerprint(user)

	use_power(active_power_usage)
	on = !( on )
	update_icon()

/obj/machinery/igniter/process()	//ugh why is this even in process()?
	if (on && !(machine_stat & NOPOWER) )
		var/turf/location = loc
		if (isturf(location))
			location.hotspot_expose(1000,500,1)
	return 1

/obj/machinery/igniter/Initialize(mapload)
	. = ..()
	icon_state = "igniter[on]"

/obj/machinery/igniter/update_icon_state()
	. = ..()
	if(machine_stat & NOPOWER)
		icon_state = "igniter0"
	else
		icon_state = "igniter[on]"

/obj/machinery/igniter/connect_to_shuttle(obj/docking_port/mobile/port, obj/docking_port/stationary/dock)
	id = "[port.id]_[id]"

// Wall mounted remote-control igniter.

/obj/machinery/sparker
	name = "mounted igniter"
	desc = "A wall-mounted ignition device."
	icon = 'icons/obj/stationobjs.dmi'
	icon_state = "migniter"
	resistance_flags = FIRE_PROOF
	var/id = null
	var/disable = 0
	var/last_spark = 0
	var/datum/effect_system/spark_spread/spark_system

/obj/machinery/sparker/toxmix
	id = INCINERATOR_ORDMIX_IGNITER

/obj/machinery/sparker/Initialize(mapload)
	. = ..()
	spark_system = new /datum/effect_system/spark_spread
	spark_system.set_up(2, 1, src)
	spark_system.attach(src)

/obj/machinery/sparker/Destroy()
	QDEL_NULL(spark_system)
	return ..()

/obj/machinery/sparker/update_icon_state()
	. = ..()
	if(disable)
		icon_state = "[initial(icon_state)]-d"
	else if(powered())
		icon_state = "[initial(icon_state)]"
	else
		icon_state = "[initial(icon_state)]-p"

/obj/machinery/sparker/powered()
	if(disable)
		return FALSE
	return ..()

/obj/machinery/sparker/attackby(obj/item/W, mob/user, params)
	if (W.tool_behaviour == TOOL_SCREWDRIVER)
		add_fingerprint(user)
		disable = !disable
		if (disable)
			user.visible_message(span_notice("[user] disables <b>[src.name]</b>!") , span_notice("You disable the connection to <b>[src.name]</b>."))
		if (!disable)
			user.visible_message(span_notice("[user] reconnects <b>[src.name]</b>!") , span_notice("You fix the connection to <b>[src.name]</b>."))
		update_icon()
	else
		return ..()

/obj/machinery/sparker/attack_ai()
	if (anchored)
		return ignite()
	else
		return

/obj/machinery/sparker/proc/ignite()
	if (!(powered()))
		return

	if ((disable) || (last_spark && world.time < last_spark + 50))
		return


	flick("[initial(icon_state)]-spark", src)
	spark_system.start()
	last_spark = world.time
	use_power(active_power_usage)
	var/turf/location = loc
	if (isturf(location))
		location.hotspot_expose(1000,2500,1)
	return 1

/obj/machinery/sparker/emp_act(severity)
	. = ..()
	if (. & EMP_PROTECT_SELF)
		return
	if(!(machine_stat & (BROKEN|NOPOWER)))
		ignite()
