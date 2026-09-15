class_name TrainingUI
extends Control

signal return_to_dojo()
signal reset_dummy_requested()

@onready var btn_back: Button = $TopHeader/BtnBack
@onready var btn_reset: Button = $TopHeader/BtnReset
@onready var btn_moves: Button = $TopHeader/BtnMoves

@onready var label_damage: Label = $Diagnostics/DamageLabel
@onready var label_combo: Label = $Diagnostics/ComboLabel

@onready var modal_moves: Control = $MoveListModal
@onready var btn_close_moves: Button = $MoveListModal/Panel/VBox/BtnClose

func _ready() -> void:
	btn_back.pressed.connect(func(): return_to_dojo.emit())
	btn_reset.pressed.connect(func(): reset_dummy_requested.emit())
	btn_moves.pressed.connect(func(): modal_moves.visible = true)
	btn_close_moves.pressed.connect(func(): modal_moves.visible = false)
	modal_moves.visible = false

func update_diagnostics(last_dmg: float, combo_hits: int) -> void:
	if label_damage:
		label_damage.text = "LAST STRIKE: %.1f DMG" % last_dmg
	if label_combo:
		label_combo.text = "COMBO: %d HITS" % combo_hits
