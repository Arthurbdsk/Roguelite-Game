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
var envelope:String=""
var path:String="user://updates/download.part"
func platform()->String:return "android" if OS.has_feature("android") else "pc"
func setup(g):
 game=g;request=HTTPRequest.new();request.timeout=30;add_child(request);request.request_completed.connect(completed)
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://updates"))
 if FileAccess.file_exists(path):DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
func installed()->String:return str(ProjectSettings.get_setting("application/config/version"))
func version_code(s:String)->int:
 var a:=s.split("-")[0].split(".");return int(a[0])*1000000+(int(a[1])*1000 if a.size()>1 else 0)+(int(a[2]) if a.size()>2 else 0)
func available()->bool:return not release.is_empty() and version_code(str(release.version))>version_code(installed())
func check():
 if busy:return
 phase="manifest";busy=true;status="Verificando atualização...";changed.emit();request.body_size_limit=262144;request.download_file=""
 if request.request(endpoint)!=OK:fail("Sem conexão. Você pode jogar normalmente.")
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
  if not record is Dictionary or record.get("platform")!=platform() or not str(record.get("url","")).begins_with("https://") or int(record.get("size",0))<=0 or str(record.get("sha256","")).length()!=64:fail("Nenhuma versão válida publicada para esta plataforma.");return
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
 return f!=null and f.get_length()==int(release.size) and FileAccess.get_sha256(path)==str(release.sha256)
func download():
 if busy or not available():return
 var dir:=DirAccess.open("user://updates")
 if dir==null or dir.get_space_left()<int(release.size)*3:fail("Espaço insuficiente para baixar e manter uma cópia recuperável.");return
 install_ready=false;progress=0;busy=true;phase="download";status="Baixando atualização...";request.body_size_limit=int(release.size);request.download_file=path;changed.emit()
 if request.request(release.url)!=OK:fail("Não foi possível iniciar o download.")
func cancel():
 request.cancel_request();busy=false;install_ready=false;status="Download cancelado. Você pode tentar novamente."
 if FileAccess.file_exists(path):DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
 changed.emit()
func _process(_delta):
 if busy and phase=="download":progress=100.0*request.get_downloaded_bytes()/maxi(1,int(release.get("size",1)));changed.emit()
func install():
 if game.state=="running" or game.coop.active:status="Encerre a partida antes de instalar.";changed.emit();return
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
 if not pm.canRequestPackageInstalls():
  activity.startActivity(Intent.Intent("android.settings.MANAGE_UNKNOWN_APP_SOURCES",Uri.parse("package:"+activity.getPackageName())))
  status="Autorize instalar desta origem e toque em Instalar atualização novamente.";changed.emit();return
 var File=JavaClassWrapper.wrap("java.io.File");var provider=JavaClassWrapper.wrap("androidx.core.content.FileProvider")
 var uri=provider.getUriForFile(activity,activity.getPackageName()+".fileprovider",File.File(apk))
 var intent=Intent.Intent("android.intent.action.VIEW");intent.setDataAndType(uri,"application/vnd.android.package-archive");intent.addFlags(1);activity.startActivity(intent)
 status="Confirme no instalador do Android.";changed.emit()

func digest(bytes:PackedByteArray)->PackedByteArray:
 var h:=HashingContext.new();h.start(HashingContext.HASH_SHA256);h.update(bytes);return h.finish()
