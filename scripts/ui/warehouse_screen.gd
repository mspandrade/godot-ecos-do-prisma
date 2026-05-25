extends Control

@onready var material_list: VBoxContainer = %MaterialList
@onready var material_total_label: Label = %MaterialTotalLabel
@onready var equipment_label: Label = %EquipmentLabel

func _ready() -> void:
	%BackButton.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/ui/GuildScene.tscn"))
	GameData.materials_changed.connect(_refresh)
	GameData.equipment_changed.connect(_refresh)
	_refresh()

func _refresh() -> void:
	for child in material_list.get_children():
		child.queue_free()
	var materials := GameData.get_materials()
	var total := 0
	for amount in materials.values():
		total += int(amount)
	material_total_label.text = "Materiais armazenados: %d" % total
	equipment_label.text = "Equipamentos guardados: %d" % GameData.get_equipment_inventory().size()
	if materials.is_empty():
		var empty := Label.new()
		empty.text = "Nenhum material coletado."
		material_list.add_child(empty)
		return
	var ids := materials.keys()
	ids.sort()
	for material_id in ids:
		var row := HBoxContainer.new()
		var name := Label.new()
		name.text = GameData.get_material_name(str(material_id))
		name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var amount := Label.new()
		amount.text = "x%d" % int(materials[material_id])
		row.add_child(name)
		row.add_child(amount)
		material_list.add_child(row)
