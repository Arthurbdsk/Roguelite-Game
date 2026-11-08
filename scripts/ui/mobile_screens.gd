class_name MobileScreens
extends RefCounted
var ui
var game
var scrolls:Dictionary={}
var last_purchase:int=-1000
var collection_selected:int=0
func remember():
 if ui==null:return
 for n in ui.menu.find_children("*","ScrollContainer",true,false):scrolls[ui.screen+str(n.name)]=n.scroll_vertical
func restore():
 for n in ui.menu.find_children("*","ScrollContainer",true,false):n.set_deferred("scroll_vertical",scrolls.get(ui.screen+str(n.name),0))
func text(parent,value:String,font_size:int=14)->Label:
 var l:=Label.new();l.text=DisplayNumbers.clean(value.replace("0.20.0","PC_VERSION")).replace("PC_VERSION","0.20.0");l.add_theme_font_size_override("font_size",font_size);l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;l.size_flags_horizontal=Control.SIZE_EXPAND_FILL;l.mouse_filter=Control.MOUSE_FILTER_IGNORE;parent.add_child(l);return l
func button(parent,value:String,action:Callable)->Button:
 var b:=Button.new();b.text=value;b.custom_minimum_size=Vector2(44,44);b.size_flags_horizontal=Control.SIZE_EXPAND_FILL;b.add_theme_font_size_override("font_size",14);b.pressed.connect(action);parent.add_child(b);return b
func icon(parent,path:String):
 var i:=TextureRect.new();i.texture=load(path) if ResourceLoader.exists(path) else null;i.custom_minimum_size=Vector2(32,32);i.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;i.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;i.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;i.mouse_filter=Control.MOUSE_FILTER_IGNORE;parent.add_child(i)
func row(parent)->HBoxContainer:
 var h:=HBoxContainer.new();h.add_theme_constant_override("separation",10);parent.add_child(h);return h
func column(parent)->VBoxContainer:
 var v:=VBoxContainer.new();v.add_theme_constant_override("separation",8);v.size_flags_horizontal=Control.SIZE_EXPAND_FILL;parent.add_child(v);return v
func scroll(parent,node_name:String="PageScroll")->VBoxContainer:
 var s:=ScrollContainer.new();s.name=node_name;s.size_flags_vertical=Control.SIZE_EXPAND_FILL;s.size_flags_horizontal=Control.SIZE_EXPAND_FILL;s.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;s.follow_focus=true;s.scroll_deadzone=12;parent.add_child(s)
 return column(s)
func page(title:String,back:Callable=Callable())->VBoxContainer:
 var p:=PanelContainer.new();p.position=game.mobile.safe.position;p.size=game.mobile.safe.size;p.add_theme_stylebox_override("panel",ui._style(Color("142238"),ui.LINE));ui.menu.add_child(p)
 var v:=column(p);var h:=row(v);text(h,title,20)
 if back.is_valid():button(h,"Voltar",back).custom_minimum_size.x=86
 return v
func close_run_panel():
 game.mobile.reset()
 if game.coop.active:game.coop.close_menu()
 else:game.state="running";ui.render("running");ui.update_hud(game.snapshot())
func render(interface,which:String,data:Dictionary)->bool:
 ui=interface;game=ui.game
 match which:
  "running":return true
  "title":title()
  "maps":maps()
  "hub":hub()
  "tree":permanent()
  "collection":collection()
  "bestiary":
   var view:=BestiaryView.new();ui.menu.add_child(view);view.setup(game,ui)
  "online","lobby":online(which)
  "paused","online_pause":pause_page()
  "mobile_build":build_page()
  "settings":settings()
  "upgrading":upgrades(data)
  "result":result(data)
  "revive_offer":revive()
  "endless_choice":endless()
  "mobile_privacy","mobile_terms":legal(which)
  _:return false
 restore();return true
func title():
 var v:=page("Hordas Android")
 text(v,"Android %s | Base PC %s | Rede %d | Ouro: %d"%[ProjectSettings.get_setting("application/config/version"),GameCompatibility.identity().get_slice("+",0),GameCompatibility.PROTOCOL,game.profile.data.gold],13)
 var grid:=GridContainer.new();grid.columns=2;grid.add_theme_constant_override("h_separation",10);grid.add_theme_constant_override("v_separation",8);grid.size_flags_vertical=Control.SIZE_EXPAND_FILL;v.add_child(grid)
 button(grid,"Jogar",game.open_map_select)
 button(grid,"Cooperativo online",game.open_online)
 button(grid,"Aprimoramentos",game.open_skill_tree)
 var books:=row(grid)
 button(books,"Coleção",func():ui.render("collection"))
 button(books,"Bestiário",func():ui.bestiary_return="title";ui.render("bestiary"))
 button(grid,"Opções",func():ui._open_settings("title"))
 button(grid,"Base",game.enter_hub)
 button(grid,"Atualizações (nova)" if game.updates!=null and game.updates.available() else "Atualizações",func():ui.render("updates"))
 var links:=row(v)
 button(links,"Privacidade",func():ui.render("mobile_privacy"))
 button(links,"Termos",func():ui.render("mobile_terms"))
 button(links,"Feito por Socialy",func():OS.shell_open("https://www.instagram.com/socialy_webdesign/"))
