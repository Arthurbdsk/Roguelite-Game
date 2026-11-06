extends PanelContainer
var lab
var tabs:TabContainer
var status_label:Label
var boss_label:Label
var build_label:Label
var weapon_slots:Array=[]
var passive_slots:Array=[]
var level_box:SpinBox
var attack_box:OptionButton
var host_controls:Array=[]
var attack_signature:String=""
var clock:float=0
var performance_label:Label
var survival_label:Label
var permanent:CheckBox
func setup(controller):
 lab=controller;add_theme_stylebox_override("panel",lab.game.ui._style(GameUI.INK,GameUI.LINE));position=Vector2(8,48);size=Vector2(624,302);rebuild()
func button(parent:Node,text:String,action:Callable,host_only:bool=false)->Button:
 var b:=Button.new();b.text=text;b.add_theme_font_size_override("font_size",11);b.pressed.connect(action);parent.add_child(b)
 if host_only:host_controls.append(b);b.disabled=not lab.is_host()
 return b
func label(parent:Node,text:String)->Label:
 var l:=Label.new();l.text=text;l.add_theme_font_size_override("font_size",10);l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;l.size_flags_horizontal=Control.SIZE_EXPAND_FILL;parent.add_child(l);return l
func row(parent:Node)->HBoxContainer:
 var r:=HBoxContainer.new();r.add_theme_constant_override("separation",5);parent.add_child(r);return r
func pick(parent:Node,entries:Dictionary,current:String)->OptionButton:
 var p:=OptionButton.new();p.add_theme_font_size_override("font_size",10);p.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 for id in entries:
  p.add_item(entries[id]);p.set_item_metadata(p.item_count-1,id)
  if id==current:p.selected=p.item_count-1
 parent.add_child(p);return p
func spin(parent:Node,value:float,low:float,high:float,step:float=1)->SpinBox:
 var s:=SpinBox.new();s.min_value=low;s.max_value=high;s.step=step;s.value=value;s.custom_minimum_size.x=65;s.add_theme_font_size_override("font_size",10);parent.add_child(s);return s
func tab(title:String)->VBoxContainer:
 var scroll:=ScrollContainer.new();scroll.name=title;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;tabs.add_child(scroll)
 var box:=VBoxContainer.new();box.add_theme_constant_override("separation",6);box.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(box);return box
