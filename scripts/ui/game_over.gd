extends Control

var game: GameManager

func bind(p_game: GameManager) -> void:
	game = p_game
	%RetryButton.pressed.connect(game.restart)
	%MenuButton.pressed.connect(game.back_to_menu)

func show_results(seconds: float, level: int, coins: int) -> void:
	var total := int(seconds)
	%TimeLabel.text = "Tempo: %02d:%02d" % [int(total / 60), total % 60]
	%LevelLabel.text = "Nivel: %d" % level
	%CoinsLabel.text = "Moedas: %d" % coins
	show()