func maps():
 var v:=page("Escolha o mapa",game.show_title);var list:=scroll(v)
 for spec in [["courtyard","Pátio","Pedra e espaço aberto."],["library","Biblioteca","Corredores largos entre as estantes."],["fields","Campos","Grama, árvores e construções."]]:
  var id:String=spec[0]
  button(list,spec[1]+"\n"+spec[2],func():game.selected_map=id;game.start_run(ui.selected_support)).custom_minimum_size.y=64
func hub():
 var v:=page("Base",game.show_title);var list:=scroll(v)
 text(list,"%d medalhas | %d ouro"%[game.profile.data.seals,game.profile.data.gold])
 button(list,"Aprimoramentos permanentes",game.open_skill_tree)
 button(list,"Bestiário",func():ui.bestiary_return="hub";ui.render("bestiary"))
 for spec in [["arsenal","Arsenal"],["library","Biblioteca"]]:
  var id:String=spec[0];var owned:bool=game.profile.data.buildings.get(id,false)
  var b:=button(list,spec[1]+(" disponível" if owned else ": 8 medalhas"),func():game.buy_building(id);ui.render("hub"))
  b.disabled=owned or game.profile.data.seals<8
 text(list,"Apoio para a próxima partida")
 for spec in [["none","Sem apoio"],["arsenal","Arsenal: Arco inicial"],["library","Biblioteca: Orbes iniciais"]]:
  var id:String=spec[0];var b:=button(list,("Selecionado: " if ui.selected_support==id else "")+spec[1],func():ui._select_support(id))
  b.disabled=id!="none" and not game.profile.data.buildings.get(id,false)
 button(list,"Escolher mapa",game.open_map_select)
func build_items(parent):
 text(parent,"Build atual",17)
 for spec in [[game.weapon_system.get_loadout(),"Armas",6],[game.weapon_system.get_passives(),"Passivas",4]]:
  text(parent,"%s: %d/%d"%[spec[1],spec[0].size(),spec[2]],13)
  for item in spec[0]:
   var h:=row(parent);icon(h,item.icon);text(h,"%s | %s"%[item.name,"Máximo" if item.level==8 else "Nível %d"%item.level],13)
  if spec[0].size()<int(spec[2]):text(parent,"%d espaços livres"%(int(spec[2])-spec[0].size()),12)
 text(parent,game.weapon_system.build_stats(),13)
func build_page():
 var v:=page("Build",close_run_panel);build_items(scroll(v))
func pause_page():
 var v:=page("Menu online" if game.coop.active else "Pausa",close_run_panel)
 if game.coop.active:text(v,"A partida online continua para todos.",13)
 var list:=scroll(v);button(list,"Continuar",close_run_panel);button(list,"Ver build",func():ui.render("mobile_build"));button(list,"Opções",func():ui._open_settings(ui.screen))
 if game.coop.active:
  var can_return:bool=game.coop.actors[game.coop.connection.peer_id].mastery.can_revive() if game.coop.hosting else game.coop.received_personal.get("revive_available",false)
  if game.player.down and can_return:button(list,"Usar Reviver",game.coop.request_self_revive)
  button(list,"Sair da partida",game.coop.leave)
 else:
  button(list,"Reiniciar partida",game.retry);button(list,"Voltar à base",game.abandon)
