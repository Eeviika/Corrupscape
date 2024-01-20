extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
	var tmr = Timer.new()
	tmr.wait_time = 2
	tmr.autostart = true
	tmr.timeout.connect(func()->void:
		GameManager.playBackgroundMusic("truth")
		tmr.queue_free()
	)
	add_child(tmr)
	tw.tw(self, 100, {"position:y"=-3500})

func _input(event):
	if event.is_action_pressed("_cancel"):
		GameManager.switchScreen("res://Levels/MainMenu.tscn")


