extends Control

const Game = preload("res://game.gd")
const DiceTray = preload("res://dice_tray.gd")
const SAVE_PATH := "user://thousands.save"
const GOLD := Color("#f3c979")
const MINT := Color("#a9c7bc")
const INK := Color("#0a201a")
const PAPER := Color("#f8f2e4")

var game := Game.new()
var tray: SubViewportContainer
var rolling := false
var content: VBoxContainer
var score_labels: Array[Label] = []
var scoreboard_x_slots: Array = []
var turn_ending := false
var mode := 1000
var target := 5000
var virtual := true
var names := ["", ""]
var selected_indices: Array = []
var save_error := ""

func _ready() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
		if file:
			var saved: Variant = file.get_var()
			if saved is Dictionary and saved.get("version") == 1:
				game.state = saved.state
	render()

func save() -> void:
	DirAccess.make_dir_recursive_absolute(OS.get_user_data_dir())
	var file := FileAccess.open(SAVE_PATH + ".tmp", FileAccess.WRITE)
	if file:
		file.store_var({"version": 1, "state": game.state})
		file.flush()
		var result := file.get_error()
		file.close()
		if result == OK and DirAccess.rename_absolute(SAVE_PATH + ".tmp", SAVE_PATH) == OK:
			save_error = ""
			return
	save_error = "The game is still playable, but this turn could not be saved."

func refresh(keep_tray := false) -> void:
	if is_instance_valid(tray) and game.state.is_empty():
		tray.queue_free()
		tray = null
	if is_instance_valid(tray) and not keep_tray:
		tray.clear_dice()
	selected_indices.clear()
	save()
	render()

func render() -> void:
	if is_instance_valid(tray) and tray.get_parent():
		tray.get_parent().remove_child(tray)
	for child in get_children():
		remove_child(child)
		child.queue_free()

	var background := ColorRect.new()
	background.color = Color("#0d241e")
	add_child(background)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	score_labels.clear()
	scoreboard_x_slots.clear()
	if not game.state.is_empty():
		game_layout()
		return

	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 20)
	scroll.add_child(margin)
	content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 11)
	margin.add_child(content)

	show_logo(78)
	setup_screen()

func show_logo(height: int) -> TextureRect:
	var logo := TextureRect.new()
	logo.texture = preload("res://art/thousands_logo.png")
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.custom_minimum_size.y = height
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(logo)
	return logo

func label(parent: Control, value: String, size: int, color: Color = PAPER) -> Label:
	var node := Label.new()
	node.text = value
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	node.add_theme_font_size_override("font_size", size)
	node.add_theme_color_override("font_color", color)
	parent.add_child(node)
	return node

