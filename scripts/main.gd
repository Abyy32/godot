extends Node2D

const Fighter = preload("res://scripts/fighter.gd")
const Rival = preload("res://scripts/enemy.gd")
const HUD = preload("res://scripts/hud.gd")
const ArenaPreviewScript = preload("res://scripts/arena_preview.gd")
const ROUND_SECONDS = 99.0

var player
var enemy
var hud
var stage
var battle_camera
var shake_time = 0.0
var shake_strength = 0.0
var ui_layer
var screen = "home"
var selection_return_screen = "mode"
var settings_return_to_battle = false
var selected_character_id = "kairo"
var selected_opponent_id = "ren"
var selected_arena_id = "forest_shrine"
var match_time = ROUND_SECONDS
var match_elapsed = 0.0
var match_finished = false
var elapsed = 0.0
var character_option
var opponent_option
var arena_option
var settings_controls = {}

func _ready():
	pause_mode = Node.PAUSE_MODE_PROCESS
	OS.set_window_title("Shinobi Arena 2D")
	GameSession.apply_audio_settings()
	_show_home()

func _process(delta):
	elapsed += delta
	update()
	if is_instance_valid(battle_camera) and not get_tree().paused:
		if shake_time > 0.0:
			shake_time = max(0.0, shake_time - delta)
			battle_camera.offset = Vector2(rand_range(-shake_strength, shake_strength), rand_range(-shake_strength, shake_strength))
		else:
			battle_camera.offset = Vector2.ZERO
	if screen != "battle" or match_finished or get_tree().paused:
		return
	match_elapsed += delta
	if GameSession.selected_mode != "practice":
		match_time = max(0.0, match_time - delta)
	if is_instance_valid(hud):
		hud.update_status(match_time, GameSession.selected_mode == "practice")
	if is_instance_valid(player) and is_instance_valid(enemy):
		if player.health <= 0.0:
			_finish_match("defeat")
		elif enemy.health <= 0.0:
			_finish_match("victory")
		elif match_time <= 0.0:
			if is_equal_approx(player.health, enemy.health):
				_finish_match("draw")
			else:
				_finish_match("victory" if player.health > enemy.health else "defeat")

func _unhandled_input(event):
	if not event.is_action_pressed("ui_cancel"):
		return
	if screen == "battle":
		if get_tree().paused:
			_resume_battle()
		else:
			_pause_battle()
	elif screen != "home":
		_go_back()

func _draw():
	if screen == "battle":
		return
	var view = get_viewport_rect().size
	var arena = GameSession.arena_by_id(selected_arena_id)
	var base = arena.color
	draw_rect(Rect2(Vector2.ZERO, view), base)
	draw_circle(Vector2(view.x * 0.78, view.y * 0.19), 70, Color(0.3, 0.5, 0.8, 0.08))
	draw_circle(Vector2(view.x * 0.78, view.y * 0.19), 40, Color("#d7e7ff"))
	draw_circle(Vector2(view.x * 0.78 + 13, view.y * 0.175), 37, base)
	var far = PoolVector2Array([Vector2(0, 430), Vector2(130, 300), Vector2(230, 385), Vector2(390, 275), Vector2(550, 405), Vector2(720, 315), Vector2(900, 410), Vector2(1080, 290), Vector2(1280, 420), Vector2(1280, 560), Vector2(0, 560)])
	draw_colored_polygon(far, arena.accent.darkened(0.57))
	var near = PoolVector2Array([Vector2(0, 485), Vector2(170, 390), Vector2(310, 465), Vector2(480, 365), Vector2(660, 475), Vector2(850, 380), Vector2(1040, 470), Vector2(1180, 390), Vector2(1280, 445), Vector2(1280, 600), Vector2(0, 600)])
	draw_colored_polygon(near, arena.accent.darkened(0.72))
	for x in [90.0, 1090.0]:
		draw_rect(Rect2(x, 340, 14, 185), Color("#0a1426"))
		draw_rect(Rect2(x + 75, 340, 14, 185), Color("#0a1426"))
		draw_rect(Rect2(x - 12, 330, 113, 15), Color("#0a1426"))
		draw_rect(Rect2(x - 22, 318, 133, 10), Color("#0a1426"))
	draw_rect(Rect2(0, 535, view.x, view.y - 535), Color("#202b3a"))
	draw_rect(Rect2(0, 535, view.x, 4), arena.accent.lightened(0.28))
	var count = 0
	if not GameSession.settings.reduced_effects:
		count = 4 if GameSession.settings.effects_quality == "low" else (12 if GameSession.settings.effects_quality == "medium" else 22)
	for index in range(count):
		var x = fposmod(index * 83.0 - elapsed * 25.0, view.x + 100.0)
		draw_line(Vector2(x, 552), Vector2(x - 35, 690), Color(0.39, 0.53, 0.67, 0.18), 2)

