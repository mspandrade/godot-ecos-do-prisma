extends RefCounted
class_name ScenePool

var items: Array[Node] = []

func build(parent: Node, scene: PackedScene, size: int, recycled_callback: Callable = Callable()) -> void:
	items.clear()
	for i in range(size):
		var instance := scene.instantiate()
		parent.add_child(instance)
		if recycled_callback.is_valid() and instance.has_signal("recycled"):
			instance.recycled.connect(recycled_callback)
		items.append(instance)

func acquire() -> Node:
	for item in items:
		if not bool(item.get("active")):
			return item
	return null
