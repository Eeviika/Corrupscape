extends CharacterBody2D

signal before_step(tilepos: Vector2i, gamepos: Vector2)
signal after_step(tilepos: Vector2i, gamepos: Vector2)
signal death()
signal goal_reached()

@export var max_steps = 30

@export var cameraLimits = {
	"left": -10000000,
	"right": 10000000,
	"bottom": 10000000,
	"top": -10000000 
}

@onready var SFX_Player : AudioStreamPlayer = $SFX
@onready var camera : Camera2D
@onready var slideTimer : Timer = $SlideTimer
@onready var movementTimer : Timer = $MovementTimeout
@onready var sprite : AnimatedSprite2D = $AnimatedSprite2D

enum Direction {RIGHT, DOWN, LEFT, UP}

var SFX: Dictionary = {
	"move": preload("res://SFX/move.wav"),
	"jump": preload("res://SFX/jump.wav"),
	"slide": preload("res://SFX/slide.wav"),
	"hurt": preload("res://SFX/hurt.wav"),
	"death": preload("res://SFX/death.wav"),
	"win": preload("res://SFX/win.wav"),
	"fall": preload("res://SFX/fall.wav"),
	"turnadd": preload("res://SFX/turnadd.wav")
}

var tile_position: Vector2i
var current_tile
var lives = 2
var previous_tile = [Vector2i(0,0), null]
var tile_map : TileMap
var steps_taken = 0
var game_over = false
var last_input
var shaking = false

func updateTilePos(updatePreviousPos=false):
	tile_position = tile_map.local_to_map(tile_map.to_local(position))
	if updatePreviousPos:
		previous_tile[1] = current_tile
		previous_tile[0] = tile_position
	current_tile = GameManager.Tiles[GameManager.Tiles.find_key(tile_map.get_cell_atlas_coords(0, tile_position).x)] if GameManager.Tiles.find_key(tile_map.get_cell_atlas_coords(0, tile_position).x) else GameManager.Tiles.VOID

func moveOnLastInputDirection(speed = 16, tweenType = "linear", time=0.6) -> Tween:
	var tween: Tween
	if last_input == Direction.LEFT:
		tween = tw.tw(self, time, {"position:x": position.x-speed*scale.x}, tweenType)
	if last_input == Direction.DOWN:
		tween = tw.tw(self, time, {"position:y": position.y+speed*scale.x}, tweenType)
	if last_input == Direction.UP:
		tween = tw.tw(self, time, {"position:y": position.y-speed*scale.x}, tweenType)
	if last_input == Direction.RIGHT:
		tween = tw.tw(self, time, {"position:x": position.x+speed*scale.x}, tweenType)
	return tween

func jump():
	SFX_Player.stream = SFX.jump
	SFX_Player.play()
	var tween:= moveOnLastInputDirection(32, "bounce", 0.45)

	tween.finished.connect(func() -> void:
		updateTilePos(true)
		if current_tile == GameManager.Tiles.VOID:
			SFX_Player.stream = SFX.fall
			SFX_Player.play()
			tw.tw(self, 1, {"scale:x"=0})
			tw.tw(self, 1, {"scale:y"=0})
			tw.tw(self, 1, {rotation=180})
			sprite.play("anxious_idle")
			lives = 0
			game_over = true
			death.emit()
			return;
		if current_tile == GameManager.Tiles.CORRUPT:
			jump()
			return;
		if current_tile == GameManager.Tiles.DECAYSTART:
			tile_map.set_cell(0, tile_position, 0, Vector2i(GameManager.Tiles.DECAYEND,0))
			updateTilePos(true)
			return;
		if current_tile == GameManager.Tiles.DECAYEND:
			SFX_Player.stream = SFX.fall
			SFX_Player.play()
			tile_map.erase_cell(0, tile_position)
			tw.tw(self, 1, {"scale:x"=0})
			tw.tw(self, 1, {"scale:y"=0})
			tw.tw(self, 1, {rotation=180})
			sprite.play("anxious_idle")
			lives = 0
			game_over = true
			death.emit()
			return;
		if current_tile == GameManager.Tiles.WALL and (last_input == Direction.RIGHT or last_input == Direction.DOWN):
			last_input += 2
			jump()
			return;
		if current_tile == GameManager.Tiles.WALL and (last_input == Direction.UP or last_input == Direction.LEFT):
			last_input -= 2
			jump()
			return;
		on_after_step()
	)
	
		

