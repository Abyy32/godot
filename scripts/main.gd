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
var character_selection_target = "player"
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
	var root = _new_ui()
	var layout = HBoxContainer.new()
	layout.anchor_left = 0.04
	layout.anchor_top = 0.08
	layout.anchor_right = 0.96
	layout.anchor_bottom = 0.92
	layout.add_constant_override("separation", 20)
	root.add_child(layout)

	var featured = GameSession.character_by_id(GameSession.player_character_id)
	var hero_panel = PanelContainer.new()
	hero_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hero_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hero_panel.size_flags_stretch_ratio = 1.7
	hero_panel.add_stylebox_override("panel", _panel_style())
	layout.add_child(hero_panel)

	var hero_margin = MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		hero_margin.add_constant_override("margin_" + side, 20 if side != "top" else 24)
	hero_panel.add_child(hero_margin)
	var hero_content = VBoxContainer.new()
	hero_content.add_constant_override("separation", 12)
	hero_margin.add_child(hero_content)
	_home_label(hero_content, "2D SHINOBI FIGHTING", Color("#79d9e8"))
	_home_label(hero_content, "SHINOBI ARENA", Color("#f0f6ff"))
	_home_label(hero_content, "Choose your fighter. Master the arena.", Color("#aabbd0"))

	var feature_row = HBoxContainer.new()
	feature_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	feature_row.add_constant_override("separation", 16)
	hero_content.add_child(feature_row)
	var portrait = TextureRect.new()
	var atlas = load(featured.sprite_path)
	if atlas != null:
		var portrait_texture = AtlasTexture.new()
		portrait_texture.atlas = atlas
		portrait_texture.region = Rect2(0, 0, 384, 512)
		portrait.texture = portrait_texture
	portrait.expand = true
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	portrait.size_flags_vertical = Control.SIZE_EXPAND_FILL
	feature_row.add_child(portrait)

	var profile = VBoxContainer.new()
	profile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	profile.size_flags_vertical = Control.SIZE_EXPAND_FILL
	profile.add_constant_override("separation", 10)
	feature_row.add_child(profile)
	_home_label(profile, "FEATURED FIGHTER", Color("#79d9e8"))
	_home_label(profile, featured.name, Color("#f0f6ff"))
	_home_label(profile, featured.role.to_upper(), featured.accent)
	_home_label(profile, featured.description, Color("#bdcadd"))
	profile.add_child(HSeparator.new())
	_home_label(profile, "HP  %d" % int(featured.hp), Color("#f0f6ff"))
	_home_label(profile, "SPEED  %d" % int(featured.speed), Color("#f0f6ff"))
	_home_label(profile, "POWER  %d" % int(featured.power), Color("#f0f6ff"))
	var profile_spacer = Control.new()
	profile_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	profile.add_child(profile_spacer)
	_home_label(profile, "%d FIGHTERS  •  3 ARENAS" % GameSession.CHARACTER_DATA.size(), Color("#aabbd0"))

	var menu_panel = PanelContainer.new()
	menu_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	menu_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	menu_panel.size_flags_stretch_ratio = 1.0
	menu_panel.add_stylebox_override("panel", _panel_style())
	layout.add_child(menu_panel)
	var menu_margin = MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		menu_margin.add_constant_override("margin_" + side, 18)
	menu_panel.add_child(menu_margin)
	var menu = VBoxContainer.new()
	menu.add_constant_override("separation", 10)
	menu_margin.add_child(menu)
	_home_label(menu, "MAIN MENU", Color("#f0f6ff"))
	_home_label(menu, "Ready when you are.", Color("#aabbd0"))
	menu.add_child(HSeparator.new())
	_home_menu_button(menu, "QUICK BATTLE", "_show_mode_select", true)
	_home_menu_button(menu, "PRACTICE DOJO", "_start_practice")
	_home_menu_button(menu, "FIGHTER COLLECTION", "_show_collection")
	_home_menu_button(menu, "SETTINGS", "_show_settings")
	_home_menu_button(menu, "CREDITS", "_show_credits")
	if not OS.has_feature("HTML5"):
		_home_menu_button(menu, "QUIT", "_quit_game")
	var menu_spacer = Control.new()
	menu_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	menu.add_child(menu_spacer)
	_home_label(menu, "MOVE  WASD / ARROWS     ATTACK  J", Color("#91a5bd"))
	_home_label(menu, "SKILL  K     GUARD  H     DASH  L", Color("#91a5bd"))