func _new_ui():
	_clear_ui()
	ui_layer = CanvasLayer.new()
	ui_layer.pause_mode = Node.PAUSE_MODE_PROCESS
	add_child(ui_layer)
	var root = Control.new()
	root.anchor_right = 1.0
	root.anchor_bottom = 1.0
	root.mouse_filter = Control.MOUSE_FILTER_PASS
	ui_layer.add_child(root)
	return root

func _clear_ui():
	if is_instance_valid(ui_layer):
		remove_child(ui_layer)
		ui_layer.free()
	ui_layer = null

func _panel(root, title, subtitle = "", panel_size = Vector2(700, 580)):
	var frame = PanelContainer.new()
	frame.rect_position = (get_viewport_rect().size - panel_size) * 0.5
	frame.rect_size = panel_size
	frame.add_stylebox_override("panel", _panel_style())
	root.add_child(frame)
	var margin = MarginContainer.new()
	margin.add_constant_override("margin_left", 24)
	margin.add_constant_override("margin_right", 24)
	margin.add_constant_override("margin_top", 20)
	margin.add_constant_override("margin_bottom", 20)
	frame.add_child(margin)
	var column = VBoxContainer.new()
	column.add_constant_override("separation", 12)
	margin.add_child(column)
	var heading = Label.new()
	heading.text = title
	heading.align = Label.ALIGN_CENTER
	heading.add_color_override("font_color", Color("#e8f5ff"))
	column.add_child(heading)
	if subtitle != "":
		var detail = Label.new()
		detail.text = subtitle
		detail.align = Label.ALIGN_CENTER
		detail.autowrap = true
		detail.add_color_override("font_color", Color("#aabbd0"))
		column.add_child(detail)
	return column

func _panel_style():
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.065, 0.12, 0.94)
	style.border_color = Color("#55708d")
	style.set_border_width_all(1)
	style.set_corner_radius_all(14)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style

func _label(parent, text, font_size = 16, centered = false):
	var label = Label.new()
	label.text = text
	label.align = Label.ALIGN_CENTER if centered else Label.ALIGN_LEFT
	label.autowrap = true
	label.add_color_override("font_color", Color("#d5e4f5"))
	parent.add_child(label)
	return label

func _button(parent, caption, method_name, binds = [], minimum = Vector2(0, 48)):
	var button = Button.new()
	button.text = caption
	button.rect_min_size = minimum
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.focus_mode = Control.FOCUS_ALL
	button.connect("pressed", self, method_name, binds)
	parent.add_child(button)
	return button

func _show_home():
	screen = "home"
	var column = _panel(_new_ui(), "SHINOBI ARENA", "Three fighters. Three arenas. Choose your path.")
	_button(column, "QUICK BATTLE", "_show_mode_select", [], Vector2(0, 52))
	_button(column, "PRACTICE DOJO", "_start_practice", [], Vector2(0, 52))
	_button(column, "COLLECTION", "_show_collection")
	_button(column, "SETTINGS", "_show_settings")
	_button(column, "CREDITS", "_show_credits")
	if not OS.has_feature("HTML5"):
		_button(column, "QUIT", "_quit_game")

func _show_mode_select():
	screen = "mode"
	var column = _panel(_new_ui(), "SELECT MODE", "Choose how this match should play")
	_button(column, "Quick Battle — fight the AI", "_choose_quick_battle")
	_button(column, "Practice — passive opponent, no timer", "_start_practice")
	var versus = _button(column, "Versus Local — Coming Soon", "_noop")
	versus.disabled = true
	_button(column, "Back", "_show_home")

func _noop():
	pass

func _choose_quick_battle():
	GameSession.selected_mode = "quick_battle"
	selection_return_screen = "mode"
	_show_character_select()

func _start_practice():
	GameSession.selected_mode = "practice"
	selection_return_screen = "home"
	_show_character_select()