func on_before_step(_tilepos, _worldpos):
	steps_taken+=1
	SFX_Player.stream = SFX.move
	SFX_Player.play()
		
func on_after_step(_tilepos=0, _worldpos=0):
	if game_over:
		return;
	if previous_tile[1] == GameManager.Tiles.DECAYEND:
		tile_map.erase_cell(0, previous_tile[0])
	if previous_tile[1] == GameManager.Tiles.DECAYSTART:
		tile_map.set_cell(0, previous_tile[0], 0, Vector2i(6,0))
	if current_tile == GameManager.Tiles.SKIP:
		SFX_Player.stream = SFX.hurt
		SFX_Player.play()
		tile_map.set_cell(0, tile_position, 0, Vector2i(GameManager.Tiles.FLOOR, 0))
		before_step.emit(tile_position, position)
		movementTimer.start()
	if current_tile == GameManager.Tiles.TURNADD:
		SFX_Player.stream = SFX.turnadd
		SFX_Player.play()
		tile_map.set_cell(0, tile_position, 0, Vector2i(GameManager.Tiles.FLOOR, 0))
		max_steps += 2
	if current_tile == GameManager.Tiles.JUMP:
		jump()
	if current_tile == GameManager.Tiles.CORRUPT:
		hurt()
	if current_tile == GameManager.Tiles.SLIDE:
		SFX_Player.stream = SFX.slide
		SFX_Player.play()
		last_input = tile_map.get_cell_alternative_tile(0, tile_position)
		if tile_map.get_cell_atlas_coords(0,tile_map.get_neighbor_cell(tile_position, [TileSet.CELL_NEIGHBOR_RIGHT_SIDE, TileSet.CELL_NEIGHBOR_BOTTOM_SIDE, TileSet.CELL_NEIGHBOR_LEFT_SIDE, TileSet.CELL_NEIGHBOR_TOP_SIDE][last_input])).x == GameManager.Tiles.WALL or tile_map.get_cell_atlas_coords(0,tile_map.get_neighbor_cell(tile_position, [TileSet.CELL_NEIGHBOR_RIGHT_SIDE, TileSet.CELL_NEIGHBOR_BOTTOM_SIDE, TileSet.CELL_NEIGHBOR_LEFT_SIDE, TileSet.CELL_NEIGHBOR_TOP_SIDE][last_input])).x == GameManager.Tiles.CORRUPT:
			return;
		moveOnLastInputDirection(16, "linear", 0.15)
		slideTimer.start()
	if current_tile == GameManager.Tiles.GOAL:
		SFX_Player.stream = SFX.win
		SFX_Player.play()
		goal_reached.emit()
		tw.tw(self, 50, {"position:y"=position.y-9999})
		tw.tw(self, 1, {rotation=180})
		tw.tw(self, 1, {"scale:x"=0})
		tw.tw(self, 1, {"scale:y"=0})
		sprite.stop()

func hurt():
	if !get_node_or_null("%GameUI") and GameManager.background_music_currently_playing == "":
		GameManager.playBackgroundRaw(SFX.hurt)
		GameManager.switchScreen("res://Levels/Credits.tscn")
	SFX_Player.stream = SFX.hurt
	SFX_Player.play()
	sprite.play("hurt")
	lives -= 1
	shaking = true
	var timer := Timer.new()
	timer.wait_time = 1
	timer.autostart = true
	timer.one_shot = true
	add_child(timer)
	timer.timeout.connect(func()->void:
		shaking = false
		sprite.play("anxious_idle")
		if GameManager.background_music_currently_playing != "rush" or !get_node_or_null("%GameUI"): GameManager.playBackgroundMusic("level-fast")
		timer.queue_free()
		if lives <= 0:
			SFX_Player.stream = SFX.death
			SFX_Player.play()
			game_over = true
			sprite.play("death")
			death.emit()
	)

