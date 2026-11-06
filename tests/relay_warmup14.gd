extends SceneTree
var failures:int=0
func _initialize()->void:call_deferred("run")
func check(value:bool,label:String)->void:
 if not value:failures+=1;printerr("FAIL "+label)
func prepare(c:RoomConnection)->void:
 c.warmup=HTTPRequest.new()
 c.add_child(c.warmup)
 c.warmup_started=Time.get_ticks_msec()
 c.pending={"type":"create"}
func run()->void:
 var c:=RoomConnection.new()
 root.add_child(c)
 c.endpoint="ws://127.0.0.1:9"
 prepare(c)
 c._warmup_finished(HTTPRequest.RESULT_SUCCESS,200,PackedStringArray(),'{"ok":true,"supported":[1,2]}'.to_utf8_buffer())
 check(c.socket!=null and c.warmup==null and c.pending.type=="create","numeric JSON protocol opens socket and preserves join request")
 c.close()
 prepare(c)
 c._warmup_finished(HTTPRequest.RESULT_SUCCESS,503,PackedStringArray(),"Not Found".to_utf8_buffer())
 check(c.warmup!=null and c.socket==null,"temporary non-JSON response waits without opening socket")
 c.close()
 await create_timer(2.1).timeout
 check(c.warmup==null and c.socket==null and c.pending.is_empty(),"cancelled retry cannot revive connection")
 var errors:Array=[]
 c.connection_failed.connect(func(reason):errors.append(reason))
 prepare(c)
 c.warmup_started=Time.get_ticks_msec()-91000
 c._warmup_finished(HTTPRequest.RESULT_TIMEOUT,0,PackedStringArray(),PackedByteArray())
 check(errors.size()==1 and c.warmup==null and c.pending.is_empty(),"startup deadline cleans request and reports error once")
 c.queue_free()
 await process_frame
 await process_frame
 print("RELAY_WARMUP14_%s" % ("PASS" if failures==0 else "FAIL"))
 quit(0 if failures==0 else 1)
