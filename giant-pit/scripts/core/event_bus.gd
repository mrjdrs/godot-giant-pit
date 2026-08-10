extends Node
## Autoload `EventBus`：转发到 GameBus。场景里也可 `EventBus.pub`。

func pub(event: StringName, payload: Dictionary = {}) -> void:
	GameBus.pub(event, payload)


func sub(event: StringName, target: Object, method: StringName) -> void:
	GameBus.sub(event, target, method)


func unsub(event: StringName, target: Object, method: StringName) -> void:
	GameBus.unsub(event, target, method)