func rebuild():
 var selected:int=tabs.current_tab if is_instance_valid(tabs) else 0
 for child in get_children():remove_child(child);child.queue_free()
 weapon_slots.clear();passive_slots.clear();host_controls.clear();attack_signature=""
 var base:=VBoxContainer.new();base.add_theme_constant_override("separation",4);add_child(base)
 var head:=row(base);label(head,"MODO DEV | F8: abrir/fechar")
 button(head,"Fechar painel",func():hide());button(head,"Encerrar teste",lab.end_test)
 tabs=TabContainer.new();tabs.size_flags_vertical=Control.SIZE_EXPAND_FILL;base.add_child(tabs)
 var encounter:=tab("Encontro");var names:Dictionary={}
 for id in lab.ENCOUNTERS:names[id]=lab.ENCOUNTERS[id][0]
 var selection:=pick(encounter,names,lab.encounter);selection.item_selected.connect(func(i):lab.encounter=selection.get_item_metadata(i))
 host_controls.append(selection);selection.disabled=not lab.is_host()
 var r:=row(encounter);label(r,"Mapa")
 var maps:=pick(r,{"courtyard":"Pátio","library":"Biblioteca","fields":"Campos"},lab.map_id);maps.item_selected.connect(func(i):lab.map_id=maps.get_item_metadata(i));host_controls.append(maps)
 label(r,"Escala")
 var count:=spin(r,lab.participants,1,4);count.value_changed.connect(func(value):lab.participants=int(value);lab.status="Escala será aplicada ao iniciar/reiniciar.");host_controls.append(count)
 var options:=row(encounter);var waves:=CheckBox.new();waves.text="Geração normal";waves.add_theme_font_size_override("font_size",10);waves.button_pressed=lab.hordes;waves.toggled.connect(func(value):lab.hordes=value);options.add_child(waves);host_controls.append(waves)
 label(options,"Tempo")
 var speed:=pick(options,{"0.5":"0,5x","1":"1x","2":"2x"},"0.5" if Engine.time_scale==.5 else "2" if Engine.time_scale==2 else "1");speed.item_selected.connect(func(i):lab.set_time(float(speed.get_item_metadata(i))));host_controls.append(speed)
 var actions:=row(encounter);button(actions,"Iniciar encontro",func():if read_build():lab.start_encounter(),true);button(actions,"Reiniciar",func():lab.start_encounter(),true)
 button(actions,"Sala DEV",lab.open_dev_room)
 label(encounter,"Escala simulada usa os mesmos multiplicadores da partida. Não substitui conexões reais. Mapa, geração e escala passam a valer ao iniciar ou reiniciar.")
 label(encounter,"Na sala DEV: configure sua build, marque pronto e inicie a sala. Depois o host escolhe o encontro. Apenas builds de desenvolvimento podem entrar.")
 var player:=tab("Jogador");var pr:=row(player);label(pr,"Preset")
 var preset:=pick(pr,{"5":"5 minutos","10":"10 minutos","15":"15 minutos","20":"20 minutos"},lab.ENCOUNTERS[lab.encounter][2])
 button(pr,"Carregar preset",func():lab.load_preset(preset.get_item_metadata(preset.selected));lab.apply_build();rebuild())
 label(pr,"Nível");level_box=spin(pr,lab.build.level,1,999)
 var flags:=row(player);permanent=CheckBox.new();permanent.text="Aprimoramentos do perfil";permanent.add_theme_font_size_override("font_size",10);permanent.button_pressed=lab.build.permanent;flags.add_child(permanent)
 var inv:=CheckBox.new();inv.text="Invulnerável";inv.add_theme_font_size_override("font_size",10);inv.button_pressed=lab.build.invulnerable;inv.toggled.connect(func(value):lab.set_player_flag("invulnerable",value));flags.add_child(inv)
 var auto:=CheckBox.new();auto.text="Ataques automáticos";auto.add_theme_font_size_override("font_size",10);auto.button_pressed=lab.build.attacks;auto.toggled.connect(func(value):lab.set_player_flag("attacks",value));flags.add_child(auto)
 slots(player,"Armas: seis espaços",lab.game.weapon_system.weapon_data,lab.build.weapons,6,weapon_slots)
 slots(player,"Passivas: quatro espaços",lab.game.weapon_system.passive_data,lab.build.passives,4,passive_slots)
 var tools:=row(player);button(tools,"Aplicar build",func():if read_build():lab.apply_build());button(tools,"Curar completamente",lab.heal)
 label(player,"Atributos da build aplicada, incluindo os bônus ativos:")
 build_label=label(player,lab.game.weapon_system.build_stats())
 var boss:=tab("Chefe");boss_label=label(boss,lab.boss_info())
 attack_box=pick(boss,{},"")
 var commands:=row(boss);button(commands,"Executar ataque",func():if attack_box.item_count>0:lab.force_attack(attack_box.get_item_metadata(attack_box.selected)),true)
 button(commands,"Repetir somente este",func():if attack_box.item_count>0:lab.force_attack(attack_box.get_item_metadata(attack_box.selected),true),true)
 button(commands,"Sequência normal",lab.normal_sequence,true)
 var combo:=row(boss)
 var combinations:=pick(combo,{"spiral":"Espiral + Selos","rings":"Anéis + Orbes","spears":"Lanças + Cristais","beams":"Feixes + Totens"},"spiral")
 button(combo,"Testar combinação",func():
  var first:String=combinations.get_item_metadata(combinations.selected)
  for pair in lab.game.late_arena.patterns.config.combination_pairs:
   if pair[0]==first:lab.force_combination(pair[0],pair[1]),true)
 var values:=row(boss);var frozen:=CheckBox.new();frozen.text="Congelar chefe";frozen.add_theme_font_size_override("font_size",10);frozen.button_pressed=lab.frozen;frozen.toggled.connect(lab.freeze);values.add_child(frozen);host_controls.append(frozen)
 label(values,"Vida %");var percent:=spin(values,100,1,100,.1);button(values,"Definir vida",func():lab.health_percent(percent.value),true);button(values,"Próxima fase",lab.next_phase,true)
 label(boss,"Ataques aguardam os limites reais de efeitos e a recuperação. Congelar para o chefe, mas mantém projéteis e áreas já lançados. Vida 0: use Próxima fase ou cause dano na arena.")
 var survival:=tab("Contínuo")
 var actions13:=row(survival);button(actions13,"Iniciar contínuo",func():lab.start_survival(false),true);button(actions13,"Iniciar infinito",func():lab.start_survival(true),true)
 var timing:=row(survival);label(timing,"Tempo em segundos")
 var seconds:=spin(timing,lab.game.elapsed,0,864000,.1);button(timing,"Aplicar tempo",func():lab.set_survival_time(seconds.value),true)
 var stage_row:=row(survival);label(stage_row,"Estágio")
 var stage:=spin(stage_row,lab.game.horde_progress.stage(),0,7200);button(stage_row,"Aplicar estágio",func():lab.set_survival_time(stage.value*120),true)
 var events13:=row(survival);button(events13,"Cerco",func():lab.force_event("siege"),true);button(events13,"Slime Rei",func():lab.force_event("king"),true);button(events13,"Gerar baú",lab.force_chest,true)
 var debug13:=row(survival);var colliders:=CheckBox.new();colliders.text="Mostrar colisores";colliders.button_pressed=lab.show_colliders;colliders.toggled.connect(func(value):lab.show_colliders=value);debug13.add_child(colliders)
 button(debug13,"Limpar eventos",func():
  if lab.is_host():lab.game.special_events.stop();lab.game.chests.reset(),true)
 survival_label=label(survival,lab.survival_info())
 var consumable_tab:=tab("Consumíveis")
 for d in lab.game.consumables.config.items:
  button(consumable_tab,"Gerar "+str(d.name),func():lab.force_consumable(str(d.id)),true)
 var heal_row:=row(consumable_tab)
 button(heal_row,"Vida cheia",func():
  if lab.is_host():lab.game.player.hp=lab.game.player.max_hp,true)
 button(heal_row,"Vida 25%",func():
  if lab.is_host():lab.game.player.hp=lab.game.player.max_hp*.25,true)
 button(consumable_tab,"Gerar 500 cristais",func():
  if lab.is_host():
   for i in 500:lab.game.drop_xp(lab.game.player.position+Vector2.from_angle(i*2.39996)*sqrt(i+1)*8,.125),true)
 button(consumable_tab,"Limpar consumíveis",func():
  if lab.is_host():lab.game.consumables.items.clear(),true)
 button(consumable_tab,"Slimes e necromante",func():
  if lab.is_host():
   for i in 6:
    var at:Vector2=lab.game.free_enemy_position(lab.game.player.position+Vector2.from_angle(i*TAU/6)*95,18)
    if at!=Vector2.INF:lab.game.spawn_enemy("slime_large" if i%2==0 else "necromancer",at),true)
 var perf_tab:=tab("Desempenho")
 var measure:=CheckBox.new();measure.text="Medir custos da simulação";measure.button_pressed=lab.game.perf_enabled;measure.toggled.connect(func(value):lab.game.perf_enabled=value);perf_tab.add_child(measure)
 performance_label=label(perf_tab,lab.performance_info())
 status_label=label(base,lab.status);status_label.custom_minimum_size.y=14
 tabs.current_tab=clampi(selected,0,tabs.get_tab_count()-1);refresh()
