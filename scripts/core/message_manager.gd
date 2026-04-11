extends CanvasLayer

@onready var message_label: Label = $MessageLabel
@onready var hide_timer: Timer = $HideTimer

func _ready() -> void:
	message_label.text = ""
	message_label.hide()
	hide_timer.timeout.connect(_on_timer_timeout)

func show_message(msg: String, duration: float = 2.0) -> void:
	message_label.text = msg
	message_label.show()
	hide_timer.start(duration)

func _on_timer_timeout() -> void:
	message_label.hide()
