extends Control

@export var scroll_speed: float = 50.0

@onready var credits_text: Label = $CreditsText

func _process(delta):
	credits_text.position.y -= scroll_speed * delta