func _home_label(parent, text, color):
	var label = Label.new()
	label.text = text
	label.autowrap = true
	label.add_color_override("font_color", color)
	parent.add_child(label)
	return label

func _home_menu_button(parent, caption, method_name, primary = false, binds = []):
	var button = _button(parent, caption, method_name, binds, Vector2(0, 52))
	var normal = StyleBoxFlat.new()
	normal.bg_color = Color("#235e78") if primary else Color(0.08, 0.13, 0.2, 0.9)
	normal.border_color = Color("#62cfe0") if primary else Color("#435b76")
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(9)
	normal.content_margin_left = 14
	normal.content_margin_right = 14
	var hover = StyleBoxFlat.new()
	hover.bg_color = Color("#347f99") if primary else Color("#172b40")
	hover.border_color = Color("#91e6f0") if primary else Color("#6b91ad")
	hover.set_border_width_all(1)
	hover.set_corner_radius_all(9)
	hover.content_margin_left = 14
	hover.content_margin_right = 14
	var pressed = StyleBoxFlat.new()
	pressed.bg_color = Color("#19475f")
	pressed.border_color = Color("#79d9e8")
	pressed.set_border_width_all(1)
	pressed.set_corner_radius_all(9)
	button.add_stylebox_override("normal", normal)
	button.add_stylebox_override("hover", hover)
	button.add_stylebox_override("focus", hover)
	button.add_stylebox_override("pressed", pressed)
	button.add_color_override("font_color", Color("#f2f7ff"))
	button.add_color_override("font_color_hover", Color("#ffffff"))
	button.add_color_override("font_color_pressed", Color("#ffffff"))
	return button

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

func _show_character_select(preserve_selection = false):
	screen = "character"
	if not preserve_selection:
		selected_character_id = GameSession.player_character_id
		selected_opponent_id = GameSession.opponent_character_id
		character_selection_target = "player"

	var root = _new_ui()
	var layout = VBoxContainer.new()
	layout.anchor_left = 0.045
	layout.anchor_top = 0.045
	layout.anchor_right = 0.955
	layout.anchor_bottom = 0.93
	layout.add_constant_override("separation", 12)
	root.add_child(layout)

	var title_row = HBoxContainer.new()
	layout.add_child(title_row)
	_home_label(title_row, "CHOOSE YOUR SHINOBI", Color("#f0f6ff"))
	var title_spacer = Control.new()
	title_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(title_spacer)
	_home_label(title_row, "%d FIGHTERS  •  PICK PLAYER, THEN RIVAL" % GameSession.CHARACTER_DATA.size(), Color("#79d9e8"))

	var target_row = HBoxContainer.new()
	target_row.add_constant_override("separation", 10)
	layout.add_child(target_row)
	_home_menu_button(target_row, "1  PLAYER FIGHTER", "_set_character_selection_target", character_selection_target == "player", ["player"])
	_home_menu_button(target_row, "2  RIVAL FIGHTER", "_set_character_selection_target", character_selection_target == "rival", ["rival"])
	var target_hint = _home_label(target_row, "Choose a roster card below for the highlighted slot.", Color("#aabbd0"))
	target_hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	target_hint.align = Label.ALIGN_RIGHT

	var preview_row = HBoxContainer.new()
	preview_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	preview_row.add_constant_override("separation", 14)
	layout.add_child(preview_row)
	_add_character_preview(preview_row, "PLAYER 1", GameSession.character_by_id(selected_character_id), character_selection_target == "player")
	_add_character_preview(preview_row, "RIVAL", GameSession.character_by_id(selected_opponent_id), character_selection_target == "rival")

	_home_label(layout, "FIGHTER ROSTER", Color("#79d9e8"))
	var roster_row = HBoxContainer.new()
	roster_row.add_constant_override("separation", 10)
	layout.add_child(roster_row)
	var active_id = selected_character_id if character_selection_target == "player" else selected_opponent_id
	for character in GameSession.CHARACTER_DATA:
		_add_character_card(roster_row, character, character.id == active_id)

	var action_row = HBoxContainer.new()
	action_row.add_constant_override("separation", 12)
	layout.add_child(action_row)
	_home_menu_button(action_row, "BACK", "_go_back")
	var action_spacer = Control.new()
	action_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_row.add_child(action_spacer)
	_home_menu_button(action_row, "CONTINUE TO ARENA  >", "_confirm_character", true)

