class_name UpdateView
extends MarginContainer
var service:UpdateService
var info:Label
var bar:ProgressBar
var download_button:Button
var install_button:Button
var bootstrap_button:Button
func setup(g,ui):
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 for side in ["left","right","top","bottom"]:add_theme_constant_override("margin_"+side,18)
 var scroll:=ScrollContainer.new();add_child(scroll);var list:=VBoxContainer.new();list.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(list);scroll.scroll_deadzone=12;scroll.follow_focus=true
 service=g.updates
 var back_screen:String=str(ui.previous_data.get("return","title"))
 if OS.has_feature("android"):
  var safe:Rect2=g.mobile.safe
  offset_left=safe.position.x;offset_top=safe.position.y;offset_right=safe.end.x-g.get_viewport_rect().size.x;offset_bottom=safe.end.y-g.get_viewport_rect().size.y
 var title:=Label.new();title.text="Atualizações";list.add_child(title)
 info=Label.new();info.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;list.add_child(info)
 bar=ProgressBar.new();bar.custom_minimum_size.y=18;list.add_child(bar)
 if OS.get_name()=="Windows":
  bootstrap_button=Button.new();bootstrap_button.text="Instalar nesta conta";bootstrap_button.custom_minimum_size.y=44;bootstrap_button.pressed.connect(service.prepare_user_install);list.add_child(bootstrap_button)
 for spec in [["Verificar atualização",service.check],["Baixar atualização",service.download],["Cancelar",service.cancel],["Tentar novamente",service.check],["Instalar atualização",service.install],["Voltar",func():g.show_title() if back_screen=="title" else ui.render(back_screen)]]:
  var b:=Button.new();b.text=spec[0];b.custom_minimum_size.y=44;b.pressed.connect(spec[1]);list.add_child(b)
  if spec[0]=="Baixar atualização":download_button=b
  if spec[0]=="Instalar atualização":install_button=b
 service.changed.connect(refresh);refresh()
 if OS.has_feature("android"):
  MobileScrolling.prepare(self)
func refresh():
 var r:Dictionary=service.release
 info.text="Instalada: %s\nDisponível: %s\nDownload: %s MB\n%s\n\n%s\n\nMultiplayer: %s"%[service.installed(),r.get("version","não verificada"),str(int(r.get("size",0))/1048576),r.get("notes",""),service.status,r.get("compatible_versions","Use PC e Android com o mesmo conteúdo desta entrega.")]
 bar.value=service.progress;download_button.disabled=service.busy or not service.available();install_button.disabled=not service.install_ready
 install_button.text="Instalar atualização" if service.platform()=="android" else "Reiniciar e atualizar"
 if bootstrap_button!=null:bootstrap_button.disabled=not service.bootstrap_possible()
