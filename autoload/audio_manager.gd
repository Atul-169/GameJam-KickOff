extends Node

const SETTINGS_PATH := "user://settings.cfg"
const SFX_POOL_SIZE := 8

var music_player: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []
var music_volume := 0.75
var sfx_volume := 0.85
var music_request_id := 0
var hit_stop_request_id := 0

func _ready() -> void:
    _ensure_bus("Music")
    _ensure_bus("SFX")
    music_player = AudioStreamPlayer.new()
    music_player.bus = "Music"
    add_child(music_player)
    for index in SFX_POOL_SIZE:
        var player := AudioStreamPlayer.new()
        player.name = "SFX_%02d" % index
        player.bus = "SFX"
        add_child(player)
        sfx_players.append(player)
    load_settings()

func _ensure_bus(name: String) -> void:
    if AudioServer.get_bus_index(name) >= 0:
        return
    AudioServer.add_bus()
    AudioServer.set_bus_name(AudioServer.bus_count - 1, name)

func set_music_volume(value: float) -> void:
    music_volume = clampf(value, 0.0, 1.0)
    AudioServer.set_bus_volume_db(
        AudioServer.get_bus_index("Music"),
        linear_to_db(maxf(music_volume, 0.001)),
    )
    save_settings()

func set_sfx_volume(value: float) -> void:
    sfx_volume = clampf(value, 0.0, 1.0)
    AudioServer.set_bus_volume_db(
        AudioServer.get_bus_index("SFX"),
        linear_to_db(maxf(sfx_volume, 0.001)),
    )
    save_settings()

func play_music(asset_key: String, fade: float = 0.25) -> void:
    music_request_id += 1
    var request_id := music_request_id
    var stream := AssetRegistry.load_audio(asset_key)
    if stream == null:
        return
    if music_player.stream == stream and music_player.playing:
        return
    if music_player.playing and fade > 0.0:
        var tween := create_tween()
        tween.tween_property(music_player, "volume_db", -30.0, fade)
        await tween.finished
        if request_id != music_request_id or not is_inside_tree():
            return
    music_player.stream = stream
    music_player.volume_db = 0.0
    music_player.play()

func play_sfx(asset_key: String) -> void:
    var stream := AssetRegistry.load_audio(asset_key)
    if stream == null or sfx_players.is_empty():
        return
    var selected := sfx_players[0]
    for candidate in sfx_players:
        if not candidate.playing:
            selected = candidate
            break
    selected.stream = stream
    selected.play()

func stop_music() -> void:
    music_request_id += 1
    if music_player != null:
        music_player.stop()

func set_fullscreen(enabled: bool) -> void:
    DisplayServer.window_set_mode(
        DisplayServer.WINDOW_MODE_FULLSCREEN
        if enabled
        else DisplayServer.WINDOW_MODE_WINDOWED
    )
    save_settings()

func save_settings() -> void:
    var config := ConfigFile.new()
    config.set_value("audio", "music", music_volume)
    config.set_value("audio", "sfx", sfx_volume)
    config.set_value(
        "video",
        "fullscreen",
        DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN,
    )
    config.save(SETTINGS_PATH)
    EventBus.settings_changed.emit()

func load_settings() -> void:
    var config := ConfigFile.new()
    if config.load(SETTINGS_PATH) == OK:
        music_volume = float(config.get_value("audio", "music", 0.75))
        sfx_volume = float(config.get_value("audio", "sfx", 0.85))
        var fullscreen := bool(
            config.get_value("video", "fullscreen", false)
        )
        DisplayServer.window_set_mode(
            DisplayServer.WINDOW_MODE_FULLSCREEN
            if fullscreen
            else DisplayServer.WINDOW_MODE_WINDOWED
        )
    AudioServer.set_bus_volume_db(
        AudioServer.get_bus_index("Music"),
        linear_to_db(maxf(music_volume, 0.001)),
    )
    AudioServer.set_bus_volume_db(
        AudioServer.get_bus_index("SFX"),
        linear_to_db(maxf(sfx_volume, 0.001)),
    )

func hit_stop(duration: float) -> void:
    hit_stop_request_id += 1
    var request_id := hit_stop_request_id
    Engine.time_scale = 0.12
    await get_tree().create_timer(duration, true, false, true).timeout
    if request_id == hit_stop_request_id:
        Engine.time_scale = 1.0

func restore_runtime_state() -> void:
    hit_stop_request_id += 1
    Engine.time_scale = 1.0