func _process(_delta):
	SFX_Player.volume_db = -80 + (0.4*(GameManager.volume*10))
	if shaking:
		position.x += randi_range(-1, 1)
		position.y += randi_range(-1, 1)

func _on_movement_timeout_timeout():
	sprite.play("idle")
	updateTilePos()
	for i in tile_map.get_surrounding_cells(tile_position):
		if tile_map.get_cell_atlas_coords(0, i).x == GameManager.Tiles.CORRUPT:
			if GameManager.background_music_currently_playing != "rush" and get_node_or_null("%GameUI"): GameManager.playBackgroundMusic("level-fast")
			sprite.play("anxious_idle")
	if steps_taken >= floor(max_steps / 1.15):
		if GameManager.background_music_currently_playing != "rush" and get_node_or_null("%GameUI"): GameManager.playBackgroundMusic("level-fast")
		sprite.play("anxious_idle")
	after_step.emit(tile_position, position)

func _ready():
	camera = get_node_or_null("Camera")
	tile_map = get_node_or_null("%TileMap")
	if !tile_map:
		GameManager.switchScreen("res://Levels/LevelError.tscn", GameManager.GameErrors.PLAYER_IN_NON_TILEMAP_LEVEL)
		return;
	if tile_map.has_signal("corruption_spread"):
		tile_map.corruption_spread.connect(func()->void:
			updateTilePos()
			if current_tile == GameManager.Tiles.CORRUPT:
				hurt()
			if current_tile == GameManager.Tiles.VOID:
				tw.tw(self, 1, {"scale:x"=0})
				tw.tw(self, 1, {"scale:y"=0})
				tw.tw(self, 1, {rotation=180})
				sprite.play("anxious_idle")
				lives = 0
				game_over = true
				death.emit()
		)
	connect("before_step", on_before_step)
	connect("after_step", on_after_step)
	updateTilePos()
	if camera:
		camera.limit_bottom = cameraLimits.bottom
		camera.limit_top = cameraLimits.top
		camera.limit_left = cameraLimits.left
		camera.limit_right = cameraLimits.right

