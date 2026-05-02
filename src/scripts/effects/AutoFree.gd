extends CPUParticles2D

## Auto-frees this node after its particle lifetime expires.
## Attach to one-shot CPUParticles2D effect scenes.

func _ready() -> void:
	await get_tree().create_timer(lifetime + 0.1).timeout
	queue_free()
