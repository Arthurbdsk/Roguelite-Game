class_name UpdateService
extends Node
signal changed
const ENDPOINT="https://raw.githubusercontent.com/Arthurbdsk/Roguelite-Game/codex/release-channel/stable.json"
var endpoint:String=ENDPOINT
var game
var status:String="Verifique se há uma atualização."
var release:Dictionary={}
var busy:bool=false
var install_ready:bool=false
var progress:float=0
var request:HTTPRequest
var phase:String=""
var fetch_pid:int=-1
var fetch_path:String=""
var test_tls_pin:String=""
var envelope:String=""
var path:String="user://updates/download.part"
func platform()->String:return "android" if OS.has_feature("android") else "pc"
func setup(g):
 game=g;request=HTTPRequest.new();request.timeout=30;add_child(request);request.request_completed.connect(completed)
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://updates"))
 if FileAccess.file_exists(path):DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
func installed()->String:return str(ProjectSettings.get_setting("application/config/version"))
func version_code(s:String)->int:
 var a:=s.split("-")[0].split(".");return (int(a[0])*1000000+(int(a[1])*1000 if a.size()>1 else 0)+(int(a[2]) if a.size()>2 else 0))*1000+(int(s.get_slice("android.",1)) if s.contains("android.") else 0)
func available()->bool:return not release.is_empty() and version_code(str(release.get("version",installed())))>version_code(installed())
func online_blocked()->bool:return bool(release.get("online_required",false)) and release.get("compatibility",GameCompatibility.identity())!=GameCompatibility.identity()
func check():
 if busy:return
 phase="manifest";busy=true;status="Verificando atualização...";changed.emit();request.body_size_limit=262144;request.download_file=""
 if start_request(endpoint,262144,true)!=OK:fail("Sem conexão. Você pode jogar normalmente.")
func fail(message:String):busy=false;install_ready=false;status=message;changed.emit()
func verify_manifest(text:String)->Dictionary:
 var e=JSON.parse_string(text)
 if not e is Dictionary or not e.get("payload") is String or not e.get("signature") is String:return {}
 var bytes:=Marshalls.base64_to_raw(e.payload);var key:=CryptoKey.new()
 if key.load("res://data/updates/public.pem",true)!=OK:return {}
 if not Crypto.new().verify(HashingContext.HASH_SHA256,digest(bytes),Marshalls.base64_to_raw(e.signature),key):return {}
 var data=JSON.parse_string(bytes.get_string_from_utf8())
 if not data is Dictionary or data.get("schema")!=1 or int(data.get("expires",0))<int(Time.get_unix_time_from_system()):return {}
 return data
func completed(result:int,code:int,_headers:PackedStringArray,body:PackedByteArray):
 busy=false
 if result!=HTTPRequest.RESULT_SUCCESS or code!=200:fail("Servidor indisponível ou download interrompido. Tente novamente; o jogo continua disponível.");return
 if phase=="manifest":
  var text:=body.get_string_from_utf8();var data:=verify_manifest(text)
  if data.is_empty():fail("Manifesto inválido, vencido ou sem assinatura confiável.");return
  var record=data.get("platforms",{}).get(platform(),{})
  if not record is Dictionary or not record.get("version") is String or record.get("platform")!=platform() or not str(record.get("url","")).begins_with("https://") or int(record.get("size",0))<=0 or str(record.get("sha256","")).length()!=64:fail("Nenhuma versão válida publicada para esta plataforma.");return
  envelope=text;release=record
  if game.ui.screen=="title":game.ui.call_deferred("render","title")
  status="Atualização disponível." if available() else "Você está na versão mais recente";changed.emit()
 else:
  if not validate_download():fail("Arquivo inválido ou incompleto. A instalação atual foi preservada.");return
  install_ready=true;progress=100;status="Instalar atualização" if platform()=="android" else "Reiniciar e atualizar";changed.emit()
func validate_download()->bool:
 var data:=verify_manifest(envelope)
 if data.is_empty() or data.get("platforms",{}).get(platform(),{})!=release:return false
 if not FileAccess.file_exists(path):return false
 var f:=FileAccess.open(path,FileAccess.READ)
 if f==null or f.get_length()!=int(release.size) or FileAccess.get_sha256(path)!=str(release.sha256):return false
 return f.get_16()==0x5a4d if platform()=="pc" else f.get_32()==0x04034b50
func download():
 if busy or not available():return
 var dir:=DirAccess.open("user://updates")
 if dir==null or dir.get_space_left()<int(release.size)*3:fail("Espaço insuficiente para baixar e manter uma cópia recuperável.");return
 install_ready=false;progress=0;busy=true;phase="download";status="Baixando atualização...";request.body_size_limit=int(release.size);request.download_file=path;changed.emit()
 if start_request(release.url,int(release.size),false)!=OK:fail("Não foi possível iniciar o download.")
func cancel():
 if fetch_pid>0:OS.kill(fetch_pid);fetch_pid=-1
 request.cancel_request();busy=false;install_ready=false;status="Download cancelado. Você pode tentar novamente."
 if FileAccess.file_exists(path):DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
 changed.emit()
