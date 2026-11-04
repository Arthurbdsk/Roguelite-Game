class_name CoopInputAuthority
extends RefCounted

var last_sequence: Dictionary = {}
var last_received: Dictionary = {}
var actions: Dictionary = {}
var timeout: float = 0.35

func accept(peer: String, payload: Dictionary, now: float) -> bool:
	var sequence = payload.get("sequence", null)
	var movement = payload.get("movement", null)
	if not (sequence is int or sequence is float) or not is_finite(float(sequence)) or int(sequence) != sequence or sequence < 0 or sequence > 2147483647:
		return false
	if int(sequence) <= int(last_sequence.get(peer, -1)) or not movement is Array or movement.size() != 2:
		return false
	for component in movement:
		if not (component is float or component is int) or not is_finite(float(component)):
			return false
	last_sequence[peer] = int(sequence)
	last_received[peer] = now
	actions[peer] = {"movement": Vector2(float(movement[0]), float(movement[1])).limit_length(), "revive": payload.get("revive", false) == true,"self_revive":payload.get("self_revive",false)==true}
	return true

func current(peer: String, now: float) -> Dictionary:
	if now - float(last_received.get(peer, -999)) > timeout:
		return {"movement": Vector2.ZERO, "revive": false}
	return actions[peer]

func remove(peer: String) -> void:
	last_sequence.erase(peer)
	last_received.erase(peer)
	actions.erase(peer)
