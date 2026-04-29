extends Control

var game: GameManager

func bind(p_game: GameManager) -> void:
	game = p_game
	%ContinueButton.pressed.connect(game.resume_game)
	%RestartButton.pressed.connect(game.restart)
	%MenuButton.pressed.connect(game.back_to_menu)