func style(color: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(10)
	box.content_margin_left = 12
	box.content_margin_right = 12
	box.content_margin_top = 8
	box.content_margin_bottom = 8
	return box

func button(parent: Control, value: String, action: Callable, primary := false) -> Button:
	var node := Button.new()
	node.text = value
	node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	node.custom_minimum_size.y = 46
	node.add_theme_font_size_override("font_size", 17)
	node.add_theme_stylebox_override("normal", style(GOLD if primary else Color("#234638")))
	node.add_theme_stylebox_override("hover", style(Color("#ffe2a3") if primary else Color("#305a49")))
	node.add_theme_stylebox_override("pressed", style(Color("#deb361") if primary else Color("#18372b")))
	for color_name in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		node.add_theme_color_override(color_name, INK if primary else PAPER)
	node.pressed.connect(action)
	parent.add_child(node)
	return node

func row(parent: Control) -> HBoxContainer:
	var node := HBoxContainer.new()
	node.add_theme_constant_override("separation", 8)
	parent.add_child(node)
	return node

func field(parent: Control, placeholder: String, value := "") -> LineEdit:
	var node := LineEdit.new()
	node.placeholder_text = placeholder
	node.text = value
	node.custom_minimum_size.y = 46
	node.add_theme_stylebox_override("normal", style(Color("#19382e")))
	node.add_theme_font_size_override("font_size", 17)
	parent.add_child(node)
	return node

func setup_screen() -> void:
	label(content, "Game mode", 17, MINT)
	var modes := row(content)
	for value in [1000, 10000]:
		button(modes, formatted(value) + "s", func():
			mode = value
			if mode == 10000 and target == 5000:
				target = 10000
			render(), mode == value)

	label(content, "Winning score", 17, MINT)
	var targets := row(content)
	for value in ([5000, 10000, 15000] if mode == 1000 else [10000, 15000]):
		button(targets, formatted(value), func():
			target = value
			render(), target == value)

	label(content, "Dice", 17, MINT)
	var options := row(content)
	button(options, "Virtual", func():
		virtual = true
		render(), virtual)
	button(options, "Physical", func():
		virtual = false
		render(), not virtual)

	label(content, "Players · %d of 6" % names.size(), 17, MINT)
	for index in range(names.size()):
		var input := field(content, "Player %d" % (index + 1), names[index])
		input.max_length = 28
		input.text_changed.connect(func(value): names[index] = value)

	var player_actions := row(content)
	if names.size() > 2:
		button(player_actions, "Remove player", func():
			names.pop_back()
			render())
	if names.size() < 6:
		button(player_actions, "Add player", func():
			names.append("")
			render())

	button(content, "Start game", func():
		var players: Array = []
		for index in range(names.size()):
			var player_name: String = names[index].strip_edges()
			players.append(player_name if not player_name.is_empty() else "Player %d" % (index + 1))
		game.start(players, mode, target, virtual)
		refresh(), true)

func formatted(value: int) -> String:
	if absi(value) < 1000:
		return str(value)
	return "%s%d,%03d" % ["−" if value < 0 else "", absi(value) / 1000, absi(value) % 1000]

func turn_header(state: Dictionary) -> void:
	var won: bool = state.winner >= 0
	var player: Dictionary = state.players[state.winner if won else state.active]
	var panel := PanelContainer.new()
	var panel_style := style(Color("#1d4034"))
	panel_style.border_color = GOLD
	panel_style.border_width_left = 4
	panel_style.content_margin_left = 16
	panel.add_theme_stylebox_override("panel", panel_style)
	content.add_child(panel)

	var header := VBoxContainer.new()
	header.add_theme_constant_override("separation", 2)
	panel.add_child(header)
	var context := row(header)
	var status := label(context, "WINNER" if won else "CURRENT TURN", 13, GOLD)
	status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var match_info := label(context, "%ss  ·  %s dice" % [
		formatted(state.mode), "Virtual" if state.virtual else "Physical"], 13, MINT)
	match_info.autowrap_mode = TextServer.AUTOWRAP_OFF
	var player_name := label(header, player.name, 30)
	player_name.autowrap_mode = TextServer.AUTOWRAP_OFF
	player_name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	if not won:
		label(header, "%s needed to win  ·  Target %s" % [
			formatted(game.points_needed()), formatted(state.target)], 14, MINT)

func game_layout() -> void:
	var split := VBoxContainer.new()
	split.add_theme_constant_override("separation", 6)
	add_child(split)
	split.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var top := MarginContainer.new()
	for side in ["left", "right"]:
		top.add_theme_constant_override("margin_" + side, 16)
	top.add_theme_constant_override("margin_top", 6)
	split.add_child(top)
	content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 4)
	top.add_child(content)
	var logo := show_logo(32)
	var end_game := button(logo, "End game", confirm_new_game)
	end_game.add_theme_font_size_override("font_size", 13)
	end_game.custom_minimum_size.y = 0
	end_game.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
	var button_size := end_game.get_combined_minimum_size()
	end_game.offset_left = -button_size.x
	end_game.offset_right = 0
	end_game.offset_top = -button_size.y / 2.0
	end_game.offset_bottom = button_size.y / 2.0
	end_game.disabled = rolling or turn_ending
	var state := game.state
	turn_header(state)
	scoreboard(state)

	var play_area := PanelContainer.new()
	play_area.add_theme_stylebox_override("panel", style(Color("#142c23")))
	play_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.add_child(play_area)
	if state.virtual:
		virtual_play_area(play_area)
	else:
		var entry := ScrollContainer.new()
		entry.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		play_area.add_child(entry)
		content = inset_column(entry, 8)
		play_controls()

