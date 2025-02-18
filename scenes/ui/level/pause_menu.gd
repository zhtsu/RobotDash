extends CanvasLayer
class_name UI_PauseMenu


signal on_continue


@export var click_sound : AudioStream

@onready var settings_button : Button = $Panel/VBoxContainer/HBoxContainer/SettingsButton
@onready var shop_button : Button = $Panel/VBoxContainer/HBoxContainer/ShopButton
@onready var settings_label : Label = $Panel/VBoxContainer/HBoxContainer/SettingsButton/Label
@onready var shop_label : Label = $Panel/VBoxContainer/HBoxContainer/ShopButton/Label
@onready var tab_container : TabContainer = $Panel/VBoxContainer/TabContainer
@onready var music_button: Button = $Panel/VBoxContainer/TabContainer/Settings/VBoxContainer/MusicButton
@onready var sound_button: Button = $Panel/VBoxContainer/TabContainer/Settings/VBoxContainer/SoundButton
@onready var item_speed_up: StoreItem = $Panel/VBoxContainer/TabContainer/Shop/ScrollContainer/VBoxContainer/SpeedUp
@onready var item_better: StoreItem = $Panel/VBoxContainer/TabContainer/Shop/ScrollContainer/VBoxContainer/Better
@onready var item_luck: StoreItem = $Panel/VBoxContainer/TabContainer/Shop/ScrollContainer/VBoxContainer/Luck
@onready var item_overtime: StoreItem = $Panel/VBoxContainer/TabContainer/Shop/ScrollContainer/VBoxContainer/Overtime
@onready var item_one_attack: StoreItem = $Panel/VBoxContainer/TabContainer/Shop/ScrollContainer/VBoxContainer/OneAttack
@onready var item_restreat: StoreItem = $Panel/VBoxContainer/TabContainer/Shop/ScrollContainer/VBoxContainer/Restreat
@onready var item_double_jump: StoreItem = $Panel/VBoxContainer/TabContainer/Shop/ScrollContainer/VBoxContainer/DoubleJump

var music_enabled : bool = true
var sound_enabled : bool = true
var store_opened : bool = false
var main : Main
var level : Level
var player : Player


func _ready() -> void:
	var data : GodotTDS.RewardVideoAdData = GodotTDS.RewardVideoAdData.new()
	data.space_id = 1037810
	GodotTDS.load_reward_video_ad(data)
	GodotTDS.on_reward_video_ad_return.connect(_on_reward_video_ad_return)
	main = get_tree().get_first_node_in_group("main")
	level = main.active_level
	player = level.player
	_update_music_button(main.music_enabled)
	_update_sound_button(main.sound_enabled)
	if main.music_enabled:
		main.fade_music()
	settings_button.button_pressed = true
	settings_button.disabled = true
	settings_label.add_theme_color_override(
		"font_color", Color.from_string("65676b", Color.BLACK))
	
	# Set store item count
	item_speed_up.count = main.active_level.speed_up_count
	item_better.count = main.active_level.better_count
	item_double_jump.count = main.active_level.double_jump_count
	item_luck.count = main.active_level.luck_count
	item_overtime.count = main.active_level.overtime_count
	item_one_attack.count = main.active_level.one_attack_count
	item_restreat.count = main.active_level.restreat_count
	
	if store_opened:
		open_store()


func _exit_tree() -> void:
	GodotTDS.on_reward_video_ad_return.disconnect(_on_reward_video_ad_return)


func _on_settings_button_button_down() -> void:
	settings_button.disabled = true
	settings_label.add_theme_color_override(
		"font_color", Color.from_string("65676b", Color.BLACK))
	shop_button.button_pressed = false
	shop_button.disabled = false
	shop_label.add_theme_color_override("font_color", Color.WHITE)
	tab_container.current_tab = 0
	SoundManager.play_sound(click_sound)


func open_store() -> void:
	shop_button.disabled = true
	shop_label.add_theme_color_override(
		"font_color", Color.from_string("65676b", Color.BLACK))
	settings_button.button_pressed = false
	settings_button.disabled = false
	settings_label.add_theme_color_override("font_color", Color.WHITE)
	tab_container.current_tab = 1
	SoundManager.play_sound(click_sound)


func _on_shop_button_button_down() -> void:
	open_store()


func _on_continue_button_button_down() -> void:
	queue_free()
	get_tree().paused = false
	on_continue.emit()
	SoundManager.play_sound(click_sound)


func _on_music_button_button_down() -> void:
	SoundManager.play_sound(click_sound)
	main.music_enabled = not main.music_enabled
	_update_music_button(main.music_enabled)


func _on_sound_button_button_down() -> void:
	SoundManager.play_sound(click_sound)
	main.sound_enabled = not main.sound_enabled
	_update_sound_button(main.sound_enabled)


func _on_back_button_button_down() -> void:
	SoundManager.play_sound(click_sound)
	get_tree().paused = false
	main.open_main_menu()
	
	
func _update_music_button(enabled : bool) -> void:
	if enabled:
		music_button.text = "音乐：开"
	else:
		music_button.text = "音乐：关"
		
		
func _update_sound_button(enabled : bool) -> void:
	if enabled:
		sound_button.text = "声效：开"
	else:
		sound_button.text = "声效：关"
		
	
var _selected_store_item : StoreItem

func _on_store_item_clicked(store_item : StoreItem) -> void:
	_selected_store_item = store_item
	var confirm_popup : ConfirmPopup = load("res://scenes/ui/common/confirm_popup.tscn").instantiate()
	var hint_text : String = \
		"观看一个30秒不可跳过的广告即可获得\n{0}".format([store_item.data.item_name])
	confirm_popup.init_text(hint_text)
	confirm_popup.connect("confirm", _watch_reward_video)
	level.add_child(confirm_popup)
	
	
func _watch_reward_video() -> void:
	GodotTDS.show_reward_video_ad()
	
	
func _on_reward_video_ad_return(code : int, _msg : String) -> void:
	if code == GodotTDS.StateCode.AD_REWARD_VIDEO_COMPLETED ||\
	   code == GodotTDS.StateCode.AD_REWARD_VIDEO_SKIPPED:
		player.apply_item_effect(_selected_store_item)
		
