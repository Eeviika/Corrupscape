extends TileMap

var player : CharacterBody2D
var timer : Timer

signal corruption_spread()

func _ready():
	player = get_node_or_null("%Player")
	if !player:
		GameManager.switchScreen("res://Levels/LevelError.tscn", GameManager.GameErrors.CORRUPTION_IN_NON_PLAYER_LEVEL)
		return;
	player.connect("before_step", spread)
	timer = Timer.new()
	timer.autostart = true
	timer.one_shot = false
	timer.wait_time = 15
	add_child(timer)
	timer.connect("timeout", func()->void:
		spread()
		corruption_spread.emit()
	)
	timer.start()
	player.death.connect(func()->void:
		set_process(false)
		if timer != null:
			timer.queue_free()
	)

func spread(_tilepos=0, _worldpos=0):
	timer.start()
	if player.steps_taken >= player.max_steps:
		return;
	for i in get_used_cells_by_id(0, -1, Vector2i(7, 0)):
		var corrupttiles = 0
		for j in get_surrounding_cells(i):
			if get_cell_atlas_coords(0, j).x == GameManager.Tiles.CORRUPT or get_cell_atlas_coords(0, j).x == GameManager.Tiles.WALL or get_cell_atlas_coords(0, j).x == GameManager.Tiles.VOID:
				corrupttiles += 1
				if corrupttiles >= 4:
					erase_cell(0, i)
					break
				continue
			if get_cell_atlas_coords(0, j).x == GameManager.Tiles.DECAYSTART:
				set_cell(0, j, 0, Vector2(6,0))
				continue
			if get_cell_atlas_coords(0, j).x == GameManager.Tiles.DECAYEND:
				erase_cell(0, j)
				continue
			if !(get_cell_atlas_coords(0, j).x == GameManager.Tiles.WALL or get_cell_atlas_coords(0, j).x == GameManager.Tiles.VOID or get_cell_atlas_coords(0, j).x == GameManager.Tiles.GOAL):
				set_cell(0, j, 0, Vector2i(7,0))