func inset_column(parent: ScrollContainer, spacing: int) -> VBoxContainer:
	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, spacing)
	parent.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	margin.add_child(column)
	return column

func virtual_play_area(parent: PanelContainer) -> void:
	var area := Control.new()
	parent.add_child(area)
	var state := game.state
	if not is_instance_valid(tray):
		tray = DiceTray.new()
		area.add_child(tray)
		if state.phase == "select":
			tray.show_saved_faces(state.rolled)
		else:
			tray.build_tray()
	else:
		area.add_child(tray)
	tray.can_select = false
	tray.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tray.offset_bottom = -150
	var controls := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		controls.add_theme_constant_override("margin_" + side, 4)
	area.add_child(controls)
	controls.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	controls.offset_top = -150
	content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 4)
	controls.add_child(content)
	play_controls()

func play_controls() -> void:
	var state := game.state
	if not save_error.is_empty():
		label(content, save_error, 14, GOLD)
	if state.winner >= 0:
		return
	if state.phase == "choice":
		button(content, "Take %s points · roll %d dice" % [
			formatted(state.offer_score), state.offer_dice], func():
			game.choose(true)
			refresh(), true)
		button(content, "Start fresh · roll six dice", func():
			game.choose(false)
			refresh())
	elif state.virtual:
		virtual_turn()
	else:
		physical_turn()