func _show_character_select():
	screen = "character"
	selected_character_id = GameSession.player_character_id
	selected_opponent_id = GameSession.opponent_character_id
	var column = _panel(_new_ui(), "CHOOSE YOUR SHINOBI", "Choose a player and rival.\nPlayer: %s    Rival: %s" % [GameSession.character_by_id(selected_character_id).name, GameSession.character_by_id(selected_opponent_id).name])
	character_option = OptionButton.new()
	opponent_option = OptionButton.new()
	for character in GameSession.CHARACTER_DATA:
		character_option.add_item("%s  |  HP %d  SPEED %d  POWER %d" % [character.name, int(character.hp), int(character.speed), int(character.power)])
		opponent_option.add_item("%s  |  %s" % [character.name, character.role])
		if character.id == selected_character_id:
			character_option.select(GameSession.CHARACTER_DATA.find(character))
		if character.id == selected_opponent_id:
			opponent_option.select(GameSession.CHARACTER_DATA.find(character))
	column.add_child(_label(column, "PLAYER FIGHTER"))
	column.add_child(character_option)
	column.add_child(_label(column, "RIVAL FIGHTER"))
	column.add_child(opponent_option)
	_button(column, "BACK", "_go_back")
	_button(column, "CONTINUE TO ARENA  >", "_confirm_character")

func _confirm_character():
	var player_index = max(0, character_option.get_selected())
	var opponent_index = max(0, opponent_option.get_selected())
	GameSession.player_character_id = GameSession.CHARACTER_DATA[player_index].id
	GameSession.opponent_character_id = GameSession.CHARACTER_DATA[opponent_index].id
	_show_arena_select()

func _show_arena_select():
	screen = "arena"
	selected_arena_id = GameSession.selected_arena_id
	var column = _panel(_new_ui(), "CHOOSE YOUR BATTLEFIELD", "Each arena has its own terrain, light, and mood.")
	arena_option = OptionButton.new()
	for index in range(GameSession.ARENA_DATA.size()):
		var arena = GameSession.ARENA_DATA[index]
		arena_option.add_item("%s — %s" % [arena.name, arena.description])
		if arena.id == selected_arena_id:
			arena_option.select(index)
	var preview = ArenaPreviewScript.new()
	preview.name = "ArenaPreview"
	preview.arena_id = selected_arena_id
	preview.rect_min_size = Vector2(360, 220)
	column.add_child(preview)
	column.add_child(arena_option)
	arena_option.connect("item_selected", self, "_on_arena_selected", [preview])
	_button(column, "RANDOM ARENA", "_random_arena")
	_button(column, "BACK", "_go_back")
	_button(column, "START BATTLE  >", "_start_battle")

func _on_arena_selected(index, preview):
	selected_arena_id = GameSession.ARENA_DATA[index].id
	preview.arena_id = selected_arena_id
	preview.update()

func _random_arena():
	var index = randi() % GameSession.ARENA_DATA.size()
	selected_arena_id = GameSession.ARENA_DATA[index].id
	arena_option.select(index)
	var preview = ui_layer.find_node("ArenaPreview", true, false)
	if is_instance_valid(preview):
		preview.arena_id = selected_arena_id
		preview.update()

func _start_battle():
	GameSession.selected_arena_id = selected_arena_id
	get_tree().paused = false
	_clear_ui()
	_cleanup_battle()
	screen = "battle"
	match_finished = false
	match_time = ROUND_SECONDS
	match_elapsed = 0.0
	update()
	var player_data = GameSession.character_by_id(GameSession.player_character_id)
	var opponent_data = GameSession.character_by_id(GameSession.opponent_character_id)
	var arena_data = GameSession.arena_by_id(selected_arena_id)
	var arena_scene = load(arena_data.scene_path)
	if arena_scene == null:
		push_error("Arena scene could not be loaded: %s" % arena_data.scene_path)
		screen = "arena"
		_show_arena_select()
		return
	stage = arena_scene.instance()
	add_child(stage)
	battle_camera = Camera2D.new()
	battle_camera.position = Vector2(640, 360)
	add_child(battle_camera)
	battle_camera.make_current()
	shake_time = 0.0
	shake_strength = 0.0
	player = Fighter.new()
	_configure_fighter(player, player_data, 0, arena_data.player_spawn, arena_data)
	player.connect("damaged", self, "_on_fighter_damaged")
	add_child(player)
	enemy = Rival.new()
	_configure_fighter(enemy, opponent_data, 1, arena_data.opponent_spawn, arena_data)
	enemy.set("practice_mode", GameSession.selected_mode == "practice")
	enemy.connect("damaged", self, "_on_fighter_damaged")
	add_child(enemy)
	player.opponent = enemy
	enemy.opponent = player
	hud = HUD.new()
	hud.player = player
	hud.enemy = enemy
	hud.connect("pause_requested", self, "_pause_battle")
	player.connect("skill_used", hud, "show_skill_banner")
	enemy.connect("skill_used", hud, "show_skill_banner")
	add_child(hud)
	hud.set_match_info(arena_data.name, player_data.name, opponent_data.name)

