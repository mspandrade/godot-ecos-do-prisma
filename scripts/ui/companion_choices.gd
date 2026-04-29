extends Control

var companion_manager: Node
var companion: Node
var choices := []
var buttons: Array[Button] = []

func bind(manager: Node) -> void:
	companion_manager = manager
	buttons = [%ChoiceA, %ChoiceB, %ChoiceC]
	for i in range(buttons.size()):
		buttons[i].pressed.connect(_choose.bind(i))

func show_choices(p_companion: Node, p_choices: Array) -> void:
	companion = p_companion
	choices = p_choices
	%Title.text = "%s subiu para o nivel %d" % [companion.display_name, companion.level]
	for i in range(buttons.size()):
		var button := buttons[i]
		if i < choices.size():
			var choice: Dictionary = choices[i]
			button.text = "%s\n%s" % [choice["name"], choice["desc"]]
			button.show()
		else:
			button.hide()
	show()

func _choose(index: int) -> void:
	if index >= choices.size():
		return
	companion_manager.apply_companion_upgrade(companion, choices[index])
	get_tree().current_scene.continue_after_companion_upgrade()
