extends Node2D

@onready var start_button = %StartButton
@onready var new_game_button = %NewGameButton
@onready var continue_game_button = %ContinueGameButton
@onready var start_screen = $StartScreen
@onready var actual_buttons = $ActualButtons

# Called when the node enters the scene tree for the first time.
func _ready():
	GameManager.playBackgroundMusic("title", true)
	start_button.pressed.connect(func()->void:
		start_screen.visible = false
		actual_buttons.visible = true
		if GameManager.hasSaveFile(): get_node_or_null("%WarningNewGame").visible = true; continue_game_button.disabled = false;
	)
	new_game_button.pressed.connect(func()->void:
		GameManager.switchScreen("res://Levels/Level1.tscn")
	)
	continue_game_button.pressed.connect(func()->void:
		GameManager.switchScreen("res://Levels/Level{0}.tscn".format([GameManager.getSaveFile().levelNumber]))
	)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
