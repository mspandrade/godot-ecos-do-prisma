extends RefCounted
class_name EntitySpriteAtlas

const TEXTURE_PATH := "res://assets/sprites/entities/IsometricTRPGAssetPack_Entities.png"
const ATLAS_PATH := "res://assets/sprites/entities/outlined_entities_atlas.json"

static var _atlas: Dictionary = {}
static var _texture: Texture2D

static func apply(sprite: Sprite2D, sprite_name: String) -> void:
	if not sprite:
		return
	var entry: Dictionary = get_sprite(sprite_name)
	if entry.is_empty():
		push_warning("Entity sprite not found: %s" % sprite_name)
		return
	sprite.texture = get_texture()
	sprite.region_enabled = true
	sprite.region_rect = Rect2(
		float(entry["x"]),
		float(entry["y"]),
		float(entry["w"]),
		float(entry["h"])
	)
	sprite.centered = true

static func apply_entity_frame(sprite: Sprite2D, type_name: String, facing: String, action: String, frame: int) -> void:
	apply(sprite, "%s_%s_%s_%d" % [type_name, facing, action, frame])

static func get_sprite(sprite_name: String) -> Dictionary:
	var sprites: Dictionary = _get_atlas().get("sprites", {})
	return sprites.get(sprite_name, {})

static func names_for_type(type_name: String) -> Array:
	var groups: Dictionary = _get_atlas().get("groups", {})
	return groups.get(type_name, [])

static func get_texture() -> Texture2D:
	if not _texture:
		_texture = load(TEXTURE_PATH)
	return _texture

static func _get_atlas() -> Dictionary:
	if not _atlas.is_empty():
		return _atlas
	if not FileAccess.file_exists(ATLAS_PATH):
		push_warning("Entity sprite atlas missing: %s" % ATLAS_PATH)
		return {}
	var file: FileAccess = FileAccess.open(ATLAS_PATH, FileAccess.READ)
	if not file:
		push_warning("Could not open entity sprite atlas: %s" % ATLAS_PATH)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) == TYPE_DICTIONARY:
		_atlas = parsed
	return _atlas
