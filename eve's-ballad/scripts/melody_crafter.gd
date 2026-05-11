extends Control

const NOTES = [
	{name = "G", key = "s", color = Color("57a65a")},
	{name = "A", key = "d", color = Color("e8c44a")},
	{name = "B", key = "a", color = Color("5b8dd9")},
	{name = "C", key = "w", color = Color("d95b5b")},
	{name = "D", key = "e", color = Color("9b59b6")},
]

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

const MAX_SLOTS = 8
const NOTE_RADIUS = 22.0

var note_players: Dictionary = {}
var melody: Array = []
var note_colors: Dictionary = {}
var previewing: bool = false
var preview_index: int = 0
var preview_timer: float = 0.0

@onready var staff = $VBoxContainer/Staff
@onready var note_inventory = $VBoxContainer/BottomBar/NoteInventory
@onready var begin_button = $VBoxContainer/BottomBar/BeginButton
@onready var counter_label = $VBoxContainer/CounterLabel
@onready var preview_button = $VBoxContainer/BottomBar/PreviewButton

func _ready():
	for note in NOTES:
		note_colors[note.name] = note.color
	_build_inventory()
	begin_button.disabled = true
	begin_button.pressed.connect(_on_begin_pressed)
	preview_button.pressed.connect(_on_preview_pressed)
	$VBoxContainer/BottomBar/ClearButton.pressed.connect(_on_clear_pressed)
	counter_label.text = "0 / 8 slots"
	await get_tree().process_frame
	_draw_staff_lines()
	_build_audio()

func _process(delta: float):
	if not previewing:
		return
	preview_timer -= delta
	if preview_timer <= 0.0:
		if preview_index >= melody.size():
			previewing = false
			preview_button.disabled = false
			preview_button.text = "♪ Preview"
			return
		var note_name = melody[preview_index]
		if note_name in note_players:
			note_players[note_name].play()
		preview_index += 1
		preview_timer = 0.5

func _build_inventory():
	for note in NOTES:
		var btn = Button.new()
		btn.text = note.name + "\n[" + note.key.to_upper() + "]"
		btn.custom_minimum_size = Vector2(60, 60)
		var style = StyleBoxFlat.new()
		style.bg_color = note.color
		style.corner_radius_top_left = 30
		style.corner_radius_top_right = 30
		style.corner_radius_bottom_left = 30
		style.corner_radius_bottom_right = 30
		btn.add_theme_stylebox_override("normal", style)
		btn.pressed.connect(_on_note_pressed.bind(note.name))
		note_inventory.add_child(btn)

func _draw_staff_lines():
	var h = staff.size.y
	var w = staff.size.x
	for i in 5:
		var line = ColorRect.new()
		line.color = Color(1, 1, 1, 0.15)
		line.size = Vector2(w, 1)
		line.position = Vector2(0, h * (0.2 + i * 0.15))
		staff.add_child(line)

func _on_note_pressed(note_name: String):
	if melody.size() >= MAX_SLOTS:
		return
	melody.append(note_name)
	_refresh_staff()
	counter_label.text = str(melody.size()) + " / 8 slots"
	begin_button.disabled = false
	if note_name in note_players:
		note_players[note_name].play()

func _refresh_staff():
	for child in staff.get_children():
		if child is Panel:
			child.queue_free()
	var w = staff.size.x
	var h = staff.size.y
	var spacing = w / (MAX_SLOTS + 1)
	for i in melody.size():
		var note_name = melody[i]
		var x = spacing * (i + 1) - NOTE_RADIUS
		var y = h * NOTE_Y[note_name] - NOTE_RADIUS
		var circle = Panel.new()
		circle.custom_minimum_size = Vector2(NOTE_RADIUS * 2, NOTE_RADIUS * 2)
		circle.position = Vector2(x, y)
		var style = StyleBoxFlat.new()
		style.bg_color = note_colors[note_name]
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
		staff.add_child(circle)

func _input(event: InputEvent):
	if not event is InputEventKey or not event.pressed:
		return
	var key_map = {"a": "B", "s": "G", "d": "A", "w": "C", "e": "D"}
	var key = OS.get_keycode_string(event.keycode).to_lower()
	if key in key_map:
		_on_note_pressed(key_map[key])

func _on_clear_pressed():
	melody.clear()
	_refresh_staff()
	counter_label.text = "0 / 8 slots"
	begin_button.disabled = true

func _on_preview_pressed():
	if melody.size() == 0:
		return
	previewing = true
	preview_index = 0
	preview_timer = 0.0
	preview_button.disabled = true
	preview_button.text = "♪ Playing..."

func _on_begin_pressed():
	Global.melody = melody.duplicate()
	get_tree().change_scene_to_file("res://scripts/melody_combat.tscn")

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
	data.resize(num_samples * 2)
	for i in num_samples:
		var t = float(i) / sample_rate
		var env = 0.0
		var attack = 0.04
		var decay = 0.3
		if t < attack:
			env = t / attack
		else:
			env = exp(-(t - attack) / decay)
		var s = 0.0
		s += sin(2.0 * PI * freq * t) * 0.6
		s += sin(2.0 * PI * freq * 2.0 * t) * 0.25
		s += sin(2.0 * PI * freq * 3.0 * t) * 0.1
		s += randf_range(-0.04, 0.04)
		s *= env
		var sample = int(clamp(s, -1.0, 1.0) * 32767)
		data[i * 2] = sample & 0xFF
		data[i * 2 + 1] = (sample >> 8) & 0xFF
	var stream = AudioStreamWAV.new()
	stream.data = data
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	return stream
