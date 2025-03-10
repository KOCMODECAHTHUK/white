// test purposes - Also a lot of fun
/datum/action/cooldown/spell/conjure/summon_ed_swarm
	name = "Dispense Wizard Justice"
	desc = "This spell dispenses wizard justice."

	summon_radius = 3
	summon_type = list(/mob/living/simple_animal/bot/secbot/ed209)
	summon_amount = 10

/datum/action/cooldown/spell/conjure/summon_ed_swarm/post_summon(atom/summoned_object, atom/cast_on)
	if(!istype(summoned_object, /mob/living/simple_animal/bot/secbot/ed209))
		return

	var/mob/living/simple_animal/bot/secbot/ed209/summoned_bot = summoned_object
	summoned_bot.name = "Wizard's Justicebot"

	summoned_bot.declare_arrests = FALSE
	summoned_bot.emagged = 2

	summoned_bot.projectile = /obj/projectile/beam/laser
	summoned_bot.shoot_sound = 'sound/weapons/laser.ogg'
