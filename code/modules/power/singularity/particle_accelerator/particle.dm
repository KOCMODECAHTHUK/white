/obj/effect/accelerated_particle
	name = "ускоренные частицы"
	desc = "Мелкие вещи движущиеся очень быстро."
	icon = 'icons/obj/machines/particle_accelerator.dmi'
	icon_state = "particle"
	anchored = TRUE
	density = FALSE
	var/movement_range = 20
	var/energy = 10
	var/speed = 1

/obj/effect/accelerated_particle/weak
	movement_range = 8
	energy = 5

/obj/effect/accelerated_particle/strong
	movement_range = 15
	energy = 15

/obj/effect/accelerated_particle/powerful
	movement_range = 20
	energy = 50


/obj/effect/accelerated_particle/New(loc)
	..()

	addtimer(CALLBACK(src, PROC_REF(move)), 1)

	var/static/list/loc_connections = list(
		COMSIG_ATOM_ENTERED = PROC_REF(on_entered),
	)
	AddElement(/datum/element/connect_loc, loc_connections)

/obj/effect/accelerated_particle/Bump(atom/A)
	if(A)
		if(isliving(A))
			toxmob(A)
		else if(istype(A, /obj/machinery/the_singularitygen))
			var/obj/machinery/the_singularitygen/S = A
			S.energy += energy
		else if(istype(A, /obj/singularity))
			var/obj/singularity/S = A
			S.energy += energy
		else if(istype(A, /obj/structure/blob))
			var/obj/structure/blob/B = A
			B.take_damage(energy*0.6)
			movement_range = 0

/obj/effect/accelerated_particle/proc/on_entered(datum/source, atom/movable/AM)
	SIGNAL_HANDLER
	if(isliving(AM))
		toxmob(AM)

/obj/effect/accelerated_particle/ex_act(severity, target)
	qdel(src)

/obj/effect/accelerated_particle/singularity_pull()
	return

/obj/effect/accelerated_particle/proc/toxmob(mob/living/M)
	M.rad_act(energy*6)

/obj/effect/accelerated_particle/proc/move()
	if(!step(src,dir))
		forceMove(get_step(src,dir))
	movement_range--
	if(movement_range == 0)
		qdel(src)
	else
		sleep(speed)
		move()
