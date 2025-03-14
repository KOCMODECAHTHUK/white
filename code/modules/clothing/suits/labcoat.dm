/obj/item/clothing/suit/toggle/labcoat
	name = "лабораторный халат"
	desc = "Костюм, который защищает от небольших разливов химикатов."
	icon_state = "labcoat"
	worn_icon = 'icons/mob/clothing/suits/labcoat.dmi'
	inhand_icon_state = "labcoat"
	blood_overlay_type = "coat"
	body_parts_covered = CHEST|ARMS
	allowed = list(/obj/item/analyzer, /obj/item/stack/medical, /obj/item/dnainjector, /obj/item/reagent_containers/dropper, /obj/item/reagent_containers/syringe, /obj/item/reagent_containers/hypospray, /obj/item/healthanalyzer, /obj/item/flashlight/pen, /obj/item/reagent_containers/glass/bottle, /obj/item/reagent_containers/glass/beaker, /obj/item/reagent_containers/pill, /obj/item/storage/pill_bottle, /obj/item/paper, /obj/item/melee/classic_baton/telescopic, /obj/item/soap, /obj/item/sensor_device, /obj/item/tank/internals/emergency_oxygen, /obj/item/tank/internals/plasmaman, /obj/item/biopsy_tool, /obj/item/medbot_carrier, /obj/item/gun/syringe, /obj/item/solnce)
	armor = list(MELEE = 0, BULLET = 0, LASER = 0,ENERGY = 0, BOMB = 0, BIO = 50, RAD = 0, FIRE = 50, ACID = 50)
	togglename = "buttons"
	species_exception = list(/datum/species/golem)

/obj/item/clothing/suit/toggle/labcoat/cmo
	name = "халат главврача"
	desc = "Синее, чем стандартная модель."
	icon_state = "labcoat_cmo"
	inhand_icon_state = "labcoat_cmo"

/obj/item/clothing/suit/toggle/labcoat/paramedic
	name = "куртка парамедика"
	desc = "Темно-синий жакет со светоотражающими полосками для техников скорой медицинской помощи."
	icon_state = "labcoat_paramedic"
	inhand_icon_state = "labcoat_paramedic"

/obj/item/clothing/suit/toggle/labcoat/mad
	name = "лабораторный костюм сумасшедшего"
	desc = "Так вы будете выглядеть способным ударить кого-то по голове и выкинуть его в космос."
	icon_state = "labgreen"
	inhand_icon_state = "labgreen"

/obj/item/clothing/suit/toggle/labcoat/genetics
	name = "лабораторный халат генетика"
	desc = "Костюм, который защищает от небольших разливов химикатов. Имеет синюю полосу на плече."
	icon_state = "labcoat_gen"

/obj/item/clothing/suit/toggle/labcoat/chemist
	name = "лабораторный халат химика"
	desc = "Костюм, который защищает от небольших разливов химикатов. Имеет оранжевую полосу на плече."
	icon_state = "labcoat_chem"

/obj/item/clothing/suit/toggle/labcoat/chemist/Initialize(mapload)
	. = ..()
	allowed += /obj/item/storage/bag/chemistry

/obj/item/clothing/suit/toggle/labcoat/virologist
	name = "лабораторный халат вирусолога"
	desc = "Костюм, который защищает от небольших разливов химикатов. Предлагает немного больше защиты от биологической опасности, чем стандартная модель. Имеет зеленую полосу на плече."
	icon_state = "labcoat_vir"

/obj/item/clothing/suit/toggle/labcoat/virologist/Initialize(mapload)
	. = ..()
	allowed += /obj/item/storage/bag/bio

/obj/item/clothing/suit/toggle/labcoat/science
	name = "лабораторный халат учёного"
	desc = "Костюм, который защищает от небольших разливов химикатов. Имеет фиолетовую полоску на плече."
	icon_state = "labcoat_tox"

/obj/item/clothing/suit/toggle/labcoat/science/Initialize(mapload)
	. = ..()
	allowed += /obj/item/storage/bag/bio

/obj/item/clothing/suit/toggle/labcoat/roboticist
	name = "лабораторный халат роботехника"
	desc = "More like an eccentric coat than a labcoat. Helps pass off bloodstains as part of the aesthetic. Comes with red shoulder pads."
	icon_state = "labcoat_robo"
