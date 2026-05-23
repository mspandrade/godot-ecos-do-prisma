extends Control

@onready var coins_label: Label = %CoinsLabel
@onready var companion_option: OptionButton = %CompanionOption
@onready var craft_list: VBoxContainer = %CraftList
@onready var inventory_list: VBoxContainer = %InventoryList

var selected_companion_id := ""

func _ready() -> void:
	%BackButton.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/ui/GuildScene.tscn"))
	companion_option.item_selected.connect(_select_companion)
	GameData.coins_changed.connect(func(_coins: int): _refresh())
	GameData.companion_roster_changed.connect(_refresh)
	GameData.equipment_changed.connect(_refresh)
	_pick_default_companion()
	_refresh()

func _pick_default_companion() -> void:
	var roster := GameData.get_companion_roster()
	for companion_id in roster.keys():
		var data: Dictionary = roster[companion_id]
		if str(data.get("state", "disponivel")) != "morto":
			selected_companion_id = str(companion_id)
			return
	selected_companion_id = ""

func _refresh() -> void:
	coins_label.text = "Moedas: %d" % GameData.coins
	_refresh_companion_options()
	_refresh_craft_list()
	_refresh_inventory_list()

func _refresh_companion_options() -> void:
	companion_option.clear()
	var roster := GameData.get_companion_roster()
	var selected_index := -1
	for companion_id in roster.keys():
		var data: Dictionary = roster[companion_id]
		if str(data.get("state", "disponivel")) == "morto":
			continue
		var index := companion_option.get_item_count()
		companion_option.add_item("%s | %s" % [str(data.get("name", companion_id)), str(data.get("class_name", data.get("class", "")))])
		companion_option.set_item_metadata(index, str(companion_id))
		if str(companion_id) == selected_companion_id:
			selected_index = index
	if selected_index == -1 and companion_option.get_item_count() > 0:
		selected_index = 0
		selected_companion_id = str(companion_option.get_item_metadata(0))
	if selected_index >= 0:
		companion_option.select(selected_index)

func _refresh_craft_list() -> void:
	for child in craft_list.get_children():
		child.queue_free()
	var defs := GameData.get_equipment_defs()
	for equipment_id in defs.keys():
		var def: Dictionary = defs[equipment_id]
		var row := VBoxContainer.new()
		row.custom_minimum_size = Vector2(0, 88)
		var title := Label.new()
		title.text = "%s | %s" % [str(def.get("name", equipment_id)), str(def.get("slot", ""))]
		title.add_theme_font_size_override("font_size", 17)
		var details := Label.new()
		details.text = "%s | %d moedas" % [str(def.get("effect", "")), int(def.get("cost", 0))]
		var button := Button.new()
		var cost := int(def.get("cost", 0))
		button.text = "Forjar - %d moedas" % cost if GameData.coins >= cost else "Faltam %d moedas" % (cost - GameData.coins)
		button.disabled = GameData.coins < cost
		button.pressed.connect(_craft.bind(str(equipment_id)))
		row.add_child(title)
		row.add_child(details)
		row.add_child(button)
		craft_list.add_child(row)

func _refresh_inventory_list() -> void:
	for child in inventory_list.get_children():
		child.queue_free()
	var inventory := GameData.get_equipment_inventory()
	if inventory.is_empty():
		var empty := Label.new()
		empty.text = "Nenhum equipamento forjado."
		inventory_list.add_child(empty)
		return
	var defs := GameData.get_equipment_defs()
	for item_value in inventory:
		var item: Dictionary = item_value
		var equipment_id := str(item.get("equipment_id", ""))
		var def: Dictionary = defs.get(equipment_id, {})
		var row := VBoxContainer.new()
		row.custom_minimum_size = Vector2(0, 96)
		var title := Label.new()
		title.text = "%s | %s" % [str(def.get("name", equipment_id)), str(def.get("effect", ""))]
		var equipped_to := str(item.get("equipped_to", ""))
		var state := Label.new()
		state.text = _item_state_text(equipped_to)
		var button := Button.new()
		button.text = _inventory_button_text(equipped_to)
		button.disabled = selected_companion_id.is_empty() or (not equipped_to.is_empty() and equipped_to != selected_companion_id)
		if equipped_to == selected_companion_id:
			button.pressed.connect(_unequip.bind(str(item.get("uid", ""))))
		else:
			button.pressed.connect(_equip.bind(str(item.get("uid", ""))))
		row.add_child(title)
		row.add_child(state)
		row.add_child(button)
		inventory_list.add_child(row)

func _item_state_text(equipped_to: String) -> String:
	if equipped_to.is_empty():
		return "Disponivel"
	var roster := GameData.get_companion_roster()
	if roster.has(equipped_to):
		return "Equipado: %s" % str(roster[equipped_to].get("name", equipped_to))
	return "Equipado"

func _inventory_button_text(equipped_to: String) -> String:
	if equipped_to == selected_companion_id:
		return "Desequipar"
	if equipped_to.is_empty():
		return "Equipar"
	return "Equipado por outro companion"

func _select_companion(index: int) -> void:
	selected_companion_id = str(companion_option.get_item_metadata(index))
	_refresh_inventory_list()

func _craft(equipment_id: String) -> void:
	if not GameData.craft_equipment(equipment_id):
		_refresh()

func _equip(item_uid: String) -> void:
	if not GameData.equip_companion_item(selected_companion_id, item_uid):
		_refresh()

func _unequip(item_uid: String) -> void:
	if not GameData.unequip_companion_item(item_uid):
		_refresh()
