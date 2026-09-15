class_name ProfileModalUI
extends Control

@onready var label_title: Label = $Panel/VBox/TitleLabel
@onready var label_stats: RichTextLabel = $Panel/VBox/StatsText
@onready var btn_close: Button = $Panel/VBox/BtnClose

func _ready() -> void:
	btn_close.pressed.connect(func(): visible = false)
	visible = false

func show_profile() -> void:
	visible = true
	var p = SaveData.data.get("player", {})
	var prog = SaveData.data.get("progression", {})
	var stats = p.get("stats", {})
	
	var lvl = int(p.get("level", 1))
	var xp = int(p.get("xp", 0))
	var coins = int(p.get("coins", 0))
	var wins = int(stats.get("wins", 0))
	var losses = int(stats.get("losses", 0))
	var total = int(stats.get("total_fights", 0))
	var max_combo = int(stats.get("max_combo", 0))
	var win_rate = float(wins) / float(max(1, total)) * 100.0
	
	label_title.text = "WARRIOR PROFILE: %s" % str(p.get("name", "KAGE"))
	
	var text = "[color=#ffd700]RANK & PROGRESSION[/color]\n"
	text += "- Level: [color=#00e5ff]%d[/color] | Experience: [color=#00e5ff]%d XP[/color]\n" % [lvl, xp]
	text += "- Treasury: [color=#ffd700]%d Monshu[/color]\n" % coins
	text += "- Active Province: [color=#ffffff]Chapter %d[/color]\n\n" % int(prog.get("current_chapter", 1))
	text += "[color=#ffd700]COMBAT RECORD[/color]\n"
	text += "- Total Duels: %d\n" % total
	text += "- Victories: [color=#4caf50]%d[/color] | Defeats: [color=#f44336]%d[/color]\n" % [wins, losses]
	text += "- Win Ratio: [color=#00e5ff]%.1f%%[/color]\n" % win_rate
	text += "- Peak Combo: [color=#ff9800]%d Hits[/color]\n" % max_combo
	
	label_stats.text = text