func _add_character_preview(parent, slot_title, character, active):
	var panel = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.065, 0.12, 0.94)
	style.border_color = character.accent if active else Color("#435b76")
	style.set_border_width_all(2 if active else 1)
	style.set_corner_radius_all(12)
	panel.add_stylebox_override("panel", style)
	parent.add_child(panel)

	var margin = MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_constant_override("margin_" + side, 12)
	panel.add_child(margin)
	var row = HBoxContainer.new()
	row.add_constant_override("separation", 12)
	margin.add_child(row)
	var portrait = _character_portrait(character, Vector2(150, 190))
	portrait.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_child(portrait)
	var details = VBoxContainer.new()
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details.add_constant_override("separation", 7)
	row.add_child(details)
	_home_label(details, slot_title, Color("#79d9e8"))
	_home_label(details, character.name, Color("#f0f6ff"))
	_home_label(details, character.role.to_upper(), character.accent)
	_home_label(details, character.description, Color("#bdcadd"))
	details.add_child(HSeparator.new())
	_home_label(details, "HP  %d     SPEED  %d" % [int(character.hp), int(character.speed)], Color("#f0f6ff"))
	_home_label(details, "POWER  %d" % int(character.power), Color("#f0f6ff"))

func _add_character_card(parent, character, selected):
	var card = Button.new()
	card.text = ""
	card.focus_mode = Control.FOCUS_ALL
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.rect_min_size = Vector2(0, 172)
	card.connect("pressed", self, "_on_character_card_pressed", [character.id])
	var normal = StyleBoxFlat.new()
	normal.bg_color = Color("#122238") if selected else Color(0.035, 0.065, 0.12, 0.94)
	normal.border_color = character.accent if selected else Color("#435b76")
	normal.set_border_width_all(2 if selected else 1)
	normal.set_corner_radius_all(10)
	normal.content_margin_left = 8
	normal.content_margin_right = 8
	normal.content_margin_top = 8
	normal.content_margin_bottom = 8
	var hover = StyleBoxFlat.new()
	hover.bg_color = Color("#1a3048")
	hover.border_color = character.accent
	hover.set_border_width_all(2)
	hover.set_corner_radius_all(10)
	card.add_stylebox_override("normal", normal)
	card.add_stylebox_override("hover", hover)
	card.add_stylebox_override("focus", hover)
	card.add_color_override("font_color", Color("#f0f6ff"))
	parent.add_child(card)

	var body = VBoxContainer.new()
	body.anchor_right = 1.0
	body.anchor_bottom = 1.0
	body.margin_left = 4
	body.margin_top = 4
	body.margin_right = -4
	body.margin_bottom = -4
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_constant_override("separation", 3)
	card.add_child(body)
	var portrait = _character_portrait(character, Vector2(0, 104))
	portrait.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	portrait.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(portrait)
	_selection_label(body, character.name, Color("#f0f6ff"))
	_selection_label(body, character.role, character.accent)

func _character_portrait(character, minimum_size):
	var portrait = TextureRect.new()
	var atlas = load(character.sprite_path)
	if atlas != null:
		var texture = AtlasTexture.new()
		texture.atlas = atlas
		texture.region = Rect2(0, 0, 384, 512)
		portrait.texture = texture
	portrait.expand = true
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.rect_min_size = minimum_size
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return portrait

func _selection_label(parent, text, color):
	var label = Label.new()
	label.text = text
	label.align = Label.ALIGN_CENTER
	label.autowrap = true
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_color_override("font_color", color)
	parent.add_child(label)
	return label

func _set_character_selection_target(target):
	character_selection_target = target
	_show_character_select(true)

func _on_character_card_pressed(character_id):
	if character_selection_target == "player":
		selected_character_id = character_id
	else:
		selected_opponent_id = character_id
	_show_character_select(true)

