extends Control

var game: GameManager

func bind(p_game: GameManager) -> void:
	game = p_game
	%RetryButton.pressed.connect(game.restart)
	%MenuButton.pressed.connect(game.back_to_menu)

func show_results(seconds: float, level: int, coins: int, result_reason: String = "derrota", gross_coins: int = -1, mission_result: Dictionary = {}, companion_result: Dictionary = {}) -> void:
	var total := int(seconds)
	match result_reason:
		"fuga":
			%Title.text = "Fuga concluida"
		"vitoria":
			%Title.text = "Missao concluida"
		_:
			%Title.text = "Fim da run"
	%RetryButton.visible = result_reason == "derrota"
	%TimeLabel.text = "Tempo: %02d:%02d" % [int(total / 60), total % 60]
	%LevelLabel.text = "Nivel: %d" % level
	if result_reason == "fuga" and gross_coins > coins:
		%CoinsLabel.text = "Moedas: %d de %d" % [coins, gross_coins]
	else:
		%CoinsLabel.text = "Moedas: %d" % coins
	%OutcomeLabel.text = _format_outcome(result_reason, mission_result, companion_result)
	show()

func _format_outcome(result_reason: String, mission_result: Dictionary, companion_result: Dictionary = {}) -> String:
	var lines := []
	match result_reason:
		"vitoria":
			var xp_per_companion := int(mission_result.get("xp_per_companion", 0))
			if xp_per_companion > 0:
				lines.append("XP da missao: +%d por companion" % xp_per_companion)
			var leveled_companions: Array = mission_result.get("leveled_companions", [])
			if leveled_companions.size() > 0:
				lines.append("Subiram de nivel: %s" % ", ".join(leveled_companions))
			var unlocked_zone_names: Array = mission_result.get("unlocked_zone_names", [])
			if unlocked_zone_names.size() > 0:
				lines.append("Nova zona: %s" % ", ".join(unlocked_zone_names))
		"fuga":
			lines.append("Missao incompleta. O esquadrao voltou para a guilda.")
		_:
			lines.append("Missao fracassada. O esquadrao voltou para a guilda.")
	if bool(mission_result.get("reroll_reset", false)):
		lines.append("Fila de recrutamento renovada.")
	var wounded_companions: Array = companion_result.get("wounded_companions", [])
	if wounded_companions.size() > 0:
		lines.append("Feridos: %s" % ", ".join(wounded_companions))
	var dead_companions: Array = companion_result.get("dead_companions", [])
	if dead_companions.size() > 0:
		lines.append("Mortos: %s" % ", ".join(dead_companions))
	if lines.is_empty():
		lines.append("Retorno registrado na guilda.")
	return "\n".join(lines)
