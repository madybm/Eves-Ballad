extends Control

const NOTE_COLORS = {
	"G": Color("57a65a"),
	"A": Color("e8c44a"),
	"B": Color("5b8dd9"),
	"C": Color("d95b5b"),
	"D": Color("9b59b6"),
}

const KEY_MAP = {
	"s": "G", "d": "A", "a": "B", "w": "C", "e": "D"
}

# Vertical position on staff (0=top, 1=bottom) — G at bottom, D at top
const NOTE_Y = {
	"D": 0.15,
	"C": 0.30,
	"B": 0.50,
	"A": 0.65,
	"G": 0.80,
}


const NOTE_FREQ = {
	"G": 392.00,
	"A": 440.00,
	"B": 493.88,
	"C": 523.25,
	"D": 587.33,
}
const TRAVEL_TIME = 3.0
const NOTE_RADIUS = 30.0    # seconds to cross from right to strike zone
const SPAWN_INTERVAL = 1.0     # seconds between notes
const STRIKE_X_RATIO = 0.85
const PERFECT_WINDOW = 0.08
const GOOD_WINDOW = 0.20    # ±12% of staff width

var note_players: Dictionary = {}
var melody: Array = []
var note_index: int = 0
var loop: int = 1
var player_hp: int = 12        # 12 rays + 1 core = 13 total
var wolf_hp: float = 8.0
var active_notes: Array = []
var spawn_timer: float = 0.0
var combo: int = 0
var combo_cooldown: int = 0
var staff_w: float = 0.0
var staff_h: float = 0.0
var strike_x: float = 0.0

# Sun rays (HP visualization)
var ray_nodes: Array = []

@onready var staff = $VBoxContainer/Staff
@onready var player_hp_label = $VBoxContainer/StatsBar/PlayerHP
@onready var loop_label = $VBoxContainer/StatsBar/LoopCounter
@onready var wolf_hp_label = $VBoxContainer/StatsBar/WolfHP
@onready var flee_button = $VBoxContainer/BottomBar/FleeButton
@onready var key_legend = $VBoxContainer/BottomBar/KeyLegend

func _ready():
	melody = Global.melody.duplicate()
	if melody.size() == 0:
		melody = ["A", "B", "A", "C", "B", "A", "D", "A"]  # fallback
	flee_button.pressed.connect(_on_flee_pressed)
	key_legend.text = "G·S   A·D   B·A   C·W   D·E"
	await get_tree().process_frame
	staff_w = staff.size.x
	staff_h = staff.size.y
	strike_x = staff_w * STRIKE_X_RATIO
	_setup_staff()
	_update_stats()
	# Panel background
	var style = StyleBoxFlat.new()
	style.bg_color = Color("1a1a2e")
	style.border_color = Color("444466")
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_width_left = 2
	style.border_width_right = 2
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	add_theme_stylebox_override("panel", style)
	_build_audio()

func _setup_staff():
	# 5 horizontal staff lines
	for i in 5:
		var line = ColorRect.new()
		line.color = Color(1, 1, 1, 0.12)
		line.size = Vector2(staff_w, 1)
		line.position = Vector2(0, staff_h * (0.2 + i * 0.15))
		staff.add_child(line)

	# Strike zone vertical line
	var sz = ColorRect.new()
	sz.color = Color(1, 0.85, 0.3, 0.6)
	sz.size = Vector2(3, staff_h)
	sz.position = Vector2(strike_x, 0)
	staff.add_child(sz)

	# Strike zone glow band
	var glow = ColorRect.new()
	glow.color = Color(1, 0.85, 0.3, 0.07)
	glow.size = Vector2(staff_w * GOOD_WINDOW * 2, staff_h)
	glow.position = Vector2(strike_x - staff_w * GOOD_WINDOW, 0)
	staff.add_child(glow)

	# Strike label
	var lbl = Label.new()
	lbl.text = "strike"
	lbl.position = Vector2(strike_x + 6, 4)
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.add_theme_color_override("font_color", Color(1, 0.85, 0.3, 0.7))
	staff.add_child(lbl)

	# Note labels on left (pitch guide)
	for note_name in NOTE_Y:
		var nlbl = Label.new()
		nlbl.text = note_name
		nlbl.position = Vector2(4, staff_h * NOTE_Y[note_name] - 10)
		nlbl.add_theme_font_size_override("font_size", 11)
		nlbl.add_theme_color_override("font_color", NOTE_COLORS[note_name])
		staff.add_child(nlbl)

