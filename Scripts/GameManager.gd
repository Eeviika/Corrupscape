extends Node

var current_data
var previous_scene
var background_music_player: AudioStreamPlayer
var background_music: Dictionary
var background_music_currently_playing: String = ""
var volume := 20

enum GameErrors {SCREEN_DOES_NOT_EXIST, PLAYER_IN_NON_TILEMAP_LEVEL, CORRUPTION_IN_NON_PLAYER_LEVEL, GAME_UI_CANNOT_CONNECT_TO_PLAYER, MUSIC_PAK_IS_INVALID, MUSIC_LOADED_IS_INVALID}

enum Tiles {VOID=-1, WALL, FLOOR, JUMP, SLIDE, SKIP, DECAYSTART, DECAYEND, CORRUPT, GOAL, TURNADD}

func initalizeBackgroundMusic(music_pak:Dictionary):
	assert(!background_music_player, "Attempted to initalize background music player when one already exists.")
	assert(music_pak, "No music pak provided.")
	for i in music_pak.keys():
		if !(music_pak[i] is AudioStreamMP3):
			switchScreen("res://Levels/LevelError.tscn", GameErrors.MUSIC_PAK_IS_INVALID)
			return;
	background_music = music_pak
	background_music_player = AudioStreamPlayer.new()
	add_child(background_music_player)

func hasSaveFile():
	return FileAccess.file_exists("user://sav.dat")

func saveFile(data:Dictionary):
	var file := FileAccess.open("user://sav.dat", FileAccess.WRITE)
	file.store_var(data)

func getSaveFile() -> Dictionary:
	var save_data := {}
	var file = FileAccess
	if file.file_exists("user://sav.dat"):
		file = file.open("user://sav.dat", FileAccess.READ)
		save_data = file.get_var()
		file.close()
	return save_data
	

func playBackgroundMusic(alias: String, repeat_anyways=false, from_pos=0.0):
	if background_music_currently_playing == alias and !repeat_anyways: return
	if !background_music.has(alias): switchScreen("res://Levels/LevelError.tscn"); return;
	background_music_currently_playing = alias
	background_music_player.stop()
	background_music_player.stream = background_music[alias]
	background_music_player.play(from_pos)

func playBackgroundRaw(audioStream, repeat_anyways=false, from_pos=0.0):
	if background_music_currently_playing == audioStream.resource_name and !repeat_anyways: return;
	background_music_currently_playing = audioStream.resource_name
	background_music_player.stop()
	background_music_player.stream = audioStream
	background_music_player.play(from_pos)

func stopBackgroundMusic():
	background_music_currently_playing = ""
	background_music_player.stop()

func switchScreen(path, data=""):
	current_data = data if str(data) != "" else current_data
	if !FileAccess.file_exists(path):
		switchScreen("res://Levels/LevelError.tscn", GameErrors.SCREEN_DOES_NOT_EXIST)
		return;
	previous_scene = [get_tree().current_scene.name, get_tree().current_scene.scene_file_path]
	get_tree().call_deferred("change_scene_to_file", path)

func reloadScreen():
	get_tree().reload_current_scene()

func copyErrorToClipboard():
	DisplayServer.clipboard_set(get_tree().current_scene.get_node("%ErrorArea").text)

func exitGame():
	print("Goodbye, World!")
	get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
	get_tree().quit()

func _ready():
	print("Hello, World!")
	previous_scene = [get_tree().current_scene.name, get_tree().current_scene.scene_file_path]
	initalizeBackgroundMusic({
		"level": preload("res://Music/level.mp3"),
		"level-fast": preload("res://Music/level-fast.mp3"),
		"rush": preload("res://Music/rush.mp3"),
		"title": preload("res://Music/title.mp3"),
		"truth": preload("res://Music/truth.mp3")
	})

func _process(_delta):

	if background_music_player:
		background_music_player.volume_db = -80 + (0.4*(volume*10))

	if get_tree().current_scene and get_tree().current_scene.scene_file_path == "res://Levels/LevelError.tscn":
		stopBackgroundMusic()
		get_tree().current_scene.get_node("%ErrorArea").text = "At {0}:{1}:{2} on {3}/{4}\nError Code {5} ({6}) occurred.\nIn Scene: {7} (Path: {8})".format([Time.get_time_dict_from_system().hour, Time.get_time_dict_from_system().minute, Time.get_time_dict_from_system().second, Time.get_date_dict_from_system().month, Time.get_date_dict_from_system().day, current_data, GameErrors.find_key(current_data), previous_scene[0], previous_scene[1]])
		if !get_tree().current_scene.get_node("%CopyToClipboardButton").is_connected("pressed", copyErrorToClipboard):
			get_tree().current_scene.get_node("%CopyToClipboardButton").connect("pressed", copyErrorToClipboard)

func _input(event):
	if event is InputEventKey and event.keycode == KEY_ESCAPE:
		var timer := Timer.new()
		timer.one_shot = true
		timer.autostart = true
		timer.wait_time = 2
		add_child(timer)
		timer.timeout.connect(func() -> void:
			if Input.is_key_pressed(KEY_ESCAPE):
				exitGame()
			else:
				queue_free()
		)
		return;
	if event is InputEventKey and event.keycode == KEY_MINUS:
		volume-=1
		volume=clamp(volume, 0, 20)
	if event is InputEventKey and event.keycode == KEY_EQUAL:
		volume+=1
		volume=clamp(volume, 0, 20)
	if event.is_action_pressed("_cancel") and get_tree().current_scene and get_tree().current_scene.scene_file_path == "res://Levels/LevelError.tscn":
		switchScreen(previous_scene[1])
