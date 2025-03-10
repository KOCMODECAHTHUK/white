//Security modules for MODsuits

///Magnetic Harness - Automatically puts guns in your suit storage when you drop them.
/obj/item/mod/module/magnetic_harness
	name = "модуль магнитного захвата"
	desc = "Модуль основанный на старой довоенной разработке, позволяющий вернуть оружие в крепеж, если пользователь выронил его вследствие случайного инцидента."
	icon_state = "mag_harness"
	complexity = 2
	use_power_cost = DEFAULT_CHARGE_DRAIN
	incompatible_modules = list(/obj/item/mod/module/magnetic_harness)
	/// Time before we activate the magnet.
	var/magnet_delay = 0.8 SECONDS
	/// The typecache of all guns we allow.
	var/static/list/guns_typecache
	/// The guns already allowed by the modsuit chestplate.
	var/list/already_allowed_guns = list()

/obj/item/mod/module/magnetic_harness/Initialize(mapload)
	. = ..()
	if(!guns_typecache)
		guns_typecache = typecacheof(list(/obj/item/gun/ballistic, /obj/item/gun/energy, /obj/item/gun/grenadelauncher, /obj/item/gun/chem, /obj/item/gun/syringe))

/obj/item/mod/module/magnetic_harness/on_install()
	already_allowed_guns = guns_typecache & mod.chestplate.allowed
	mod.chestplate.allowed |= guns_typecache

/obj/item/mod/module/magnetic_harness/on_uninstall(deleting = FALSE)
	if(deleting)
		return
	mod.chestplate.allowed -= (guns_typecache - already_allowed_guns)

/obj/item/mod/module/magnetic_harness/on_suit_activation()
	RegisterSignal(mod.wearer, COMSIG_MOB_UNEQUIPPED_ITEM, PROC_REF(check_dropped_item))

/obj/item/mod/module/magnetic_harness/on_suit_deactivation(deleting = FALSE)
	UnregisterSignal(mod.wearer, COMSIG_MOB_UNEQUIPPED_ITEM)

/obj/item/mod/module/magnetic_harness/proc/check_dropped_item(datum/source, obj/item/dropped_item, force, new_location)
	SIGNAL_HANDLER

	if(!is_type_in_typecache(dropped_item, guns_typecache))
		return
	if(new_location != get_turf(src))
		return
	addtimer(CALLBACK(src, PROC_REF(pick_up_item), dropped_item), magnet_delay)

/obj/item/mod/module/magnetic_harness/proc/pick_up_item(obj/item/item)
	if(!isturf(item.loc) || !item.Adjacent(mod.wearer))
		return
	if(!mod.wearer.equip_to_slot_if_possible(item, ITEM_SLOT_SUITSTORE, qdel_on_fail = FALSE, disable_warning = TRUE))
		return
	playsound(src, 'sound/items/modsuit/magnetic_harness.ogg', 50, TRUE)
	balloon_alert(mod.wearer, "[item] прицеплен")
	drain_power(use_power_cost)

///Pepper Shoulders - When hit, reacts with a spray of pepper spray around the user.
/obj/item/mod/module/pepper_shoulders
	name = "модуль перцовых наплечников"
	desc = "Модуль экстренной самообороны носителя, реагирующий на попытки прикоснуться к поверхности скафандра периферийной защитой из перцового газа."
	icon_state = "pepper_shoulder"
	module_type = MODULE_USABLE
	complexity = 1
	use_power_cost = DEFAULT_CHARGE_DRAIN
	incompatible_modules = list(/obj/item/mod/module/pepper_shoulders)
	cooldown_time = 5 SECONDS
	overlay_state_inactive = "module_pepper"
	overlay_state_use = "module_pepper_used"

/obj/item/mod/module/pepper_shoulders/on_suit_activation()
	RegisterSignal(mod.wearer, COMSIG_HUMAN_CHECK_SHIELDS, PROC_REF(on_check_shields))

/obj/item/mod/module/pepper_shoulders/on_suit_deactivation(deleting = FALSE)
	UnregisterSignal(mod.wearer, COMSIG_HUMAN_CHECK_SHIELDS)

/obj/item/mod/module/pepper_shoulders/on_use()
	. = ..()
	if(!.)
		return
	playsound(src, 'sound/effects/spray.ogg', 30, TRUE, -6)
	var/datum/reagents/capsaicin_holder = new(10)
	capsaicin_holder.add_reagent(/datum/reagent/consumable/condensedcapsaicin, 10)
	var/datum/effect_system/fluid_spread/smoke/chem/quick/smoke = new
	smoke.set_up(1, holder = src, location = get_turf(src), carry = capsaicin_holder)
	smoke.start(log = TRUE)
	QDEL_NULL(capsaicin_holder) // Reagents have a ref to their holder which has a ref to them. No leaks please.

