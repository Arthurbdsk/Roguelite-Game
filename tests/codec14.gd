extends SceneTree
func _initialize():call_deferred("run")
func run():
 var changes:Array=[]
 for i in 225:changes.append({"id":"e"+str(i),"kind":"enemy","species":"ghoul","position":Vector2(500+i%25*22,400+int(i/25)*23),"velocity":Vector2(13.5,-12.2),"hp":343.5,"max_hp":600.5,"frame":i%4,"state":"approach"})
 var packet:Dictionary={"type":"delta","data":{"full":true,"changes":changes,"removals":[],"elapsed":1800.5}}
 var json_start:int=Time.get_ticks_usec();var old:PackedByteArray=JSON.stringify({"type":"delta","data":CoopWire.encode(packet.data)}).to_utf8_buffer();var json_us:int=Time.get_ticks_usec()-json_start
 var start:int=Time.get_ticks_usec();var packed:PackedByteArray=SnapshotCodec.pack(packet);var pack_us:int=Time.get_ticks_usec()-start
 start=Time.get_ticks_usec();var result:Dictionary=SnapshotCodec.unpack(packed);var unpack_us:int=Time.get_ticks_usec()-start
 assert(result==packet and packed.size()<old.size())
 assert(SnapshotCodec.unpack(PackedByteArray()).is_empty())
 var invalid:=PackedByteArray([72,20,0,0,0,0,1]);invalid.encode_u32(2,SnapshotCodec.MAX_RAW+1);assert(SnapshotCodec.unpack(invalid).is_empty())
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame;g.set_physics_process(false);g.start_run();g.persistence_enabled=false
 var actor:=CoopActor.new();actor.setup(g,g.coop,{"id":"fixture","name":"Test","skills":{}},true)
 for id in actor.weapon_system.WEAPON_PATHS:actor.weapon_system.levels[id]=8
 for id in actor.weapon_system.PASSIVE_PATHS:actor.weapon_system.passives[id]=8
 actor.offers=actor.weapon_system.get_offers();var before:int=g.gold;assert(actor.choose("supplies",actor.generation));assert(g.gold==before+10)
 actor.release();actor=null;g.queue_free();g=null;await process_frame;await create_timer(.2).timeout
 print("CODEC14_PASS raw_json_bytes=%d binary_zstd_bytes=%d json_us=%d encode_us=%d decode_us=%d native_vectors_exact=true bounded_decompression=true"%[old.size(),packed.size(),json_us,pack_us,unpack_us]);quit()