func _configure_fighter(fighter, data, team_id, spawn, arena_data):
	fighter.team = team_id
	fighter.character_name = data.name
	fighter.max_health = data.hp
	fighter.move_speed = data.speed
	fighter.attack_power = data.power
	fighter.color_main = data.color
	fighter.color_accent = data.accent
	fighter.sprite_texture = load(data.sprite_path)
	fighter.position = spawn
	fighter.arena_left = arena_data.left_bound
	fighter.arena_right = arena_data.right_bound

func _finish_match(outcome):
	if match_finished:
		return
	match_finished = true
	player.set_combat_enabled(false)
	enemy.set_combat_enabled(false)
	GameSession.match_result = {"outcome": outcome, "player_name": GameSession.character_by_id(GameSession.player_character_id).name, "opponent_name": GameSession.character_by_id(GameSession.opponent_character_id).name, "arena_name": GameSession.arena_by_id(GameSession.selected_arena_id).name, "duration": match_elapsed, "player_health": player.health, "opponent_health": enemy.health}
	GameSession.record_result(outcome)
	_cleanup_battle()
	_show_result()

func _cleanup_battle():
	_release_combat_input()
	for node in get_tree().get_nodes_in_group("projectiles"):
		node.queue_free()
	for node in [hud, player, enemy, stage, battle_camera]:
		if is_instance_valid(node):
			node.queue_free()
	hud = null
	player = null
	enemy = null
	stage = null
	battle_camera = null
	shake_time = 0.0
	shake_strength = 0.0

func _show_result():
	screen = "result"
	var result = GameSession.match_result
	var heading = "DRAW"
	if result.outcome == "victory":
		heading = "VICTORY"
	elif result.outcome == "defeat":
		heading = "DEFEAT"
	var column = _panel(_new_ui(), heading, "%s vs %s  •  %s\nTime: %d seconds   •   HP: %d — %d" % [result.player_name, result.opponent_name, result.arena_name, int(result.duration), int(result.player_health), int(result.opponent_health)])
	_button(column, "Rematch", "_start_battle")
	_button(column, "Character Select", "_show_character_select")
	_button(column, "Arena Select", "_show_arena_select")
	_button(column, "Home", "_return_home")

func _pause_battle():
	if screen != "battle" or match_finished or get_tree().paused:
		return
	get_tree().paused = true
	_release_combat_input()
	shake_time = 0.0
	if is_instance_valid(battle_camera):
		battle_camera.offset = Vector2.ZERO
	if is_instance_valid(hud):
		hud.hide()
	var column = _panel(_new_ui(), "PAUSED", "The match and round timer are paused.")
	_button(column, "Resume", "_resume_battle")
	_button(column, "Settings", "_show_battle_settings")
	_button(column, "Restart Match", "_start_battle")
	_button(column, "Home", "_return_home")

func _show_battle_settings():
	_show_settings(true)

func _resume_battle():
	get_tree().paused = false
	if screen == "battle":
		_clear_ui()
		if is_instance_valid(hud):
			hud.show()

func _show_settings(return_to_battle_override = false):
	var return_to_battle = screen == "battle" or return_to_battle_override
	settings_return_to_battle = return_to_battle
	screen = "settings"
	var column = _panel(_new_ui(), "SETTINGS", "Changes are saved locally.", Vector2(780, 670))
	settings_controls.clear()
	for setting in [["Master volume", "master_volume", 0.0, 1.0, "Master"], ["Music volume", "music_volume", 0.0, 1.0, "Music"], ["SFX volume", "sfx_volume", 0.0, 1.0, "SFX"], ["Control sensitivity", "control_sensitivity", 0.5, 1.5, ""], ["Flash intensity", "flash_intensity", 0.0, 1.0, ""]]:
		_add_setting_slider(column, setting[0], setting[1], setting[2], setting[3], setting[4])
	var shake = CheckButton.new()
	shake.text = "Screen shake enabled"
	shake.pressed = GameSession.settings.screen_shake
	shake.connect("toggled", self, "_on_setting_toggle", ["screen_shake"])
	column.add_child(shake)
	var quality = OptionButton.new()
	for item in ["low", "medium", "high"]:
		quality.add_item(item.capitalize())
	quality.select(["low", "medium", "high"].find(GameSession.settings.effects_quality))
	quality.connect("item_selected", self, "_on_quality_selected")
	column.add_child(quality)
	var layout = OptionButton.new()
	layout.add_item("Classic touch controls")
	layout.add_item("Compact touch controls")
	layout.select(1 if GameSession.settings.mobile_layout == "compact" else 0)
	layout.connect("item_selected", self, "_on_layout_selected")
	column.add_child(layout)
	var reduced = CheckButton.new()
	reduced.text = "Reduce visual effects"
	reduced.pressed = GameSession.settings.reduced_effects
	reduced.connect("toggled", self, "_on_setting_toggle", ["reduced_effects"])
	column.add_child(reduced)
	_button(column, "Reset Settings", "_reset_settings")
	_button(column, "Back", "_back_from_settings")