func _process(delta: float):
	if melody.size() == 0:
		return

	spawn_timer -= delta
	if spawn_timer <= 0.0:
		_spawn_note()
		spawn_timer = SPAWN_INTERVAL

	# Move notes right to left
	var to_remove = []
	for entry in active_notes:
		entry.progress += delta / TRAVEL_TIME
		var x = -NOTE_RADIUS + (staff_w + NOTE_RADIUS * 2) * entry.progress
		entry.node.position.x = x - NOTE_RADIUS

		# Missed — passed strike zone with no input
		if entry.progress > STRIKE_X_RATIO + GOOD_WINDOW + 0.05 and not entry.hit:
			to_remove.append(entry)

	for entry in to_remove:
		_on_miss(entry)

func _spawn_note():
	var note_name = melody[note_index % melody.size()]
	var is_wolf_attack = (note_index % melody.size()) == melody.size() - 1
	note_index += 1

	if note_index % melody.size() == 0:
		loop += 1
		_update_stats()

	var y = staff_h * NOTE_Y[note_name] - NOTE_RADIUS

	var circle = Panel.new()
	circle.custom_minimum_size = Vector2(NOTE_RADIUS * 2, NOTE_RADIUS * 2)
	circle.position = Vector2(staff_w, y)

	var style = StyleBoxFlat.new()
	style.bg_color = NOTE_COLORS[note_name] if not is_wolf_attack else Color("cc3333")
	style.corner_radius_top_left = NOTE_RADIUS
	style.corner_radius_top_right = NOTE_RADIUS
	style.corner_radius_bottom_left = NOTE_RADIUS
	style.corner_radius_bottom_right = NOTE_RADIUS
	circle.add_theme_stylebox_override("panel", style)

	var lbl = Label.new()
	lbl.text = note_name
	lbl.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	lbl.add_theme_color_override("font_color", Color.WHITE)
	circle.add_child(lbl)

	# Key hint below note
	var key_lbl = Label.new()
	key_lbl.text = _get_key_for_note(note_name).to_upper()
	key_lbl.position = Vector2(NOTE_RADIUS - 5, NOTE_RADIUS * 2 + 2)
	key_lbl.add_theme_font_size_override("font_size", 10)
	key_lbl.add_theme_color_override("font_color", Color(1, 1, 1, 0.6))
	circle.add_child(key_lbl)

	if is_wolf_attack:
		var atk_lbl = Label.new()
		atk_lbl.text = "wolf bites"
		atk_lbl.position = Vector2(-10, -20)
		atk_lbl.add_theme_font_size_override("font_size", 10)
		atk_lbl.add_theme_color_override("font_color", Color("ff6666"))
		circle.add_child(atk_lbl)

	staff.add_child(circle)
	active_notes.append({
		node = circle,
		note_name = note_name,
		progress = 0.0,
		hit = false,
		is_wolf_attack = is_wolf_attack
	})

func _get_key_for_note(note_name: String) -> String:
	for k in KEY_MAP:
		if KEY_MAP[k] == note_name:
			return k
	return ""

func _input(event: InputEvent):
	if not event is InputEventKey or not event.pressed:
		return
	var key = OS.get_keycode_string(event.keycode).to_lower()
	if key in KEY_MAP:
		_try_hit(KEY_MAP[key])

func _try_hit(pressed_note: String):
	var best = null
	var best_dist = 9999.0
	for entry in active_notes:
		if entry.hit:
			continue
		# progress goes 0->1 right to left, strike zone is at STRIKE_X_RATIO from left
		# so note reaches strike zone when progress = 1.0 - STRIKE_X_RATIO
		var dist = abs(entry.progress - STRIKE_X_RATIO)
		if dist < best_dist:
			best_dist = dist
			best = entry

	if best == null:
		return

	if best_dist > GOOD_WINDOW:
		return

	if best.note_name != pressed_note:
		_take_damage(1)
		_flash_wrong(best)
		_reset_combo()
		return

	var is_perfect = best_dist <= PERFECT_WINDOW
	best.hit = true
	best.node.queue_free()
	active_notes.erase(best)
	if best.note_name in note_players:
		note_players[best.note_name].play()

	var base_dmg = 0.5 if is_perfect else 0.25
	var combo_mult = _get_combo_mult()
	wolf_hp -= base_dmg * combo_mult

	if is_perfect:
		if combo_cooldown > 0:
			combo_cooldown -= 1
		else:
			combo += 1
	else:
		_reset_combo()

	_update_stats()
	if wolf_hp <= 0:
		_end_combat(true)

