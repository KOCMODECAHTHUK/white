///Filtering ratio for high amounts of gas
#define HIGH_FILTERING_RATIO 0.001
///Filtering ratio for min amount of gas
#define LOW_FILTERING_RATIO 0.0005
///Min amount of high filtering gases for high filtering ratio
#define HIGH_FILTERING_MOLES 0.001
///Min amount of mid filtering gases for high filtering ratio
#define MID_FILTERING_MOLES 0.0025
///Min amount of low filtering gases for high filtering ratio
#define LOW_FILTERING_MOLES 0.0005
///Min amount of wear that the filter gets when used
#define FILTERS_CONSTANT_WEAR 0.05

/obj/item/gas_filter
	name = "фильтр противогаза"
	desc = "Кусок многослойной фильтрационной ткани для использования в противогазах."
	icon = 'icons/obj/clothing/masks.dmi'
	icon_state = "gas_atmos_filter"
	///Amount of filtering points available
	var/filter_status = 100
	///strength of the filter against high filtering gases
	var/filter_strength_high = 10
	///strength of the filter against mid filtering gases
	var/filter_strength_mid = 8
	///strength of the filter against low filtering gases
	var/filter_strength_low = 5
	///General efficiency of the filter (between 0 and 1)
	var/filter_efficiency = 0.5

	///List of gases with high filter priority
	var/list/high_filtering_gases = list(
		GAS_PLASMA,
		GAS_CO2,
		GAS_NITROUS
		)
	///List of gases with medium filter priority
	var/list/mid_filtering_gases = list(
		GAS_NITRYL,
		GAS_STIMULUM,
		GAS_HYPERNOB,
		GAS_BZ
		)
	///List of gases with low filter priority
	var/list/low_filtering_gases = list(
		GAS_TRITIUM,
		)

/obj/item/gas_filter/examine(mob/user)
	. = ..()
	. += span_notice("[src] is at <b>[filter_status]%</b> durability.")

/**
 * called by the gas mask where the filter is installed, lower the filter_status depending on the breath gas composition and by the strength of the filter
 * returns the modified breath gas mixture
 *
 * Arguments:
 * * breath - the current gas mixture of the breathed air
 *
 */
/obj/item/gas_filter/proc/reduce_filter_status(datum/gas_mixture/breath)

	var/danger_points = 0

	for(var/gas_id in breath.get_gases())
		if(gas_id in high_filtering_gases)
			if(breath.get_moles(gas_id) > HIGH_FILTERING_MOLES)
				breath.set_moles(gas_id, max(breath.get_moles(gas_id) - filter_strength_high * filter_efficiency * HIGH_FILTERING_RATIO, 0))
				danger_points += 0.5
				continue
			breath.set_moles(gas_id, max(breath.get_moles(gas_id) - filter_strength_high * filter_efficiency * LOW_FILTERING_RATIO, 0))
			danger_points += 0.05
			continue
		if(gas_id in mid_filtering_gases)
			if(breath.get_moles(gas_id) > MID_FILTERING_MOLES)
				breath.set_moles(gas_id, max(breath.get_moles(gas_id) - filter_strength_mid * filter_efficiency * HIGH_FILTERING_RATIO, 0))
				danger_points += 0.75
				continue
			breath.set_moles(gas_id, max(breath.get_moles(gas_id) - filter_strength_mid * filter_efficiency * LOW_FILTERING_RATIO, 0))
			danger_points += 0.15
			continue
		if(gas_id in low_filtering_gases)
			if(breath.get_moles(gas_id) > LOW_FILTERING_MOLES)
				breath.set_moles(gas_id, max(breath.get_moles(gas_id) - filter_strength_low * filter_efficiency * HIGH_FILTERING_RATIO, 0))
				danger_points += 1
				continue
			breath.set_moles(gas_id, max(breath.get_moles(gas_id) - filter_strength_low * filter_efficiency * LOW_FILTERING_RATIO, 0))
			danger_points += 0.5
			continue

	filter_status = max(filter_status - danger_points - FILTERS_CONSTANT_WEAR, 0)
	return breath

/obj/item/gas_filter/damaged
	name = "поврежденный фильтр противогаза"
	desc = "Кусок многослойной фильтрационной ткани для использования в противогазах. Кажется он поврежден."
	filter_status = 50 //override on initialize

/obj/item/gas_filter/damaged/Initialize(mapload)
	. = ..()
	filter_status = rand(35, 65)

/obj/item/gas_filter/plasmaman
	name = "фильтр противогаза плазмена"
	desc = "Кусок многослойной фильтрационной ткани для использования в противогазах."
	high_filtering_gases = list(
		GAS_O2,
		GAS_CO2,
		GAS_NITROUS
		)