func _process(_delta):
 if fetch_pid>0:
  if FileAccess.file_exists(fetch_path+".progress") and phase=="download":progress=100.0*int(FileAccess.get_file_as_string(fetch_path+".progress"))/maxi(1,int(release.get("size",1)));changed.emit()
  if not OS.is_process_running(fetch_pid):
   fetch_pid=-1
   var ok:bool=FileAccess.file_exists(fetch_path+".result") and FileAccess.get_file_as_string(fetch_path+".result")=="200"
   completed(HTTPRequest.RESULT_SUCCESS if ok else HTTPRequest.RESULT_CANT_CONNECT,200 if ok else 0,PackedStringArray(),FileAccess.get_file_as_bytes(fetch_path) if phase=="manifest" and ok else PackedByteArray())
 elif busy and phase=="download":progress=100.0*request.get_downloaded_bytes()/maxi(1,int(release.get("size",1)));changed.emit()
func start_request(url:String,limit:int,manifest:bool)->int:
 if OS.get_name()!="Windows":return request.request(url)
 fetch_path="user://updates/manifest.part" if manifest else path
 for suffix in [".result",".progress"]:
  if FileAccess.file_exists(fetch_path+suffix):DirAccess.remove_absolute(ProjectSettings.globalize_path(fetch_path+suffix))
 var helper_path:=ProjectSettings.globalize_path("user://updates/Fetch.exe")
 var helper:=FileAccess.open(helper_path,FileAccess.WRITE)
 if helper==null:return ERR_CANT_CREATE
 helper.store_buffer(FileAccess.get_file_as_bytes("res://data/updates/Updater.exe"));helper.close()
 var args:=PackedStringArray(["--fetch",url,ProjectSettings.globalize_path(fetch_path),str(limit)])
 if game.test_mode and not test_tls_pin.is_empty():args.append(test_tls_pin)
 fetch_pid=OS.create_process(helper_path,args)
 return OK if fetch_pid>0 else ERR_CANT_FORK
func install():
 if game.state not in ["title","hub","online"] or game.coop.active:status="Encerre a partida antes de instalar.";changed.emit();return
 if not install_ready or not validate_download():fail("Validação falhou. Baixe novamente.");return
 if platform()=="android":install_android();return
 var folder:=ProjectSettings.globalize_path("user://updates/")
 var f:=FileAccess.open(folder+"request.json",FileAccess.WRITE);f.store_string(JSON.stringify({"envelope":envelope,"pid":OS.get_process_id(),"old":OS.get_executable_path()}));f.close()
 var helper:=FileAccess.open(folder+"Updater.exe",FileAccess.WRITE);helper.store_buffer(FileAccess.get_file_as_bytes("res://data/updates/Updater.exe"));helper.close()
 if OS.create_process(folder+"Updater.exe",[folder+"request.json"])<=0:fail("Não foi possível iniciar o atualizador.");return
 game.bestiary.flush();game.profile.save();get_tree().quit()
func install_android():
 if not Engine.has_singleton("AndroidRuntime"):fail("Instalador Android indisponível.");return
 var activity=Engine.get_singleton("AndroidRuntime").getActivity();var pm=activity.getPackageManager();var apk:=ProjectSettings.globalize_path(path)
 var incoming=pm.getPackageArchiveInfo(apk,64);var current=pm.getPackageInfo(activity.getPackageName(),64)
 if incoming==null or incoming.packageName!=current.packageName or incoming.signatures.size()!=current.signatures.size():fail("APK incompatível.");return
 for i in current.signatures.size():
  if not current.signatures[i].equals(incoming.signatures[i]):fail("Assinatura do APK incompatível.");return
 var Intent=JavaClassWrapper.wrap("android.content.Intent");var Uri=JavaClassWrapper.wrap("android.net.Uri")
 var sdk=JavaClassWrapper.wrap("android.os.Build$VERSION")
 if int(sdk.SDK_INT)>=26 and not pm.canRequestPackageInstalls():
  activity.startActivity(Intent.Intent("android.settings.MANAGE_UNKNOWN_APP_SOURCES",Uri.parse("package:"+activity.getPackageName())))
  status="Autorize instalar desta origem e toque em Instalar atualização novamente.";changed.emit();return
 var File=JavaClassWrapper.wrap("java.io.File");var provider=JavaClassWrapper.wrap("androidx.core.content.FileProvider")
 var uri=provider.getUriForFile(activity,activity.getPackageName()+".fileprovider",File.File(apk))
 var intent=Intent.Intent("android.intent.action.VIEW");intent.setDataAndType(uri,"application/vnd.android.package-archive");intent.addFlags(1);activity.startActivity(intent)
 status="Confirme no instalador do Android.";changed.emit()

func digest(bytes:PackedByteArray)->PackedByteArray:
 var h:=HashingContext.new();h.start(HashingContext.HASH_SHA256);h.update(bytes);return h.finish()
func _exit_tree():
 if fetch_pid>0 and OS.is_process_running(fetch_pid):OS.kill(fetch_pid)
