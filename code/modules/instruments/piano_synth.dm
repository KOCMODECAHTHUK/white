
/obj/item/instrument/piano_synth
	name = "синтезатор"
	desc = "Усовершенствованный электронный синтезатор, который можно использовать в качестве различных инструментов."
	icon_state = "synth"
	inhand_icon_state = "synth"
	allowed_instrument_ids = "piano"
	var/circuit_type = /obj/item/circuit_component/synth
	var/shell_capacity = SHELL_CAPACITY_SMALL

/obj/item/instrument/piano_synth/Initialize(mapload)
	. = ..()
	song.allowed_instrument_ids = SSinstruments.synthesizer_instrument_ids
	AddComponent(/datum/component/shell, list(new circuit_type), shell_capacity)

/obj/item/instrument/piano_synth/headphones
	name = "наушники"
	desc = "Туц, туц, туц, туц, ВОУ!"
	icon = 'icons/obj/clothing/accessories.dmi'
	lefthand_file = 'icons/mob/inhands/clothing_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/clothing_righthand.dmi'
	icon_state = "headphones"
	inhand_icon_state = "headphones"
	slot_flags = ITEM_SLOT_EARS | ITEM_SLOT_HEAD
	force = 0
	w_class = WEIGHT_CLASS_SMALL
	custom_price = PAYCHECK_ASSISTANT * 2.5
	instrument_range = 1
	circuit_type = /obj/item/circuit_component/synth/headphones
	shell_capacity = SHELL_CAPACITY_TINY

/obj/item/instrument/piano_synth/headphones/ComponentInitialize()
	. = ..()
	AddElement(/datum/element/update_icon_updates_onmob)
	RegisterSignal(src, COMSIG_INSTRUMENT_START, PROC_REF(start_playing))
	RegisterSignal(src, COMSIG_INSTRUMENT_END, PROC_REF(stop_playing))

/**
 * Called by a component signal when our song starts playing.
 */
/obj/item/instrument/piano_synth/headphones/proc/start_playing()
	SIGNAL_HANDLER
	icon_state = "[initial(icon_state)]_on"
	update_appearance()

/**
 * Called by a component signal when our song stops playing.
 */
/obj/item/instrument/piano_synth/headphones/proc/stop_playing()
	SIGNAL_HANDLER
	icon_state = "[initial(icon_state)]"
	update_appearance()

/obj/item/instrument/piano_synth/headphones/spacepods
	name = "НТ-pods"
	desc = "Флекси своими деньгами И игнорируйте то, что говорят все остальные, одновременно!"
	icon_state = "spacepods"
	inhand_icon_state = "spacepods"
	slot_flags = ITEM_SLOT_EARS
	strip_delay = 100 //air pods don't fall out
	instrument_range = 0 //you're paying for quality here
	custom_premium_price = PAYCHECK_ASSISTANT * 36 //Save up 5 shifts worth of pay just to lose it down a drainpipe on the sidewalk

/obj/item/circuit_component/synth
	display_name = "Синтезатор"
	desc = "Усовершенствованный электронный синтезатор, который можно использовать в качестве различных инструментов."

	/// The song, represented in latin alphabet A to G, that'll be played when play is triggered.
	var/datum/port/input/song
	/// Starts playing the song.
	var/datum/port/input/play
	/// Stop playing the song.
	var/datum/port/input/stop
	/// How many times the song will be played.
	var/datum/port/input/repetitions
	/// The beats per minute of the song
	var/datum/port/input/beats_per_min
	/// The volume of the song
	var/datum/port/input/volume
	/// Notes with volume below this threshold will be dead
	var/datum/port/input/volume_dropoff
	/// Note shift
	var/datum/port/input/note_shift
	/// Sustain Mode
	var/datum/port/input/sustain_mode
	/// The value of the above
	var/datum/port/input/sustain_value
	/// If set the last held note will decay
	var/datum/port/input/note_decay
	/// The list of instruments which sound can be synthesized.
	var/datum/port/input/option/selected_instrument
	/// Whether a song is currently playing
	var/datum/port/output/is_playing
	/// Sent when a new song has started playing
	var/datum/port/output/started_playing
	/// Sent when a song has finished playing
	var/datum/port/output/stopped_playing

	/// The synthesizer this circut is attached to.
	var/obj/item/instrument/piano_synth/synth

