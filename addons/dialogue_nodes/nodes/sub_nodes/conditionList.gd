@tool
extends BoxContainer


signal modified

@onready var add_button: Button = $AddButton

const ConditionItemScene := preload('res://addons/dialogue_nodes/nodes/sub_nodes/ConditionItem.tscn')

var undo_redo: EditorUndoRedoManager


func _to_dict() -> Array[Dictionary]:
	var dict: Array[Dictionary] = []
	
	for child in get_children():
		if child is Button: continue
		dict.append(child._to_dict())
	
	return dict


func _from_dict(dict: Array[Dictionary]) -> void:
	for idx in range(dict.size()):
		var new_item = ConditionItemScene.instantiate()
		add_item(new_item, idx)
		new_item._from_dict(dict[idx])


func is_empty() -> bool:
	return (get_child_count() == 1) and (get_child(0) is Button)


func add_item(new_item: BoxContainer, to_idx := -1) -> void:
	if new_item.get_parent() != self: add_child(new_item, true)
	move_child(new_item, to_idx)
	
	new_item.undo_redo = undo_redo
	new_item.show_delete = true
	for idx in range(get_child_count() - 1):
		if get_child(idx) is Button: continue
		get_child(idx).is_last = false
	get_child(-2).is_last = true
	
	new_item.modified.connect(_on_modified)
	new_item.delete_requested.connect(_on_item_deleted.bind(new_item))


func remove_item(item: BoxContainer) -> void:
	item.modified.disconnect(_on_modified)
	item.delete_requested.disconnect(_on_item_deleted)
	
	if item.get_parent() == self: remove_child(item)
	
	for idx in range(get_child_count() - 1):
		if get_child(idx) is Button: continue
		get_child(idx).is_last = false
	if get_child_count() > 1:
		get_child(-2).is_last = true


func _on_add_button_pressed() -> void:
	var new_item := ConditionItemScene.instantiate()
	
	if not undo_redo:
		add_item(new_item, -2)
		return
	
	undo_redo.create_action('Add condition item')
	undo_redo.add_do_method(self, 'add_item', new_item, -2)
	undo_redo.add_do_method(self, '_on_modified')
	undo_redo.add_do_reference(new_item)
	undo_redo.add_undo_method(self, 'remove_item', new_item)
	undo_redo.add_undo_method(self, '_on_modified')
	undo_redo.commit_action()


func _on_item_deleted(item: BoxContainer) -> void:
	if not undo_redo:
		remove_item(item)
		return
	
	var idx = item.get_index()
	
	undo_redo.create_action('Remove condition item')
	undo_redo.add_do_method(self, 'remove_item', item)
	undo_redo.add_do_method(self, '_on_modified')
	undo_redo.add_undo_method(self, 'add_item', item, idx)
	undo_redo.add_undo_method(self, '_on_modified')
	undo_redo.commit_action()


func _on_modified() -> void:
	modified.emit()