extends RefCounted

var state: Dictionary

func start(names: Array, mode: int, target: int, virtual: bool) -> void:
	var players: Array = []
	for player_name in names:
		players.append({"name": player_name, "total": 0, "xs": 0, "history": []})
	state = {
		"players": players, "mode": mode, "target": target, "virtual": virtual,
		"active": 0, "winner": -1, "offer_score": 0, "offer_dice": 6, "offer_held": [], "offer_cycle_points": 0, "message": ""
	}
	reset_turn()

func reset_turn() -> void:
	state.merge({
		"phase": "choice" if state.offer_score > 0 else "ready",
		"points": 0, "cycle_points": 0, "held": [], "dice_left": 6,
		"rolls_left": 3, "rolled": [], "qualified": false
	}, true)

func choose(inherit: bool) -> void:
	if inherit:
		state.points = state.offer_score
		state.dice_left = state.offer_dice
		state.held = state.offer_held.duplicate()
		state.cycle_points = state.offer_cycle_points
	state.phase = "ready"

func roll(faces: Array) -> void:
	state.rolled = faces
	state.rolls_left -= 1
	state.phase = "select"
	state.message = ""
	var count := 1 << faces.size()
	for mask in range(1, count):
		var selected: Array = []
		for index in range(faces.size()):
			if mask & (1 << index):
				selected.append(faces[index])
		if playable(selected):
			return
	finish(0)

func straight(selected: Array) -> bool:
	var combined: Array = state.held + selected
	combined.sort()
	return combined == [1, 2, 3, 4, 5, 6]

func scores(selected: Array) -> Array:
	if selected.is_empty():
		return []
	var totals := [0]
	for face in range(1, 7):
		var group := face_scores(face, selected.count(face))
		var next: Array = []
		for total in totals:
			for value in group:
				if not next.has(total + value):
					next.append(total + value)
		totals = next
	totals.sort()
	return totals

func face_scores(face: int, count: int) -> Array:
	if count == 0:
		return [0]
	var results: Array = []
	if face == 1 or face == 5:
		var single := 100 if face == 1 else 50
		for rest in face_scores(face, count - 1):
			results.append(rest + single)
	if count >= 3:
		var triple := 1000 if face == 1 else face * 100
		for rest in face_scores(face, count - 3):
			results.append(rest + triple)
		if state.mode == 10000 and count >= 4:
			for rest in face_scores(face, count - 4):
				results.append(rest + triple * 10)
	return results

func straight_score() -> int:
	return 1000 if state.mode == 10000 else 500

func playable(selected: Array) -> bool:
	var remaining: int = points_needed()
	if straight(selected) and state.points - state.cycle_points + straight_score() <= remaining:
		return true
	for score in scores(selected):
		if state.points + score <= remaining:
			return true
	return false

func points_needed() -> int:
	return state.target - state.players[state.active].total

func keep(selected: Array, points: int, use_straight: bool) -> void:
	if use_straight:
		state.points -= state.cycle_points
		state.cycle_points = 0
	state.points += points
	state.cycle_points += points
	state.held.append_array(selected)
	state.dice_left -= selected.size()
	state.qualified = true
	state.rolled = []
	state.phase = "ready"
	if state.dice_left == 0:
		state.held = []
		state.cycle_points = 0
		state.dice_left = 6
		state.rolls_left = 1
		state.message = "All six scored. Roll all six again or bank."
	if state.mode == 1000 and state.rolls_left == 0:
		state.message = "No rolls left. Bank your points."

func finish(score: int, dice_left: int = 6) -> void:
	var player: Dictionary = state.players[state.active]
	var overshot := score > points_needed()
	if overshot:
		score = 0
	state.offer_score = score if state.mode == 10000 else 0
	state.offer_dice = dice_left
	state.offer_held = state.held.duplicate()
	state.offer_cycle_points = state.cycle_points
	state.message = "%s banked %s." % [player.name, score]
	if score == 0:
		player.xs += 1
		state.message = "%s took an X." % player.name
		if overshot:
			state.message += " The score went over the target."
		if player.xs == 3:
			var penalty := 500 if state.mode == 1000 else 1000
			player.xs = 0
			player.total -= penalty
			state.message += " Third X: −%s points." % penalty
	player.history.append(score)
	player.total += score
	if player.total == state.target:
		state.winner = state.active
		return
	state.active = (state.active + 1) % state.players.size()
	reset_turn()
