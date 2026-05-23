extends Control

var game: GameManager

func bind(p_game: GameManager) -> void:
	game = p_game
	%RetryButton.pressed.connect(game.restart)
	%MenuButton.pressed.connect(game.back_to_menu)

func show_results(seconds: float, level: int, coins: int, result_reason: String = "derrota", gross_coins: int = -1) -> void:
	var total := int(seconds)
	match result_reason:
		"fuga":
			%Title.text = "Fuga concluida"
		"vitoria":
			%Title.text = "Missao concluida"
		_:
			%Title.text = "Fim da run"
	%TimeLabel.text = "Tempo: %02d:%02d" % [int(total / 60), total % 60]
	%LevelLabel.text = "Nivel: %d" % level
	if result_reason == "fuga" and gross_coins > coins:
		%CoinsLabel.text = "Moedas: %d de %d" % [coins, gross_coins]
	else:
		%CoinsLabel.text = "Moedas: %d" % coins
	show()
