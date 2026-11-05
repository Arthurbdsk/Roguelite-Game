class_name SnapshotCodec
extends RefCounted
const MAX_RAW:int=4194304
const MAX_PACKET:int=524288
static func pack(packet:Dictionary)->PackedByteArray:
 var raw:PackedByteArray=var_to_bytes(packet)
 if raw.size()>MAX_RAW:return PackedByteArray()
 var out:=PackedByteArray([72,20,0,0,0,0]);out.encode_u32(2,raw.size());out.append_array(raw.compress(FileAccess.COMPRESSION_ZSTD))
 return out if out.size()<=MAX_PACKET else PackedByteArray()
static func unpack(packet:PackedByteArray)->Dictionary:
 if packet.size()<7 or packet.size()>MAX_PACKET or packet[0]!=72 or packet[1]!=20:return {}
 var size:int=packet.decode_u32(2)
 if size<=0 or size>MAX_RAW:return {}
 var raw:PackedByteArray=packet.slice(6).decompress(size,FileAccess.COMPRESSION_ZSTD)
 if raw.size()!=size:return {}
 var value=bytes_to_var(raw)
 return value if value is Dictionary else {}
