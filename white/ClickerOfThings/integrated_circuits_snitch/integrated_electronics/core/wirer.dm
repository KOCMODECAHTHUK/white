#define WIRE		"wire"
#define WIRING		"wiring"
#define UNWIRE		"unwire"
#define UNWIRING	"unwiring"

/obj/item/integrated_electronics/wirer
	name = "circuit wirer"
	desc = "It's a small wiring tool, with a wire roll, electric soldering iron, wire cutter, and more in one package. \
	The wires used are generally useful for small electronics, such as circuitboards and breadboards, as opposed to larger wires \
	used for power or data transmission."
	icon = 'icons/obj/assemblies/electronic_tools.dmi'
	icon_state = "wirer-wire"
	flags_1 = CONDUCT_1
	w_class = WEIGHT_CLASS_SMALL
	var/datum/integrated_io/selected_io = null
	var/mode = WIRE

/obj/item/integrated_electronics/wirer/update_icon()
	. = ..()
	icon_state = "wirer-[mode]"

/obj/item/integrated_electronics/wirer/proc/wire(var/datum/integrated_io/io, mob/user)
	if(!io.holder.assembly)
		to_chat(user, span_warning("<b>[capitalize(io.holder)]</b> needs to be secured inside an assembly first."))
		return
	switch(mode)
		if(WIRE)
			selected_io = io
			to_chat(user, span_notice("You attach a data wire to [selected_io.holder] [selected_io.name] data channel."))
			mode = WIRING
			update_icon()
		if(WIRING)
			if(io == selected_io)
				to_chat(user, span_warning("Wiring [selected_io.holder] [selected_io.name] into itself is rather pointless."))
				return
			if(io.io_type != selected_io.io_type)
				to_chat(user, "<span class='warning'>Those two types of channels are incompatible.  The first is a [selected_io.io_type], \
				while the second is a [io.io_type].</span>")
				return
			if(io.holder.assembly && io.holder.assembly != selected_io.holder.assembly)
				to_chat(user, span_warning("Both [io.holder] and [selected_io.holder] need to be inside the same assembly."))
				return
			selected_io.connect_pin(io)

			to_chat(user, span_notice("You connect [selected_io.holder] [selected_io.name] to [io.holder] [io.name]."))
			mode = WIRE
			update_icon()
			selected_io.holder.interact(user) // This is to update the UI.
			selected_io = null

		if(UNWIRE)
			selected_io = io
			if(!io.linked.len)
				to_chat(user, span_warning("There is nothing connected to [selected_io] data channel."))
				selected_io = null
				return
			to_chat(user, span_notice("You prepare to detach a data wire from [selected_io.holder] [selected_io.name] data channel."))
			mode = UNWIRING
			update_icon()
			return

		if(UNWIRING)
			if(io == selected_io)
				to_chat(user, "<span class='warning'>You can't wire a pin into each other, so unwiring [selected_io.holder] from \
				the same pin is rather moot.</span>")
				return
			if(selected_io in io.linked)
				selected_io.disconnect_pin(io)
				to_chat(user, "<span class='notice'>You disconnect [selected_io.holder] [selected_io.name] from \
				<b>[io.holder]</b> [io.name].</span>")
				selected_io.holder.interact(user) // This is to update the UI.
				selected_io = null
				mode = UNWIRE
				update_icon()
			else
				to_chat(user, "<span class='warning'><b>[capitalize(selected_io.holder)]</b> [selected_io.name] and [io.holder] \
				[io.name] are not connected.</span>")
				return

/obj/item/integrated_electronics/wirer/attack_self(mob/user)
	switch(mode)
		if(WIRE)
			mode = UNWIRE
		if(WIRING)
			if(selected_io)
				to_chat(user, span_notice("You decide not to wire the data channel."))
			selected_io = null
			mode = WIRE
		if(UNWIRE)
			mode = WIRE
		if(UNWIRING)
			if(selected_io)
				to_chat(user, span_notice("You decide not to disconnect the data channel."))
			selected_io = null
			mode = UNWIRE
	update_icon()
	to_chat(user, span_notice("You set <b>[src.name]</b> to [mode]."))

#undef WIRE
#undef WIRING
#undef UNWIRE
#undef UNWIRING