func slots(parent:Node,title:String,definitions:Dictionary,equipped:Dictionary,count:int,records:Array):
 label(parent,title)
 var grid:=GridContainer.new();grid.columns=2;grid.add_theme_constant_override("h_separation",8);parent.add_child(grid)
 var ids:Array=equipped.keys()
 for i in count:
  var r:=row(grid);var options:Dictionary={"":"Vazio"}
  for id in definitions:options[id]=definitions[id].display_name
  var current:String=ids[i] if i<ids.size() else ""
  var item:=pick(r,options,current);item.custom_minimum_size.x=205
  var rank:=spin(r,equipped.get(current,1),1,8);records.append({"item":item,"rank":rank})
func read_build()->bool:
 var result:Dictionary=lab.build.duplicate(true);result.level=int(level_box.value);result.permanent=permanent.button_pressed
 for category in ["weapons","passives"]:
  result[category]={}
  for record in weapon_slots if category=="weapons" else passive_slots:
   var id:String=record.item.get_item_metadata(record.item.selected)
   if id.is_empty():continue
   if result[category].has(id):lab.status="Item repetido: escolha um item por espaço.";return false
   result[category][id]=int(record.rank.value)
 lab.build=result;return true
func refresh():
 if not is_instance_valid(status_label):return
 if is_instance_valid(performance_label):performance_label.text=lab.performance_info()
 if is_instance_valid(survival_label):survival_label.text=lab.survival_info()
 status_label.text="Tempo: %.1fx | "%Engine.time_scale+lab.status;boss_label.text=lab.boss_info();build_label.text=lab.game.weapon_system.build_stats()
 var signature:String=str(lab.attacks())
 if signature!=attack_signature:
  attack_signature=signature;attack_box.clear()
  var names:Dictionary={"spiral":"Espiral Dupla","rings":"Anéis com Abertura","spears":"Chuva de Lanças","orbs":"Orbes de Cerco","crystals":"Cristais de Gelo","beams":"Feixes Giratórios","seals":"Selos de Perseguição","totems":"Totens de Canalização","execute":"Golpe","charge":"Investida","fire":"Bolas de fogo","summon":"Invocar","lightning":"Raios","ice":"Parede de gelo","ring":"Anel","cross":"Feixes cruzados","feathers":"Penas","light_ring":"Anel de luz","columns":"Colunas","dash":"Dash","ice_sectors":"Lanças de gelo","light_bands":"Faixas de luz","moving_ring":"Ondas com abertura móvel"}
  for id in lab.attacks():attack_box.add_item(names.get(id,id));attack_box.set_item_metadata(attack_box.item_count-1,id)
 for control in host_controls:
  if control is Button:control.disabled=not lab.is_host()
  elif control is SpinBox:control.editable=lab.is_host()
func _process(delta:float):
 if not visible:return
 clock-=delta
 if clock<=0:clock=.1;refresh()