func settings():
 var v:=page("Opções",func():ui.render(ui.return_screen,game.profile.data));var list:=scroll(v)
 for spec in [["volume","Efeitos sonoros"],["music","Música"],["effects","Detalhes visuais"]]:
  var key:String=spec[0];var h:=row(list);text(h,spec[1]);var value:=text(h,"%d%%"%roundi(float(game.profile.data.settings.get(key,.4))*100),13);value.custom_minimum_size.x=48
  var slider:=HSlider.new();slider.name="MobileOption_"+key;slider.custom_minimum_size=Vector2(180,44);slider.size_flags_horizontal=Control.SIZE_EXPAND_FILL;slider.min_value=0;slider.max_value=1;slider.step=.05;slider.value=game.profile.data.settings.get(key,.4);list.add_child(slider)
  slider.value_changed.connect(func(n):game.set_option(key,n);value.text="%d%%"%roundi(n*100))
 var shake:=CheckButton.new();shake.text="Tremor de tela";shake.custom_minimum_size.y=44;shake.button_pressed=game.profile.data.settings.shake;shake.toggled.connect(func(n):game.set_option("shake",n));list.add_child(shake)
 text(list,"Detalhes alteram somente efeitos decorativos. Inimigos, ataques e recompensas continuam iguais.",13)
 if game.mobile_performance!=null:
  var measured:Dictionary=game.mobile_performance.report()
  text(list,"Último trecho: %d FPS | p95: %d ms"%[roundi(measured.fps),roundi(measured.p95_ms)],13)
func upgrades(data):
 var v:=page("Subiu de nível",game.coop.close_menu if game.coop.active else Callable())
 var h:=row(v);h.size_flags_vertical=Control.SIZE_EXPAND_FILL
 var choices:=scroll(h,"ChoiceScroll");choices.custom_minimum_size.x=318;choices.name="UpgradeList"
 for offer in data.get("offers",[]):
  var b:=button(choices,"",func():game.choose_upgrade(offer.id));b.custom_minimum_size.y=106
  var inset:=MarginContainer.new();inset.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
  for edge in ["left","right","top","bottom"]:inset.add_theme_constant_override("margin_"+edge,8)
  inset.mouse_filter=Control.MOUSE_FILTER_IGNORE;b.add_child(inset);var r:=row(inset);r.mouse_filter=Control.MOUSE_FILTER_IGNORE;icon(r,offer.get("icon",""));var c:=column(r);c.mouse_filter=Control.MOUSE_FILTER_IGNORE
  text(c,offer.name,15);text(c,offer.get("detail","Novo"),12);text(c,offer.description,13)
  inset.minimum_size_changed.connect(func():b.custom_minimum_size.y=maxf(106,inset.get_combined_minimum_size().y))
 var build:=scroll(h,"BuildScroll");build.custom_minimum_size.x=205;build.name="BuildPanel";build_items(build)
func permanent():
 var v:=page("Aprimoramentos | %d ouro"%game.profile.data.gold,game.close_skill_tree)
 var h:=row(v);h.size_flags_vertical=Control.SIZE_EXPAND_FILL
 var list:=scroll(h,"PermanentScroll");list.custom_minimum_size.x=300
 var grid:=GridContainer.new();grid.columns=2;grid.size_flags_horizontal=Control.SIZE_EXPAND_FILL;grid.add_theme_constant_override("h_separation",6);grid.add_theme_constant_override("v_separation",6);list.add_child(grid)
 for d in game.skills.definitions:
  var rank:int=game.skills.rank(d.id);var id:String=d.id
  var b:=button(grid,"",func():ui.selected_skill=id;ui.render("tree"));b.custom_minimum_size=Vector2(140,98)
  if id==ui.selected_skill:b.add_theme_stylebox_override("normal",ui._style(Color("354e69"),Color("fff0a4"),2))
  var c:=column(b);c.mouse_filter=Control.MOUSE_FILTER_IGNORE;c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);c.offset_left=6;c.offset_right=-6;c.offset_top=5
  text(c,d.title,13);icon(c,d.icon);text(c,("Máximo" if rank==d.max_rank() else "%d / %d"%[rank,d.max_rank()]),12)
 if not game.skills.by_id.has(ui.selected_skill):ui.selected_skill="damage"
 var d=game.skills.by_id[ui.selected_skill];var n:int=game.skills.rank(d.id);var info:Dictionary=game.skills.state(d.id)
 var details:=scroll(h,"PermanentDetailsScroll");details.custom_minimum_size.x=230
 var head:=row(details);icon(head,d.icon);text(head,d.title,17)
 text(details,d.description,13);text(details,"Atual: "+game.skills.effect(d.id,n),13)
 if n<d.max_rank():text(details,"Após: "+game.skills.effect(d.id,n+1),13)
 text(details,"Preço: %d ouro"%info.cost if n<d.max_rank() else "Nível máximo",14)
 var buy:=button(details,"Comprar",func():
  if Time.get_ticks_msec()-last_purchase<350:return
  last_purchase=Time.get_ticks_msec();game.skills.purchase(d.id,n);ui.render("tree"))
 buy.name="BuyPermanent";buy.disabled=not info.can_buy
 if d.id=="challenge":
  text(details,"Aumenta a dificuldade. Ativos: %d"%game.profile.data.challenge_active,13)
  var r:=row(details)
  button(r,"-",func():game.skills.set_challenge(maxi(0,game.profile.data.challenge_active-1));ui.render("tree"))
  button(r,"+",func():game.skills.set_challenge(mini(n,game.profile.data.challenge_active+1));ui.render("tree"))
 var refund:=button(details,"Reembolsar: %d ouro"%game.skills.refund_total(),refund_confirm);refund.disabled=game.skills.refund_total()==0
