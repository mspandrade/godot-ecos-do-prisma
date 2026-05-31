extends Control

const MedievalUI := preload("res://scripts/ui/components/medieval_ui.gd")

var game: GameManager

func bind(p_game: GameManager) -> void:
	MedievalUI.apply_tree(self)
	game = p_game
	%ContinueButton.pressed.connect(game.resume_game)
	%RestartButton.pressed.connect(game.restart)
	%MenuButton.pressed.connect(game.back_to_menu)

