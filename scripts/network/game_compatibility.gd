class_name GameCompatibility
extends RefCounted
const PROTOCOL:int=2
static func identity()->String:
 var parsed=JSON.parse_string(FileAccess.get_file_as_string("res://data/gameplay_manifest.json"))
 if not parsed is Dictionary or parsed.get("protocol",0)!=PROTOCOL:return ""
 return str(parsed.get("compatibility_id",""))