func refund_confirm():
 var revision:int=game.profile.data.upgrade_revision;var dialog:=ConfirmationDialog.new();dialog.title="Reembolsar";dialog.dialog_text="Devolver exatamente %d de ouro e remover os níveis comprados?"%game.skills.refund_total();dialog.ok_button_text="Reembolsar";dialog.cancel_button_text="Cancelar";dialog.theme=ui.ui_theme;ui.menu.add_child(dialog)
 for b in [dialog.get_ok_button(),dialog.get_cancel_button()]:b.custom_minimum_size=Vector2(120,44)
 dialog.confirmed.connect(func():game.skills.refund(revision);dialog.queue_free();ui.render("tree"));dialog.canceled.connect(dialog.queue_free);dialog.popup_centered(Vector2i(420,180))
func collection():
 var v:=page("Coleção",game.show_title);var h:=row(v);h.size_flags_vertical=Control.SIZE_EXPAND_FILL
 var entries:Array=[]
 for kind in ["weapon","passive"]:
  var source:Dictionary=game.weapon_system.weapon_data if kind=="weapon" else game.weapon_system.passive_data
  for id in source:
   var d=source[id];entries.append({"key":kind+":"+id,"name":d.display_name,"icon":d.icon,"description":d.description if kind=="weapon" else d.level_descriptions[0]})
 for d in game.consumables.config.items:entries.append({"key":"consumable:"+d.id,"name":d.name,"icon":GameIcons.path("consumable:"+d.id),"description":d.description})
 var list:=scroll(h,"CollectionScroll");list.custom_minimum_size.x=300;var grid:=GridContainer.new();grid.columns=4;grid.add_theme_constant_override("h_separation",5);grid.add_theme_constant_override("v_separation",5);list.add_child(grid)
 for i in entries.size():
  var entry:Dictionary=entries[i];var known:bool=game.profile.data.get("discoveries",{}).get(entry.key,false)
  var b:=button(grid,"?" if not known else "",func():collection_selected=i;ui.render("collection"));b.custom_minimum_size=Vector2(65,65)
  if known:
   var image:=TextureRect.new();image.texture=load(entry.icon);image.position=Vector2(16,16);image.size=Vector2(32,32);image.mouse_filter=Control.MOUSE_FILTER_IGNORE;b.add_child(image)
 var detail:=scroll(h,"CollectionDetails");detail.custom_minimum_size.x=235
 var e:Dictionary=entries[clampi(collection_selected,0,entries.size()-1)]
 if game.profile.data.get("discoveries",{}).get(e.key,false):icon(detail,e.icon);text(detail,e.name,18);text(detail,e.description,14)
 else:text(detail,"Não descoberto",18);text(detail,"Encontre este item durante uma partida.",14)