/obj/item/mod/module/pepper_shoulders/proc/on_check_shields()
	SIGNAL_HANDLER

	if(!COOLDOWN_FINISHED(src, cooldown_timer))
		return
	if(!check_power(use_power_cost))
		return
	mod.wearer.visible_message(span_warning("[src] реагирует на атаку облаком перцового газа!"), span_notice("Сработала система экстренной самообороны! Из наплечников распыляется перцовый газ!"))
	on_use()

///Holster - Instantly holsters any not huge gun.
/obj/item/mod/module/holster
	name = "модуль кобуры"
	desc = "Данный модуль входит в комплект поставки большинства боевых скафандров и предоставляет дополнительный слот для хранения оружия."
	icon_state = "holster"
	module_type = MODULE_USABLE
	complexity = 2
	incompatible_modules = list(/obj/item/mod/module/holster)
	cooldown_time = 0.5 SECONDS
	allow_flags = MODULE_ALLOW_INACTIVE
	/// Gun we have holstered.
	var/obj/item/gun/holstered

/obj/item/mod/module/holster/on_use()
	. = ..()
	if(!.)
		return
	if(!holstered)
		var/obj/item/gun/holding = mod.wearer.get_active_held_item()
		if(!holding)
			balloon_alert(mod.wearer, "Нечего вытаскивать!")
			return
		if(!istype(holding) || holding.w_class > WEIGHT_CLASS_BULKY)
			balloon_alert(mod.wearer, "Оно слишком большое!")
			return
		if(mod.wearer.transferItemToLoc(holding, src, force = FALSE, silent = TRUE))
			holstered = holding
			balloon_alert(mod.wearer, "Оружие убрано")
			playsound(src, 'sound/weapons/gun/revolver/empty.ogg', 100, TRUE)
	else if(mod.wearer.put_in_active_hand(holstered, forced = FALSE, ignore_animation = TRUE))
		balloon_alert(mod.wearer, "Оружие извлечено")
		playsound(src, 'sound/weapons/gun/revolver/empty.ogg', 100, TRUE)
	else
		balloon_alert(mod.wearer, "Кобура занята!")

/obj/item/mod/module/holster/on_uninstall(deleting = FALSE)
	if(holstered)
		holstered.forceMove(drop_location())

/obj/item/mod/module/holster/Exited(atom/movable/gone, direction)
	. = ..()
	if(gone == holstered)
		holstered = null

/obj/item/mod/module/holster/Destroy()
	QDEL_NULL(holstered)
	return ..()

///Megaphone - Lets you speak loud.
/obj/item/mod/module/megaphone
	name = "модуль громкоговорителя"
	desc = "Интегрированный в скафандр мегафон, в основном использующийся при подавлении гражданских волнений или для непосредственного руководства на поле боя."
	icon_state = "megaphone"
	module_type = MODULE_TOGGLE
	complexity = 1
	use_power_cost = DEFAULT_CHARGE_DRAIN * 0.5
	incompatible_modules = list(/obj/item/mod/module/megaphone)
	cooldown_time = 0.5 SECONDS
	/// List of spans we add to the speaker.
	var/list/voicespan = list(SPAN_COMMAND)

/obj/item/mod/module/megaphone/on_activation()
	. = ..()
	if(!.)
		return
	RegisterSignal(mod.wearer, COMSIG_MOB_SAY, PROC_REF(handle_speech))

/obj/item/mod/module/megaphone/on_deactivation(display_message = TRUE, deleting = FALSE)
	. = ..()
	if(!.)
		return
	UnregisterSignal(mod.wearer, COMSIG_MOB_SAY)

/obj/item/mod/module/megaphone/proc/handle_speech(datum/source, list/speech_args)
	SIGNAL_HANDLER

	speech_args[SPEECH_SPANS] |= voicespan
	drain_power(use_power_cost)

