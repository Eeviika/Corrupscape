extends CanvasLayer

var player : CharacterBody2D
@onready var stats: Label = $Stats
@onready var ofstext: Label = $OutOfSteps
@onready var gr_text: Label = $GoalReached
@onready var heart1: TextureRect = $heart1
@onready var heart2: TextureRect = $heart2


@export var level_number = 0
var time: float
var goal_reached := false

# Called when the node enters the scene tree for the first time.
func _ready():
	player = get_node_or_null("%Player")
	if !player:
		GameManager.switchScreen("res://Levels/LevelError.tscn", GameManager.GameErrors.GAME_UI_CANNOT_CONNECT_TO_PLAYER)
		return
	player.goal_reached.connect(func()->void:
		goal_reached = true
		gr_text.visible = true
		heart1.visible = false
		heart2.visible = false
		ofstext.visible = false
		if level_number < 14:
			GameManager.saveFile({"levelNumber": level_number+1})
		if level_number == 14:
			GameManager.stopBackgroundMusic()
	)
	if level_number <= 13:
		GameManager.playBackgroundMusic("level")
	if level_number == 14:
		GameManager.playBackgroundMusic("rush", true)

func _input(event):
	if event.is_action("_cancel"):
		GameManager.reloadScreen()
	if event.is_action("_confirm") and goal_reached:
		GameManager.switchScreen("res://Levels/Level{0}.tscn".format([level_number+1]))

func _process(_dt):
	if player.steps_taken < player.max_steps and !goal_reached:
		time += _dt
	if !player.game_over:
		stats.text = "LEVEL {0}\nSTEPS: {1} / {2}\nTIME: {3}:{4}".format([level_number, player.steps_taken, player.max_steps, floor(time/60), floor(int(time) % 60) if (floor(int(time)) % 60) >= 10 else "0" + str(floor(int(time)) % 60)])
	if player.lives == 2 and !goal_reached:
		heart1.visible = true
		heart2.visible = true
	if player.lives == 1 and !goal_reached:
		heart1.visible = false
	if player.lives <= 0 and goal_reached == false:
		heart1.visible = false
		heart2.visible = false
	if player.steps_taken >= player.max_steps and !goal_reached:
		ofstext.visible = true;
		heart1.visible = false
		heart2.visible = false
		ofstext.text = "OUT OF STEPS\n\nPress R (B) to restart"
	if player.game_over and !goal_reached:
		ofstext.visible = true;
		heart1.visible = false
		heart2.visible = false
		ofstext.text = "GAME OVER\n\nPress R (B) to restart"
