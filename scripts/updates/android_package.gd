class_name NativeAndroidPackage
extends RefCounted
# Godot 4.7 exposes Java methods and static fields, not instance fields.
static func read(info)->Dictionary:
 if info==null:return {}
 var kind=info.getClass()
 var package_name=field_value(kind.getField("packageName"),info)
 var version_name=field_value(kind.getField("versionName"),info)
 var version_code=kind.getField("versionCode").getInt(info)
 var signatures=field_value(kind.getField("signatures"),info)
 if is_instance_valid(JavaClassWrapper.get_exception()) or not is_instance_valid(package_name) or not is_instance_valid(version_name) or not is_instance_valid(signatures):return {}
 var ArrayClass=JavaClassWrapper.wrap("java.lang.reflect.Array")
 var count:int=ArrayClass.getLength(signatures)
 if count<=0:return {}
 return {"package":package_name.toString(),"version":version_name.toString(),"code":int(version_code),"certificates":signatures,"certificate_count":count}
static func field_value(field,owner):
 # Field.get collides with Godot Object.get; invoke that Java method explicitly.
 var Class=JavaClassWrapper.wrap("java.lang.Class")
 var getter=field.getClass().getMethod("get",[Class.forName("java.lang.Object")])
 return getter.invoke(field,[owner])
