extends SceneTree

var checks: int = 0
var failed: int = 0

func _initialize() -> void:
	call_deferred("run")

func verify(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failed += 1
		printerr("FAIL: " + label)

func actors() -> Dictionary:
	return {"a": {"position": Vector2.ZERO, "hp": 100.0, "max_hp": 100.0, "down": false}, "b": {"position": Vector2(20, 0), "hp": 0.0, "max_hp": 125.0, "down": true}}

func run() -> void:
	var rules := CoopRules.new()
	var expected: Array = [[1,1,1,1],[1,1.5,1,1.44],[1,2,1,2.08],[1,2.5,1,2.72]]
	for n in range(1, 5):
		var scale: Dictionary = rules.scaling(n)
		for i in 4:
			verify(is_equal_approx(float(scale[["health", "damage", "speed", "count"][i]]), float(expected[n-1][i])), "additive scaling %d players" % n)
		verify(rules.wave_count(10, n) == [10,14,21,27][n-1], "consistent wave rounding")
		verify(rules.wave_count(1, n, true) == 1, "boss quantity is not multiplied")
		var composition: Dictionary = rules.composition({"ghoul": 10, "hound": 4, "guard": 3}, n)
		verify(composition.ghoul + composition.hound + composition.guard == rules.wave_count(17, n), "composition rounding preserves whole wave total")
		verify(composition == rules.composition({"guard": 3, "hound": 4, "ghoul": 10}, n), "composition rounding is independent of dictionary ordering")
	var state := actors()
	var reviver := ReviveAuthority.new()
	var actions := {"a": {"movement": Vector2.ZERO, "revive": true}}
	verify(reviver.update(4.99, state, actions).is_empty(), "revive cannot finish early")
	var events := reviver.update(0.01, state, actions)
	verify(events.size() == 1 and state.b.hp == 50.0 and not state.b.down, "revive restores exactly forty percent")
	verify(state.b.invulnerable == 2.0, "revive grants two seconds of protection")
	verify(reviver.update(10, state, actions).is_empty(), "completion cannot be duplicated")
	for cancellation in ["release", "move", "displace", "damage", "damage_healed", "distance", "down", "disconnect"]:
		state = actors()
		reviver = ReviveAuthority.new()
		actions = {"a": {"movement": Vector2.ZERO, "revive": true}}
		reviver.update(3, state, actions)
		match cancellation:
			"release": actions.a.revive = false
			"move": actions.a.movement = Vector2.RIGHT
			"displace": state.a.position += Vector2(0.05, 0)
			"damage": state.a.hp = 99
			"damage_healed": state.a.damage_revision = 1
			"distance": state.b.position = Vector2(200, 0)
			"down": state.a.down = true
			"disconnect": state.erase("a")
		verify(reviver.update(0.1, state, actions).is_empty(), "interruption does not complete: " + cancellation)
		verify(not reviver.interactions.has("a") and state.b.down, "interruption clears progress: " + cancellation)
	state = actors()
	state.c = {"position": Vector2(18,0), "hp": 100.0, "max_hp": 100.0, "down": false}
	reviver = ReviveAuthority.new()
	reviver.update(1, state, {"a": {"revive": true}, "c": {"revive": true}})
	verify(reviver.interactions.size() == 1, "one rescuer owns each body")
	state = actors()
	state.c = {"position": Vector2(25,0), "hp": 0.0, "max_hp": 100.0, "down": true}
	reviver = ReviveAuthority.new()
	reviver.update(1, state, actions)
	# Recreate clean held input after the interruption cases above.
	actions = {"a": {"movement": Vector2.ZERO, "revive": true}}
	reviver.update(1, state, actions)
	verify(reviver.interactions.a.target == "b", "nearest body is selected")
	state.c.position = Vector2(1,0)
	reviver.update(1, state, actions)
	verify(reviver.interactions.a.target == "b", "interaction keeps its original body")
	verify(not reviver.all_down(state), "living teammate prevents defeat")
	state.a.down = true
	verify(reviver.all_down(state), "all connected actors down means defeat")
	state.a.connected = false
	state.b.connected = false
	state.c.connected = false
	verify(not reviver.all_down(state), "empty connected party does not create defeat event")
	var inputs := CoopInputAuthority.new()
	verify(inputs.accept("a", {"sequence": 1, "movement": [100,100], "revive": true}, 0), "host accepts valid action")
	verify(inputs.current("a", 0).movement.length() <= 1.00001, "host normalizes excessive movement")
	verify(not inputs.accept("a", {"sequence": 1, "movement": [0,0]}, 0), "replayed action is rejected")
	verify(not inputs.accept("a", {"sequence": 2, "movement": [NAN,0]}, 0), "nonfinite movement is rejected")
	verify(not inputs.accept("a", {"sequence": INF, "movement": [0,0]}, 0), "nonfinite sequence is rejected")
	verify(not inputs.accept("a", {"sequence": 2, "movement": [0]}, 0), "malformed input is rejected")
	verify(not inputs.current("a", 0.4).revive, "stale input releases revive rather than holding forever")
	inputs.remove("a")
	verify(inputs.current("a", 0).movement == Vector2.ZERO, "disconnect removes authoritative input")
	print("NETWORK_FOUNDATION_%s checks=%d failures=%d" % ["PASS" if failed == 0 else "FAIL", checks, failed])
	quit(0 if failed == 0 else 1)