func scoreboard(state: Dictionary) -> void:
	var heading := row(content)
	var title := label(heading, "Scoreboard", 14, MINT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var detail := button(heading, "Details", show_scoreboard_details)
	detail.size_flags_horizontal = Control.SIZE_SHRINK_END
	detail.custom_minimum_size = Vector2(0, 30)
	detail.add_theme_font_size_override("font_size", 13)
	var compact := style(Color("#234638"))
	compact.content_margin_top = 4
	compact.content_margin_bottom = 4
	for state_name in ["normal", "hover", "pressed"]:
		detail.add_theme_stylebox_override(state_name, compact)
	detail.disabled = rolling

	var columns := row(content)
	columns.add_theme_constant_override("separation", 3)
	for index in range(state.players.size()):
		var player: Dictionary = state.players[index]
		var active: bool = index == state.active
		var card := PanelContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.custom_minimum_size.x = 52
		var card_style := style(Color("#234638") if active else Color("#152f26"))
		card_style.content_margin_left = 2
		card_style.content_margin_right = 2
		card_style.content_margin_top = 4
		card_style.content_margin_bottom = 4
		card.add_theme_stylebox_override("panel", card_style)
		columns.add_child(card)

		var cells := VBoxContainer.new()
		cells.add_theme_constant_override("separation", 1)
		card.add_child(cells)
		score_cell(cells, player.name, 13, GOLD if active else PAPER, true)
		score_labels.append(score_cell(cells, formatted(player.total), 14, PAPER))
		scoreboard_x_slots.append(x_markers(cells, player.xs))

func x_markers(parent: Control, earned: int) -> Array[Label]:
	var strip := HBoxContainer.new()
	strip.alignment = BoxContainer.ALIGNMENT_CENTER
	strip.add_theme_constant_override("separation", 3)
	strip.tooltip_text = "%d of 3 Xs" % earned
	parent.add_child(strip)
	var markers: Array[Label] = []
	for index in range(3):
		var color := Color("#ff575f") if index < earned else Color("#92989a")
		markers.append(score_cell(strip, "×", 14, color))
	return markers

func score_cell(parent: Control, value: String, font_size: int, color: Color, truncate := false) -> Label:
	var cell := label(parent, value, font_size, color)
	cell.autowrap_mode = TextServer.AUTOWRAP_OFF
	cell.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if truncate:
		cell.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	return cell

func show_scoreboard_details() -> void:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", style(Color("#0d241e")))
	add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var layout := VBoxContainer.new()
	panel.add_child(layout)
	var header := row(layout)
	var title := label(header, "Scoreboard", 24, GOLD)
	title.autowrap_mode = TextServer.AUTOWRAP_OFF
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var close := button(header, "Back", panel.queue_free)
	close.size_flags_horizontal = Control.SIZE_SHRINK_END
	close.grab_focus()
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	layout.add_child(scroll)
	var records := inset_column(scroll, 10)
	if not game.state.message.is_empty():
		label(records, game.state.message, 15, GOLD)
	for player in game.state.players:
		label(records, player.name, 20, GOLD)
		var summary := row(records)
		var total_label := label(summary, "Score %s" % formatted(player.total), 16)
		total_label.autowrap_mode = TextServer.AUTOWRAP_OFF
		x_markers(summary, player.xs)
		var recent: PackedStringArray = []
		for score in player.history.slice(-3):
			recent.append("X" if score == 0 else formatted(score))
		label(records, "Last turns: " + (", ".join(recent) if not recent.is_empty() else "—"), 15, MINT)
	button(layout, "New game", confirm_new_game)

func confirm_new_game() -> void:
	if game.state.winner >= 0:
		clear_game()
		return
	var dialog := ConfirmationDialog.new()
	dialog.title = "End this game?"
	dialog.dialog_text = "End this game and return to the new game setup?"
	dialog.ok_button_text = "End game"
	dialog.confirmed.connect(clear_game)
	dialog.close_requested.connect(dialog.queue_free)
	dialog.canceled.connect(dialog.queue_free)
	add_child(dialog)
	dialog.popup_centered()

func clear_game() -> void:
	rolling = false
	game.state = {}
	refresh()

func physical_turn() -> void:
	var state := game.state
	if state.points > 0:
		label(content, "Inherited %s points · start with %d dice" % [
			formatted(state.points), state.dice_left], 17, GOLD)
		label(content, "Score on your first roll to keep playing. Enter the points you add this turn.", 15, MINT)
	var input := field(content, "Points scored this turn")
	input.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_NUMBER
	var remaining: OptionButton
	if state.mode == 10000:
		label(content, "Dice left for the next player", 15, MINT)
		remaining = OptionButton.new()
		remaining.custom_minimum_size.y = 44
		for dice in range(1, 7):
			remaining.add_item(str(dice), dice)
		remaining.select(5)
		content.add_child(remaining)
	var feedback := label(content, "", 15, GOLD)
	button(content, "Bank score", func():
		var value := input.text.strip_edges()
		if not value.is_valid_int() or value.to_int() <= 0 or value.to_int() % 50 != 0:
			feedback.text = "Enter a positive multiple of 50, or tap Record X."
			return
		finish_turn(value.to_int() + state.points, remaining.get_selected_id() if remaining else 6), true)
	button(content, "Record X", func():
		finish_turn(0))

func virtual_turn() -> void:
	var state := game.state
	label(content, "Turn points   %s" % formatted(state.points), 24, GOLD)
	if not state.held.is_empty():
		var held: PackedStringArray = []
		for face in state.held:
			held.append(str(face))
		label(content, "Set aside: " + ", ".join(held), 16, MINT)
	if rolling:
		label(content, "Rolling…", 16, MINT)
		return
	if state.phase == "select":
		label(content, "Tap dice in the tray to choose what to keep.", 16, MINT)
		var actions := VBoxContainer.new()
		actions.add_theme_constant_override("separation", 8)
		content.add_child(actions)
		tray.can_select = true
		for connection in tray.die_tapped.get_connections():
			tray.die_tapped.disconnect(connection.callable)
		tray.die_tapped.connect(func(index: int):
			if selected_indices.has(index):
				selected_indices.erase(index)
			else:
				selected_indices.append(index)
			tray.set_die_selected(index, selected_indices.has(index))
			update_scoring_buttons(actions))
		return
	if state.mode == 1000:
		label(content, "%d rolls left" % state.rolls_left, 14, MINT)
	var turn_buttons := row(content)
	if state.mode == 10000 or state.rolls_left > 0:
		button(turn_buttons, "Roll %d %s" % [state.dice_left, "die" if state.dice_left == 1 else "dice"], animate_roll, true)
	if state.qualified:
		button(turn_buttons, "Bank %s" % formatted(state.points), func():
			finish_turn(state.points, state.dice_left), state.rolls_left == 0 and state.mode == 1000)

func animate_roll() -> void:
	if rolling:
		return
	rolling = true
	render()
	tray.finished.connect(func(faces: Array):
		rolling = false
		var player: Dictionary = game.state.players[game.state.active]
		var previous_xs: int = player.xs
		var previous_total: int = player.total
		var previous_turns: int = player.history.size()
		var player_index: int = game.state.active
		game.roll(faces)
		if player.history.size() > previous_turns:
			present_turn_end(player_index, previous_total, previous_xs)
		else:
			refresh(true), CONNECT_ONE_SHOT)
	tray.launch(game.state.dice_left)

func update_scoring_buttons(actions: VBoxContainer) -> void:
	for child in actions.get_children():
		actions.remove_child(child)
		child.queue_free()
	if selected_indices.is_empty():
		return
	var state := game.state
	var selected: Array = []
	for index in selected_indices:
		selected.append(state.rolled[index])
	var options: Array[Dictionary] = []
	for score in game.scores(selected):
		if state.points + score <= game.points_needed():
			options.append({"text": "+" + formatted(score), "score": score, "straight": false})
	if game.straight(selected):
		var score := game.straight_score()
		if state.points - state.cycle_points + score <= game.points_needed():
			options.append({"text": "Straight " + formatted(score), "score": score, "straight": true})
	if options.is_empty():
		label(actions, "Choose a scoring set that fits the target.", 15, MINT)
		return
	if options.size() == 1:
		var option := options[0]
		button(actions, "Keep " + option.text, func():
			game.keep(selected, option.score, option.straight)
			refresh(), true)
		return
	var choices := row(actions)
	var picker := OptionButton.new()
	picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	options.sort_custom(func(a: Dictionary, b: Dictionary): return a.score > b.score)
	for option in options:
		picker.add_item(option.text)
	picker.select(0)
	choices.add_child(picker)
	button(choices, "Keep dice", func():
		var option := options[picker.selected]
		game.keep(selected, option.score, option.straight)
		refresh(), true)

func finish_turn(score: int, dice_left := 6) -> void:
	if turn_ending:
		return
	var player_index: int = game.state.active
	var player: Dictionary = game.state.players[player_index]
	var previous_total: int = player.total
	var previous_xs: int = player.xs
	game.finish(score, dice_left)
	present_turn_end(player_index, previous_total, previous_xs)

func present_turn_end(player_index: int, previous_total: int, previous_xs: int) -> void:
	turn_ending = true
	save()
	get_viewport().gui_release_focus()
	var player: Dictionary = game.state.players[player_index]
	var banked: int = player.history.back()
	var new_total: int = player.total
	var total := score_labels[player_index]

	var overlay := ColorRect.new()
	overlay.color = Color(0.02, 0.07, 0.05, 0.68)
	add_child(overlay)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var badge := PanelContainer.new()
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var badge_style := style(Color("#19382e"))
	badge_style.set_border_width_all(2)
	badge_style.border_color = GOLD if banked > 0 else Color("#ffad9c")
	badge.add_theme_stylebox_override("panel", badge_style)
	overlay.add_child(badge)
	var badge_text := "+" + formatted(banked) if banked > 0 else ""
	if banked == 0:
		var marks: PackedStringArray = []
		marks.resize(previous_xs + 1)
		marks.fill("X")
		badge_text = "  ".join(marks)
	var result := label(badge, badge_text, 44, badge_style.border_color)
	result.autowrap_mode = TextServer.AUTOWRAP_OFF
	var origin := size * Vector2(0.5, 0.42)
	if is_instance_valid(tray):
		origin = tray.get_global_rect().get_center()
		origin.y = clampf(origin.y, 90.0, size.y - 110.0)
	await get_tree().process_frame
	badge.size = badge.get_combined_minimum_size()
	badge.position = origin - badge.size / 2.0
	badge.pivot_offset = badge.size / 2.0
	badge.scale = Vector2.ONE * 0.75
	var reveal := create_tween()
	reveal.tween_property(badge, "scale", Vector2.ONE, 0.30).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if banked > 0:
		pop_confetti(overlay, origin)
	await get_tree().create_timer(0.85 if banked > 0 else 1.1).timeout

	if banked == 0:
		var slot: Label = scoreboard_x_slots[player_index][previous_xs]
		result.text = "×"
		overlay.color.a = 0.12
		var strike := create_tween().set_parallel()
		strike.tween_property(badge, "position", slot.get_global_rect().get_center() - badge.size / 2.0, 0.48).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		strike.tween_property(badge, "scale", Vector2.ONE * 0.28, 0.48)
		await strike.finished
		slot.add_theme_color_override("font_color", Color("#ff575f"))
		badge.hide()
		await get_tree().create_timer(0.24).timeout
		if previous_xs == 2:
			for marker: Label in scoreboard_x_slots[player_index]:
				marker.add_theme_color_override("font_color", Color("#92989a"))

	if banked > 0 or previous_total != new_total:
		await get_tree().process_frame
		overlay.color.a = 0.12
		if banked > 0:
			var flight := create_tween().set_parallel()
			flight.tween_property(badge, "position", total.get_global_rect().get_center() - badge.size / 2.0, 0.55).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
			flight.tween_property(badge, "scale", Vector2.ONE * 0.34, 0.55)
			await flight.finished
		badge.hide()
		total.add_theme_color_override("font_color", GOLD)
		var count := create_tween()
		count.tween_method(func(score: float): total.text = formatted(roundi(score)),
			float(previous_total), float(new_total), 0.65).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		await count.finished
		await get_tree().create_timer(0.35).timeout
	badge.hide()
	overlay.color.a = 0.78

	var center := CenterContainer.new()
	overlay.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var card := PanelContainer.new()
	card.custom_minimum_size.x = minf(300.0, size.x - 48.0)
	card.add_theme_stylebox_override("panel", style(Color("#19382e")))
	center.add_child(card)
	var handoff := VBoxContainer.new()
	handoff.add_theme_constant_override("separation", 10)
	card.add_child(handoff)
	var won: bool = game.state.winner >= 0
	var next_player: Dictionary = game.state.players[game.state.active]
	var title := label(handoff, "Game won!" if won else "Pass the phone", 23, GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var heading := label(handoff, next_player.name, 30)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if banked == 0 and previous_xs == 2:
		var penalty := label(handoff, "%s hit 3 Xs and lost %s points." % [
			player.name, formatted(previous_total - new_total)], 16, MINT)
		penalty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button(handoff, "See results" if won else "I'm ready", func():
		turn_ending = false
		refresh(), true)

func pop_confetti(parent: Control, origin: Vector2) -> void:
	var colors := [GOLD, PAPER, Color("#7ed6a1"), Color("#ffa48c")]
	for index in range(28):
		var piece := ColorRect.new()
		piece.mouse_filter = Control.MOUSE_FILTER_IGNORE
		piece.color = colors[index % colors.size()]
		piece.size = Vector2(5, 10)
		var side := -1.0 if index % 2 == 0 else 1.0
		piece.position = origin + Vector2(side * 60.0, 18.0)
		parent.add_child(piece)
		parent.move_child(piece, 0)
		var burst := create_tween().set_parallel()
		burst.tween_property(piece, "position", piece.position + Vector2(
			side * randf_range(25.0, 100.0), randf_range(-106.0, 48.0)), 0.72).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		burst.tween_property(piece, "rotation", randf_range(-5.0, 5.0), 0.72)
		burst.tween_property(piece, "modulate:a", 0.0, 0.35).set_delay(0.36)
		burst.chain().tween_callback(piece.queue_free)