func _confirm_character():
	GameSession.player_character_id = selected_character_id
	GameSession.opponent_character_id = selected_opponent_id
	_show_arena_select()

func _show_arena_select(preserve_selection = false):
	screen = "arena"
	if not preserve_selection:
		selected_arena_id = GameSession.selected_arena_id
	var root = _new_ui()
	var layout = VBoxContainer.new()
	layout.anchor_left = 0.045
	layout.anchor_top = 0.06
	layout.anchor_right = 0.955
	layout.anchor_bottom = 0.915
	layout.add_constant_override("separation", 12)
	root.add_child(layout)

	var title_row = HBoxContainer.new()
	layout.add_child(title_row)
	_home_label(title_row, "CHOOSE YOUR BATTLEFIELD", Color("#f0f6ff"))
	var title_spacer = Control.new()
	title_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(title_spacer)
	_home_label(title_row, "%d ARENAS  •  CLICK A CARD TO SELECT" % GameSession.ARENA_DATA.size(), Color("#79d9e8"))
	_home_label(layout, "Every arena has its own atmosphere and fighting ground.", Color("#aabbd0"))

	var card_row = HBoxContainer.new()
	card_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card_row.add_constant_override("separation", 14)
	layout.add_child(card_row)
	for arena in GameSession.ARENA_DATA:
		_add_arena_card(card_row, arena, arena.id == selected_arena_id)

	var action_row = HBoxContainer.new()
	action_row.add_constant_override("separation", 12)
	layout.add_child(action_row)
	_home_menu_button(action_row, "BACK", "_go_back")
	var action_spacer = Control.new()
	action_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_row.add_child(action_spacer)
	_home_menu_button(action_row, "RANDOM ARENA", "_random_arena")
	_home_menu_button(action_row, "START BATTLE  >", "_start_battle", true)

func _add_arena_card(parent, arena, selected):
	var card = Button.new()
	card.text = ""
	card.focus_mode = Control.FOCUS_ALL
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card.rect_min_size = Vector2(0, 300)
	card.connect("pressed", self, "_on_arena_card_pressed", [arena.id])
	var normal = StyleBoxFlat.new()
	normal.bg_color = Color("#122238") if selected else Color(0.035, 0.065, 0.12, 0.94)
	normal.border_color = arena.accent if selected else Color("#435b76")
	normal.set_border_width_all(2 if selected else 1)
	normal.set_corner_radius_all(12)
	normal.content_margin_left = 10
	normal.content_margin_right = 10
	normal.content_margin_top = 10
	normal.content_margin_bottom = 10
	var hover = StyleBoxFlat.new()
	hover.bg_color = Color("#1a3048")
	hover.border_color = arena.accent
	hover.set_border_width_all(2)
	hover.set_corner_radius_all(12)
	card.add_stylebox_override("normal", normal)
	card.add_stylebox_override("hover", hover)
	card.add_stylebox_override("focus", hover)
	parent.add_child(card)

	var body = VBoxContainer.new()
	body.anchor_right = 1.0
	body.anchor_bottom = 1.0
	body.margin_left = 4
	body.margin_top = 4
	body.margin_right = -4
	body.margin_bottom = -4
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_constant_override("separation", 8)
	card.add_child(body)
	var preview = ArenaPreviewScript.new()
	preview.arena_id = arena.id
	preview.rect_min_size = Vector2(360, 220)
	preview.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preview.size_flags_vertical = Control.SIZE_EXPAND_FILL
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(preview)
	_selection_label(body, arena.name, Color("#f0f6ff"))
	_selection_label(body, arena.description, Color("#bdcadd"))
	_selection_label(body, "SELECTED" if selected else "TAP TO SELECT", arena.accent)

func _on_arena_card_pressed(arena_id):
	selected_arena_id = arena_id
	_show_arena_select(true)

func _random_arena():
	var index = randi() % GameSession.ARENA_DATA.size()
	selected_arena_id = GameSession.ARENA_DATA[index].id
	_show_arena_select(true)

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
	fighter.run_cycle_texture = load("res://assets/sprites/%s_run_cycle.png" % data.id)
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
	var column = _panel(_new_ui(), "COLLECTION", "Original prototype roster • %d fighters available" % GameSession.CHARACTER_DATA.size())
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
