/datum/round_event_control/anomaly/anomaly_dimensional
	name = "Anomaly: Dimensional"
	typepath = /datum/round_event/anomaly/anomaly_dimensional

	min_players = 10
	max_occurrences = 5
	weight = 20

/datum/round_event/anomaly/anomaly_dimensional
	startWhen = 10
	announceWhen = 3
	anomaly_path = /obj/effect/anomaly/dimensional

/datum/round_event/anomaly/anomaly_dimensional/announce(fake)
	priority_announce("Localized dimensional instability detected on long range scanners. Expected location: [impact_area.name].", "Anomaly Alert")