func _unhandled_input(_event):

	if Input.is_action_pressed("_special") and camera:
		camera.offset.x += Input.get_axis("_left", "_right") * 32
		camera.offset.y += Input.get_axis("_up", "_down") * 32
		return
	
	if camera: camera.offset = Vector2(0,0)

	if steps_taken >= max_steps or shaking or game_over or current_tile == GameManager.Tiles.GOAL or !slideTimer.is_stopped() or !movementTimer.is_stopped():
		return;		

	if Input.is_action_just_pressed("_up") and !(GameManager.Tiles[GameManager.Tiles.find_key(tile_map.get_cell_atlas_coords(0, tile_map.get_neighbor_cell(tile_position, TileSet.CELL_NEIGHBOR_TOP_SIDE)).x)] == GameManager.Tiles.WALL or GameManager.Tiles[GameManager.Tiles.find_key(tile_map.get_cell_atlas_coords(0, tile_map.get_neighbor_cell(tile_position, TileSet.CELL_NEIGHBOR_TOP_SIDE)).x)] == GameManager.Tiles.VOID):
		last_input = Direction.UP
		sprite.play("look_up")
		before_step.emit(tile_position, position)
		updateTilePos(true)
		movementTimer.start()
		tw.tw(self, 0.15, {"position:y": position.y-16*scale.x})
		return
	if Input.is_action_just_pressed("_down") and !(GameManager.Tiles[GameManager.Tiles.find_key(tile_map.get_cell_atlas_coords(0, tile_map.get_neighbor_cell(tile_position, TileSet.CELL_NEIGHBOR_BOTTOM_SIDE)).x)] == GameManager.Tiles.WALL or GameManager.Tiles[GameManager.Tiles.find_key(tile_map.get_cell_atlas_coords(0, tile_map.get_neighbor_cell(tile_position, TileSet.CELL_NEIGHBOR_BOTTOM_SIDE)).x)] == GameManager.Tiles.VOID):
		last_input = Direction.DOWN
		sprite.play("look_down")
		before_step.emit(tile_position, position)
		updateTilePos(true)
		movementTimer.start()
		tw.tw(self, 0.15, {"position:y": position.y+16*scale.x})
		return
	if Input.is_action_just_pressed("_left") and !(GameManager.Tiles[GameManager.Tiles.find_key(tile_map.get_cell_atlas_coords(0, tile_map.get_neighbor_cell(tile_position, TileSet.CELL_NEIGHBOR_LEFT_SIDE)).x)] == GameManager.Tiles.WALL or GameManager.Tiles[GameManager.Tiles.find_key(tile_map.get_cell_atlas_coords(0, tile_map.get_neighbor_cell(tile_position, TileSet.CELL_NEIGHBOR_LEFT_SIDE)).x)] == GameManager.Tiles.VOID):
		last_input = Direction.LEFT
		sprite.play("look_left")
		before_step.emit(tile_position, position)
		updateTilePos(true)
		movementTimer.start()
		tw.tw(self, 0.15, {"position:x": position.x-16*scale.x})
		return
	if Input.is_action_just_pressed("_right")  and !(GameManager.Tiles[GameManager.Tiles.find_key(tile_map.get_cell_atlas_coords(0, tile_map.get_neighbor_cell(tile_position, TileSet.CELL_NEIGHBOR_RIGHT_SIDE)).x)] == GameManager.Tiles.WALL or GameManager.Tiles[GameManager.Tiles.find_key(tile_map.get_cell_atlas_coords(0, tile_map.get_neighbor_cell(tile_position, TileSet.CELL_NEIGHBOR_RIGHT_SIDE)).x)] == GameManager.Tiles.VOID):
		last_input = Direction.RIGHT
		sprite.play("look_right")
		before_step.emit(tile_position, position)
		updateTilePos(true)
		movementTimer.start()
		tw.tw(self, 0.15, {"position:x": position.x+16*scale.x})
		return
		
func _on_slide_timer_timeout():
	updateTilePos(true)
	if current_tile == GameManager.Tiles.VOID:
		SFX_Player.stream = SFX.fall
		SFX_Player.play()
		tw.tw(self, 1, {"scale:x"=0})
		tw.tw(self, 1, {"scale:y"=0})
		tw.tw(self, 1, {rotation=180})
		sprite.play("anxious_idle")
		lives = 0
		game_over = true
		death.emit()
		return
	if current_tile != GameManager.Tiles.FLOOR:
		on_after_step()
		return
	if tile_map.get_cell_atlas_coords(0,tile_map.get_neighbor_cell(tile_position, [TileSet.CELL_NEIGHBOR_RIGHT_SIDE, TileSet.CELL_NEIGHBOR_BOTTOM_SIDE, TileSet.CELL_NEIGHBOR_LEFT_SIDE, TileSet.CELL_NEIGHBOR_TOP_SIDE][last_input])).x == GameManager.Tiles.WALL or tile_map.get_cell_atlas_coords(0,tile_map.get_neighbor_cell(tile_position, [TileSet.CELL_NEIGHBOR_RIGHT_SIDE, TileSet.CELL_NEIGHBOR_BOTTOM_SIDE, TileSet.CELL_NEIGHBOR_LEFT_SIDE, TileSet.CELL_NEIGHBOR_TOP_SIDE][last_input])).x == GameManager.Tiles.CORRUPT:
		return;
	SFX_Player.stream = SFX.slide
	SFX_Player.play()
	moveOnLastInputDirection(16, "linear", 0.15)
	slideTimer.start()	
