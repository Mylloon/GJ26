extends Node

var arrow = load("res://assets/cursor/cursor_idle.png")
var hover = load("res://assets/cursor/cursor_hover.png")
var clicked = load("res://assets/cursor/cursor_clic.png")


func _ready():
	Input.set_custom_mouse_cursor(hover, Input.CURSOR_POINTING_HAND)
	Input.set_custom_mouse_cursor(clicked, Input.CURSOR_DRAG)

	Input.set_custom_mouse_cursor(arrow, Input.CURSOR_ARROW)


func _process(_delta):
	var click = "left_click"
	if Input.is_action_just_pressed(click):
		Input.set_custom_mouse_cursor(clicked, Input.CURSOR_ARROW)

	if Input.is_action_just_released(click):
		Input.set_custom_mouse_cursor(arrow, Input.CURSOR_ARROW)