func _get_combo_mult() -> float:
	if combo >= 24: return 2.5
	if combo >= 16: return 2.0
	if combo >= 8:  return 1.5
	if combo >= 4:  return 1.25
	return 1.0

func _reset_combo():
	var lost_tier = 0
	if combo >= 24: lost_tier = 4
	elif combo >= 16: lost_tier = 3
	elif combo >= 8: lost_tier = 2
	elif combo >= 4: lost_tier = 1
	combo_cooldown = lost_tier * 2
	combo = 0

func _on_miss(entry: Dictionary):
	if entry.is_wolf_attack:
		_take_damage(2)
	else:
		_take_damage(1)
	entry.node.queue_free()
	active_notes.erase(entry)
	_reset_combo()
	_update_stats()

func _take_damage(amount: int):
	player_hp = max(0, player_hp - amount)
	if player_hp <= 0:
		_end_combat(false)

func _flash_wrong(entry: Dictionary):
	# Brief red flash on wrong key
	var style = StyleBoxFlat.new()
	style.bg_color = Color("ff0000")
	style.corner_radius_top_left = NOTE_RADIUS
	style.corner_radius_top_right = NOTE_RADIUS
	style.corner_radius_bottom_left = NOTE_RADIUS
	style.corner_radius_bottom_right = NOTE_RADIUS
	entry.node.add_theme_stylebox_override("panel", style)

func _update_stats():
	player_hp_label.text = "♥ " + str(player_hp) + " / 12"
	loop_label.text = "Loop " + str(loop)
	wolf_hp_label.text = "🐺 " + str(snapped(wolf_hp, 0.1))
	var combo_text = ""
	if combo >= 24: combo_text = " ✦ Enchanted"
	elif combo >= 16: combo_text = " ✦ Charm"
	elif combo >= 8: combo_text = " ✦ Harmony"
	elif combo >= 4: combo_text = " ✦ Resonance"
	loop_label.text += combo_text

func _on_flee_pressed():
	get_tree().change_scene_to_file("res://scenes/melody_crafter.tscn")

func _end_combat(won: bool):
	# Disable input
	set_process(false)
	set_process_input(false)
	
	# Show result
	var result = Panel.new()
	result.custom_minimum_size = Vector2(300, 150)
	result.position = Vector2(staff_w / 2 - 150, staff_h / 2 - 75)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color("1e1e2e")
	style.border_color = Color("444466")
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_width_left = 2
	style.border_width_right = 2
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	result.add_theme_stylebox_override("panel", style)
	
	var lbl = Label.new()
	lbl.text = "🎵 The wolf is calmed!" if won else "💀 Magdalene fell..."
	lbl.position = Vector2(20, 30)
	lbl.add_theme_color_override("font_color", Color.WHITE)
	result.add_child(lbl)
	
	var btn = Button.new()
	btn.text = "Return to crafter"
	btn.position = Vector2(50, 90)
	btn.size = Vector2(200, 40)
	btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/melody_crafter.tscn"))
	result.add_child(btn)
	
	staff.add_child(result)
func _build_audio():
	for note_name in NOTE_FREQ:
		var freq = NOTE_FREQ[note_name]
		var player = AudioStreamPlayer.new()
		player.stream = _make_flute_tone(freq)
		player.volume_db = -6.0
		add_child(player)
		note_players[note_name] = player

func _make_flute_tone(freq: float) -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 0.6
	var num_samples = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(num_samples * 2)  # 16-bit mono

	for i in num_samples:
		var t = float(i) / sample_rate
		# Envelope — quick attack, slow decay
		var env = 0.0
		var attack = 0.04
		var decay = 0.3
		if t < attack:
			env = t / attack
		else:
			env = exp(-(t - attack) / decay)

		# Flute harmonics — fundamental + 2nd + 3rd with breath noise
		var s = 0.0
		s += sin(2.0 * PI * freq * t) * 0.6          # fundamental
		s += sin(2.0 * PI * freq * 2.0 * t) * 0.25   # 2nd harmonic
		s += sin(2.0 * PI * freq * 3.0 * t) * 0.1    # 3rd harmonic
		s += randf_range(-0.04, 0.04)                  # breath noise

		s *= env
		# Clamp and convert to 16-bit
		var sample = int(clamp(s, -1.0, 1.0) * 32767)
		data[i * 2] = sample & 0xFF
		data[i * 2 + 1] = (sample >> 8) & 0xFF

	var stream = AudioStreamWAV.new()
	stream.data = data
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	return stream