///Criminal Capture - Lets you put people in transport bags.
/obj/item/mod/module/criminalcapture
	name = "модуль карцера"
	desc = "Модуль используемый для транспортировки потенциальных преступников или же раненых в специальной транспортной сумке \
	с защитой от окружающей среды. Возможно это не слишком гуманно по отношению к задерживаемому, \
	однако в первую очередь это удобно для офицеров безопасности. Помещенный внутрь человек в критическом состоянии так же стабилизируется."
	icon_state = "criminalcapture"
	module_type = MODULE_ACTIVE
	complexity = 2
	use_power_cost = DEFAULT_CHARGE_DRAIN * 0.5
	incompatible_modules = list(/obj/item/mod/module/criminalcapture)
	cooldown_time = 0.5 SECONDS
	/// Max bag capacity.
	var/max_capacity = 3
	/// Time to capture a prisoner.
	var/capture_time = 1 SECONDS
	/// Time to pack a bodybag up.
	var/packup_time = 0.5 SECONDS
	/// List of our capture bags.
	var/list/criminal_capture_bags = list()

/obj/item/mod/module/criminalcapture/Initialize(mapload)
	. = ..()
	for(var/i in 1 to max_capacity)
		criminal_capture_bags += new /obj/structure/closet/body_bag/environmental/prisoner/pressurized(src)

/obj/item/mod/module/criminalcapture/on_select_use(atom/target)
	. = ..()
	if(!.)
		return
	if(!mod.wearer.Adjacent(target))
		return
	if(isliving(target))
		var/mob/living/living_target = target
		var/turf/target_turf = get_turf(living_target)
		playsound(src, 'sound/items/zip.ogg', 25, TRUE)
		if(!do_after(mod.wearer, capture_time, target = living_target))
			balloon_alert(mod.wearer, "Прервано!")
			return
		var/obj/structure/closet/body_bag/environmental/prisoner/dropped_bag = pop(criminal_capture_bags)
		dropped_bag.forceMove(target_turf)
		dropped_bag.close()
		living_target.forceMove(dropped_bag)
	else if(istype(target, /obj/structure/closet/body_bag/environmental/prisoner) || istype(target, /obj/item/bodybag/environmental/prisoner))
		var/obj/item/bodybag/environmental/prisoner/bag = target
		if(criminal_capture_bags.len >= max_capacity)
			balloon_alert(mod.wearer, "Лимит сумки достигнут!")
			return
		playsound(src, 'sound/items/zip.ogg', 25, TRUE)
		if(!do_after(mod.wearer, packup_time, target = bag))
			balloon_alert(mod.wearer, "Прервано!")
			return
		if(criminal_capture_bags.len >= max_capacity)
			balloon_alert(mod.wearer, "Лимит сумки достигнут!")
			return
		if(locate(/mob/living) in bag)
			balloon_alert(mod.wearer, "Живое существо внутри!")
			return
		if(istype(bag, /obj/item/bodybag/environmental/prisoner))
			bag = bag.deploy_bodybag(mod.wearer, get_turf(bag))
		var/obj/structure/closet/body_bag/environmental/prisoner/structure_bag = bag
		if(!structure_bag.opened)
			structure_bag.open(mod.wearer, force = TRUE)
		bag.forceMove(src)
		criminal_capture_bags += bag
		balloon_alert(mod.wearer, "Сумка зафиксирована")
	else
		balloon_alert(mod.wearer, "Неправильная цель!")

///Mirage grenade dispenser - Dispenses grenades that copy the user's appearance.
/obj/item/mod/module/dispenser/mirage
	name = "модуль раздачи гранат 'Мираж'"
	desc = "Этот модуль может создавать гранаты-миражи по желанию пользователя. Эти гранаты создают голографические копии пользователя."
	icon_state = "mirage_grenade"
	cooldown_time = 20 SECONDS
	overlay_state_inactive = "module_mirage_grenade"
	dispense_type = /obj/item/grenade/mirage

/obj/item/mod/module/dispenser/mirage/on_use()
	. = ..()
	if(!.)
		return
	var/obj/item/grenade/mirage/grenade = .
	grenade.arm_grenade(mod.wearer)

/obj/item/grenade/mirage
	name = "Граната 'Мираж'"
	desc = "Специальное устройство, которое при активации производит голографическую копию пользователя."
	icon_state = "mirage"
	inhand_icon_state = "flashbang"
	det_time = 3 SECONDS
	/// Mob that threw the grenade.
	var/mob/living/thrower

/obj/item/grenade/mirage/arm_grenade(mob/user, delayoverride, msg, volume)
	. = ..()
	thrower = user

