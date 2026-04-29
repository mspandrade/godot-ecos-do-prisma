extends Control

var upgrade_manager: UpgradeManager
var buttons: Array[Button] = []
var choices := []

func bind(manager: UpgradeManager) -> void:
	upgrade_manager = manager
	buttons = [%ChoiceA, %ChoiceB, %ChoiceC]
	for i in range(buttons.size()):
		buttons[i].pressed.connect(_choose.bind(i))

func show_choices(p_choices: Array) -> void:
	choices = p_choices
	for i in range(buttons.size()):
		var button := buttons[i]
		if i < choices.size():
			var up: Dictionary = choices[i]
			button.text = "%s\n%s" % [up["name"], up["desc"]]
			button.show()
		else:
			button.hide()
	show()

func _choose(index: int) -> void:
	if index >= choices.size():
		return
	upgrade_manager.apply_upgrade(choices[index])
	get_tree().current_scene.continue_after_upgrade()