/obj/item/circuit_component/synth/populate_ports()
	song = add_input_port("Песня", PORT_TYPE_LIST(PORT_TYPE_STRING), trigger = PROC_REF(import_song))
	play = add_input_port("Играть", PORT_TYPE_SIGNAL, trigger = PROC_REF(start_playing))
	stop = add_input_port("Остановить", PORT_TYPE_SIGNAL, trigger = PROC_REF(stop_playing))
	repetitions = add_input_port("Количество повторов", PORT_TYPE_NUMBER, trigger = PROC_REF(set_repetitions))
	beats_per_min = add_input_port("BPM", PORT_TYPE_NUMBER, trigger = PROC_REF(set_bpm))
	selected_instrument = add_option_port("Выбранный инструмент", SSinstruments.synthesizer_instrument_ids, trigger = PROC_REF(set_instrument))
	volume = add_input_port("Громкость", PORT_TYPE_NUMBER, trigger = PROC_REF(set_volume))
	volume_dropoff = add_input_port("Порог снижения громкости", PORT_TYPE_NUMBER, trigger = PROC_REF(set_dropoff))
	note_shift = add_input_port("Сдвиг ноты", PORT_TYPE_NUMBER, trigger = PROC_REF(set_note_shift))
	sustain_mode = add_option_port("Note Sustain Mode", SSinstruments.note_sustain_modes, trigger = PROC_REF(set_sustain_mode))
	sustain_value = add_input_port("Note Sustain Value", PORT_TYPE_NUMBER, trigger = PROC_REF(set_sustain_value))
	note_decay = add_input_port("Held Note Decay", PORT_TYPE_NUMBER, trigger = PROC_REF(set_sustain_decay))

	is_playing = add_output_port("Сейчас играет", PORT_TYPE_NUMBER)
	started_playing = add_output_port("Начато", PORT_TYPE_SIGNAL)
	stopped_playing = add_output_port("Остановлено", PORT_TYPE_SIGNAL)

/obj/item/circuit_component/synth/register_shell(atom/movable/shell)
	. = ..()
	synth = shell
	RegisterSignal(synth, COMSIG_INSTRUMENT_START, PROC_REF(on_song_start))
	RegisterSignal(synth, COMSIG_INSTRUMENT_END, PROC_REF(on_song_end))
	RegisterSignal(synth, COMSIG_INSTRUMENT_SHOULD_STOP_PLAYING, PROC_REF(continue_if_autoplaying))

/obj/item/circuit_component/synth/unregister_shell(atom/movable/shell)
	if(synth.song.music_player == src)
		synth.song.stop_playing()
	synth = null
	UnregisterSignal(synth, list(COMSIG_INSTRUMENT_START, COMSIG_INSTRUMENT_END, COMSIG_INSTRUMENT_SHOULD_STOP_PLAYING))
	return ..()

/obj/item/circuit_component/synth/proc/start_playing(datum/port/input/port)
	synth.song.start_playing(src)

/obj/item/circuit_component/synth/proc/on_song_start()
	SIGNAL_HANDLER
	is_playing.set_output(TRUE)
	started_playing.set_output(COMPONENT_SIGNAL)

/obj/item/circuit_component/synth/proc/continue_if_autoplaying(datum/source, atom/music_player)
	SIGNAL_HANDLER
	if(music_player == src)
		return IGNORE_INSTRUMENT_CHECKS

/obj/item/circuit_component/synth/proc/stop_playing(datum/port/input/port)
	synth.song.stop_playing()

/obj/item/circuit_component/synth/proc/on_song_end()
	SIGNAL_HANDLER
	is_playing.set_output(FALSE)
	stopped_playing.set_output(COMPONENT_SIGNAL)

/obj/item/circuit_component/synth/proc/import_song()
	synth.song.ParseSong(song.value)

/obj/item/circuit_component/synth/proc/set_repetitions()
	synth.song.set_repeats(repetitions.value)

/obj/item/circuit_component/synth/proc/set_bpm()
	synth.song.sanitize_tempo(BPM_TO_TEMPO_SETTING(beats_per_min.value))

/obj/item/circuit_component/synth/proc/set_instrument()
	synth.song.set_instrument(selected_instrument.value)

/obj/item/circuit_component/synth/proc/set_volume()
	synth.song.set_volume(volume.value)

/obj/item/circuit_component/synth/proc/set_dropoff()
	synth.song.set_dropoff_volume(volume_dropoff.value)

/obj/item/circuit_component/synth/proc/set_note_shift()
	synth.song.note_shift = clamp(note_shift.value, synth.song.note_shift_min, synth.song.note_shift_max)

/obj/item/circuit_component/synth/proc/set_sustain_mode()
	synth.song.sustain_mode = SSinstruments.note_sustain_modes[sustain_mode.value]

/obj/item/circuit_component/synth/proc/set_sustain_value()
	switch(synth.song.sustain_mode)
		if(SUSTAIN_LINEAR)
			synth.song.set_linear_falloff_duration(sustain_value.value)
		if(SUSTAIN_EXPONENTIAL)
			synth.song.set_exponential_drop_rate(sustain_value.value)

/obj/item/circuit_component/synth/proc/set_sustain_decay()
	synth.song.full_sustain_held_note = !!synth.song.full_sustain_held_note

/obj/item/circuit_component/synth/headphones
	display_name = "Наушники"
	desc = "Усовершенствованное электронное устройство, которое воспроизводит музыку в ваших ушах."