func _add_setting_slider(parent, title, key, minimum, maximum, bus):
	var row = HBoxContainer.new()
	parent.add_child(row)
	var label = Label.new()
	label.text = "%s: %.2f" % [title, float(GameSession.settings[key])]
	label.rect_min_size.x = 190
	row.add_child(label)
	var slider = HSlider.new()
	slider.min_value = minimum
	slider.max_value = maximum
	slider.step = 0.05
	slider.value = GameSession.settings[key]
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(slider)
	slider.connect("value_changed", self, "_on_slider_changed", [key, title, bus, label])

func _on_slider_changed(value, key, title, bus, label):
	GameSession.settings[key] = value
	label.text = "%s: %.2f" % [title, value]
	if bus != "":
		GameSession.set_audio_volume(bus, value)
	GameSession.save_settings()

func _on_setting_toggle(enabled, key):
	GameSession.settings[key] = enabled
	GameSession.save_settings()
	update()

func _on_quality_selected(index):
	GameSession.settings.effects_quality = ["low", "medium", "high"][index]
	GameSession.save_settings()
	update()

func _on_layout_selected(index):
	GameSession.settings.mobile_layout = "compact" if index == 1 else "classic"
	GameSession.save_settings()
	if is_instance_valid(hud):
		hud.apply_mobile_layout(GameSession.settings.mobile_layout)

func _reset_settings():
	GameSession.settings = {"master_volume": 1.0, "music_volume": 0.8, "sfx_volume": 1.0, "control_sensitivity": 1.0, "mobile_layout": "classic", "effects_quality": "medium", "screen_shake": true, "reduced_effects": false, "flash_intensity": 1.0}
	GameSession.save_settings()
	GameSession.apply_audio_settings()
	_show_settings(settings_return_to_battle)

func _back_from_settings():
	if settings_return_to_battle:
		screen = "battle"
		_resume_battle()
	else:
		_show_home()

func _on_fighter_damaged(_amount):
	if not GameSession.settings.screen_shake or GameSession.settings.reduced_effects or not is_instance_valid(battle_camera):
		return
	shake_time = 0.12
	shake_strength = 6.0

func _show_credits():
	screen = "credits"
	var column = _panel(_new_ui(), "CREDITS", "Shinobi Arena 2D\nOriginal procedural placeholder art and code.\nUse only original or properly licensed assets.")
	_button(column, "Back", "_show_home")

func _show_collection():
	screen = "collection"
	var column = _panel(_new_ui(), "COLLECTION", "Original prototype roster • all three fighters are available")
	for character in GameSession.CHARACTER_DATA:
		_label(column, "%s  •  %s  •  %d HP  •  %s" % [character.name, character.role, int(character.hp), "Unlocked" if character.unlocked else "Locked"])
	_label(column, "Record: %d wins  •  %d losses  •  %d draws" % [GameSession.progress.wins, GameSession.progress.losses, GameSession.progress.draws], 16, true)
	_button(column, "Back", "_show_home")

func _go_back():
	match screen:
		"mode": _show_home()
		"character": _show_home() if selection_return_screen == "home" else _show_mode_select()
		"arena": _show_character_select()
		"result": _return_home()
		"collection", "settings", "credits": _show_home()
		_: _show_home()

func _return_home():
	get_tree().paused = false
	_cleanup_battle()
	GameSession.match_result = {}
	_show_home()

func _quit_game():
	get_tree().quit()

func _release_combat_input():
	for action_name in ["move_left", "move_right", "jump", "guard", "attack", "skill", "skill_alt", "dash"]:
		Input.action_release(action_name)