func online(which:String):
 var session=game.coop;var v:=page("Sala "+session.connection.code if which=="lobby" else "Cooperativo online",session.leave)
 button(v.get_child(0),"Atualizações",func():ui.render("updates",{"return":which}))
 if which=="lobby":
  var list:=scroll(v)
  var all_ready:bool=not session.connection.players.is_empty();var mine:bool=false
  for member in session.connection.players:
   text(list,member.name+(" (anfitrião)" if member.id==session.connection.host_id else "")+(" | Pronto" if member.ready else " | Aguardando"),14);all_ready=all_ready and member.ready
   if member.id==session.connection.peer_id:mine=member.ready
  var r:=row(list);var maps:=OptionButton.new();maps.custom_minimum_size=Vector2(210,44)
  for title in ["Pátio","Biblioteca","Campos"]:maps.add_item(title)
  maps.select(["courtyard","library","fields"].find(session.lobby_map));maps.disabled=not session.hosting;maps.item_selected.connect(func(i):session.connection.send_message({"type":"map","map":["courtyard","library","fields"][i]}));r.add_child(maps)
  var challenge:=OptionButton.new();challenge.custom_minimum_size=Vector2(190,44);var cap:int=game.skills.rank("challenge") if session.hosting else session.lobby_challenge
  for i in cap+1:challenge.add_item("Desafio %d"%i)
  challenge.select(session.lobby_challenge);challenge.disabled=not session.hosting;challenge.item_selected.connect(func(i):session.connection.send_message({"type":"challenge","value":i}));r.add_child(challenge)
  for option in [maps,challenge]:option.get_popup().add_theme_constant_override("v_separation",18)
  var actions:=row(v);button(actions,"Cancelar prontidão" if mine else "Estou pronto",func():session.connection.send_message({"type":"ready","ready":not mine}))
  if session.hosting:button(actions,"Iniciar partida",func():session.connection.send_message({"type":"start"})).disabled=not all_ready
  button(actions,"Copiar código",func():DisplayServer.clipboard_set(session.connection.code))
 else:
  text(v,"Até quatro pessoas. Compatível com PC 0.20.0.",13)
  var list:=scroll(v);var r:=row(list);var left:=column(r);var right:=column(r)
  var name_input:=LineEdit.new();name_input.name="MobileName";name_input.max_length=8;name_input.text=session.local_name.left(8);name_input.placeholder_text="Até 8 caracteres";name_input.custom_minimum_size=Vector2(220,44);name_input.virtual_keyboard_enabled=true;left.add_child(name_input);name_input.text_changed.connect(func(value):session.local_name=value.left(8))
  var code:=LineEdit.new();code.name="MobileRoomCode";code.max_length=6;code.placeholder_text="ABC123";code.custom_minimum_size=Vector2(220,44);code.virtual_keyboard_enabled=true;right.add_child(code)
  code.text_changed.connect(func(value):var caret:int=code.caret_column;code.text=value.to_upper();code.caret_column=caret)
  var name_header:=row(left);left.move_child(name_header,0);text(name_header,"Seu nome");button(name_header,"Teclado",func():game.open_mobile_keyboard(name_input,"Seu nome"))
  var code_header:=row(right);right.move_child(code_header,0);text(code_header,"Código da sala");button(code_header,"Teclado",func():game.open_mobile_keyboard(code,"Código da sala"))
  var actions:=row(list);button(actions,"Criar sala",func():DisplayServer.virtual_keyboard_hide();session.connect_room(true,name_input.text.left(8)))
  button(actions,"Entrar por código",func():DisplayServer.virtual_keyboard_hide();session.connect_room(false,name_input.text.left(8),code.text))
  text(list,session.message,14)
func result(data):
 var v:=page("Vitória" if data.get("won",false) else "Fim da partida",game.show_title);var list:=scroll(v)
 text(list,"Tempo: %s | Nível: %d | Abates: %d"%[ui._clock(data.get("elapsed",0)),data.get("level",1),data.get("kills",0)],16)
 text(list,"Ouro recebido: %d\nSaldo total: %d\nMedalhas: %d"%[data.get("gold",0),data.get("total_gold",0),data.get("earned",0)],17)
 var r:=row(v);button(r,"Tentar novamente",game.retry);button(r,"Base",game.enter_hub)
func revive():
 var v:=page("Reviver");text(v,"Retorne com 40% da vida e 2 segundos de proteção. Uma utilização por partida. Sua build será preservada.",17)
 button(v,"Usar retorno",game.use_solo_revive);button(v,"Encerrar partida",func():game.finish_run(false))
func endless():
 var v:=page("Campanha vencida");text(v,"Continue com sua build, ouro e tempo. Online: todos precisam concordar em até 30 segundos.",17)
 button(v,"Continuar no infinito",func():game.campaign.vote(true));button(v,"Encerrar com vitória",func():game.campaign.vote(false))
func legal(which):
 var v:=page("Privacidade" if which=="mobile_privacy" else "Termos de serviço",game.show_title);var list:=scroll(v)
 text(list,"O solo funciona offline, sem conta, anúncios ou análise de uso. Progresso e opções ficam no armazenamento privado do aplicativo Android. Desinstalar pode remover esses dados. Atualizações com o mesmo pacote e assinatura preservam o progresso.\n\nOnline: o serviço de salas recebe nome, código, aprimoramentos e mensagens da partida. A hospedagem pode manter registros técnicos da conexão. O link Socialy abre o Instagram, sujeito às regras desse serviço." if which=="mobile_privacy" else "Versão de teste. Arte, sistemas e balanceamento podem mudar. O cooperativo depende do relay e da conexão. A saída do anfitrião encerra a sessão, sem migração de host ou reconexão automática. Ao colocar o app em segundo plano, a sessão online é encerrada neste aparelho.\n\nSem compras, cadastro ou assinatura. Esta build não é compatível automaticamente com versões futuras de PC. Créditos e licenças acompanham o projeto.",14)
