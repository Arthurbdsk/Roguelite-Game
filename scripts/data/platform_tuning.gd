class_name PlatformTuning
extends RefCounted

static func mobile_visuals()->bool:
 return OS.has_feature("android") or "--mobile-preview" in OS.get_cmdline_user_args()

static func enemy_visual_multiplier()->float:
 return 0.8 if mobile_visuals() else 1.0

static func solo_spawn_multiplier(game)->float:
 return 0.6 if mobile_visuals() and not game.coop.active else 1.0
