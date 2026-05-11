extends CanvasLayer

@onready var notebook_button = $NotebookButton
@onready var notebook_panel = $NotebookPanel
@onready var tab_info = $NotebookPanel/TabInfo
@onready var tab_music = $NotebookPanel/TabMusic
@onready var tab_quests = $NotebookPanel/TabQuests
@onready var content_info = $NotebookPanel/ContentInfo
@onready var content_music = $NotebookPanel/ContentMusic
@onready var content_quests = $NotebookPanel/ContentQuests

func _ready():
	notebook_panel.visible = false
	notebook_button.pressed.connect(_on_notebook_button_pressed)
	tab_info.pressed.connect(_on_tab_info_pressed)
	tab_music.pressed.connect(_on_tab_music_pressed)
	tab_quests.pressed.connect(_on_tab_quests_pressed)

func _on_notebook_button_pressed():
	notebook_panel.visible = not notebook_panel.visible

func _show_tab(content: Node):
	content_info.visible = false
	content_music.visible = false
	content_quests.visible = false
	content.visible = true

func _on_tab_info_pressed():
	_show_tab(content_info)

func _on_tab_music_pressed():
	_show_tab(content_music)

func _on_tab_quests_pressed():
	_show_tab(content_quests)