/obj/item/grenade/mirage/detonate(mob/living/lanced_by)
	. = ..()
	do_sparks(rand(3, 6), FALSE, src)
	if(thrower)
		var/mob/living/simple_animal/hostile/illusion/mirage/mirage = new(get_turf(src))
		mirage.Copy_Parent(thrower, 15 SECONDS)
	qdel(src)

///Projectile Dampener - Weakens projectiles in range.
/obj/item/mod/module/projectile_dampener
	name = "модуль гиперкинетического демпфера"
	desc = "Используя технологию миротворчерских киборгов, этот модуль уменьшает кинетическую энергию снарядов в области действия."
	icon_state = "projectile_dampener"
	module_type = MODULE_TOGGLE
	complexity = 3
	active_power_cost = DEFAULT_CHARGE_DRAIN
	incompatible_modules = list(/obj/item/mod/module/projectile_dampener)
	cooldown_time = 1.5 SECONDS
	/// Radius of the dampening field.
	var/field_radius = 2
	/// Damage multiplier on projectiles.
	var/damage_multiplier = 0.75
	/// Speed multiplier on projectiles, higher means slower.
	var/speed_multiplier = 2.5
	/// List of all tracked projectiles.
	var/list/tracked_projectiles = list()
	/// Effect image on projectiles.
	var/image/projectile_effect
	/// The dampening field
	var/datum/proximity_monitor/advanced/projectile_dampener/dampening_field

/obj/item/mod/module/projectile_dampener/Initialize(mapload)
	. = ..()
	projectile_effect = image('icons/effects/fields.dmi', "projectile_dampen_effect")

/obj/item/mod/module/projectile_dampener/on_activation()
	. = ..()
	if(!.)
		return
	if(istype(dampening_field))
		QDEL_NULL(dampening_field)
	dampening_field = new(mod.wearer, field_radius, TRUE, src)
	RegisterSignal(dampening_field, COMSIG_DAMPENER_CAPTURE, PROC_REF(dampen_projectile))
	RegisterSignal(dampening_field, COMSIG_DAMPENER_RELEASE, PROC_REF(release_projectile))

/obj/item/mod/module/projectile_dampener/on_deactivation(display_message, deleting = FALSE)
	. = ..()
	if(!.)
		return
	QDEL_NULL(dampening_field)

/obj/item/mod/module/projectile_dampener/proc/dampen_projectile(datum/source, obj/projectile/projectile)
	projectile.damage *= damage_multiplier
	projectile.speed *= speed_multiplier
	projectile.add_overlay(projectile_effect)

/obj/item/mod/module/projectile_dampener/proc/release_projectile(datum/source, obj/projectile/projectile)
	projectile.damage /= damage_multiplier
	projectile.speed /= speed_multiplier
	projectile.cut_overlay(projectile_effect)

///Active Sonar - Displays a hud circle on the turf of any living creatures in the given radius
/obj/item/mod/module/active_sonar
	name = "модуль активного сонара"
	desc = "Древняя технология 20-го века. Этот модуль использует звуковые волны для обнаружения живых существ в радиусе пользователя. \
	Его громкий звук довольно трудно не заметить помещении, в отличии от полевых условиях, для которых он был предназначен."
	icon_state = "active_sonar"
	module_type = MODULE_USABLE
	use_power_cost = DEFAULT_CHARGE_DRAIN * 4
	complexity = 3
	incompatible_modules = list(/obj/item/mod/module/active_sonar)
	cooldown_time = 15 SECONDS

/obj/item/mod/module/active_sonar/on_use()
	. = ..()
	if(!.)
		return
	balloon_alert(mod.wearer, "Перезарядка сонара...")
	playsound(mod.wearer, 'sound/mecha/skyfall_power_up.ogg', vol = 20, vary = TRUE, extrarange = SHORT_RANGE_SOUND_EXTRARANGE)
	if(!do_after(mod.wearer, 1.1 SECONDS))
		return
	var/creatures_detected = 0
	for(var/mob/living/creature in range(9, mod.wearer))
		if(creature == mod.wearer || creature.stat == DEAD)
			continue
		new /obj/effect/temp_visual/sonar_ping(mod.wearer.loc, mod.wearer, creature)
		creatures_detected++
	playsound(mod.wearer, 'sound/effects/ping_hit.ogg', vol = 75, vary = TRUE, extrarange = MEDIUM_RANGE_SOUND_EXTRARANGE) // Should be audible for the radius of the sonar
	to_chat(mod.wearer, span_notice("Ударяю своим кулаком об пол, посылая звуковую волну, которая обнаруживает [creatures_detected] живых существ рядом!"))
