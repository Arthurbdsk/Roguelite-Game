class_name EnemyCatalog
extends RefCounted
# Descriptions contain no copied balance numbers. Attributes come from spawn data.
const TEXT:Dictionary={
 "ghoul":"Persegue o jogador e causa dano ao encostar.",
 "hound":"Avança rapidamente e ataca por contato. Reconheça as asas e mantenha distância.",
 "guard":"Prepara uma investida na direção marcada. Desvie para o lado antes do avanço.",
 "skeleton_sword":"Prepara um golpe curto de espada. Ataque durante a recuperação.",
 "skeleton_archer":"Dispara flechas em linha reta. O cenário pode bloquear o disparo.",
 "necromancer":"Invoca esqueletos e ataca de longe. Elimine-o antes que reúna muitos aliados.",
 "beast":"Orc montado que prepara um ataque próximo. A marca indica a direção do golpe.",
 "plague":"Arremessa frascos de veneno no local marcado. Saia da área antes do impacto.",
 "shadow":"Desaparece e reaparece na área marcada para uma emboscada. Invisibilidade não é morte.",
 "devourer":"Come moedas e cristais. Cresce e ganha vida e dano; sem alimento, persegue e ataca.",
 "slime_large":"Divide-se em pequenos slimes ao morrer. Seus descendentes têm atributos próprios.",
 "slime_small":"Pequeno slime gerado por divisão. Ataca por contato e não herda a vida do pai.",
 "event_blue":"Slime azul de evento que gera pequenos ao morrer. Cada divisão mantém uma base própria.",
 "event_small":"Pequeno slime azul do evento. Persegue o jogador e ataca por contato.",
 "slime_king":"Slime coroado de evento. Sua divisão pode gerar vários descendentes.",
 "siege_archer":"Arqueiro de evento com mais vida. Dispara de longe e desaparece ao terminar o evento.",
 "orc_armored":"Orc com armadura. Recebe menos dano, mas mantém o comportamento do Orc comum.",
 "orc_elite":"Orc de elite com armadura reforçada. Sua redução de dano é maior.",
 "skeleton_armored":"Esqueleto com armadura e escudo. Prepara ataques de espada e reduz o dano recebido.",
 "executioner":"Chega aos cinco minutos. Alterna golpe de execução e investida; fica mais agressivo ao perder vida.",
 "demon":"Alterna investidas, magias e invocações. Ao cair, transforma-se antes da morte definitiva.",
 "guardian":"Cria ataques de área e barreiras. Observe os avisos e preserve uma rota de saída.",
 "horror":"Combina projéteis, invocações e avanços. Sua derrota inicial libera a forma verdadeira."
}
static func ids(game)->Array:
 var result:Array=[]
 for id in game.enemy_data:
  if id not in ["boss","ice_crystal","channel_totem"]:result.append(id)
 result.sort_custom(func(a,b):return game.enemy_data[a].title.naturalnocasecmp_to(game.enemy_data[b].title)<0)
 return result
static func category(id:String)->String:
 if id in ["executioner","demon","guardian","horror","slime_king"]:return "Chefes"
 if id in ["necromancer","beast","plague","shadow","devourer","siege_archer","event_blue","event_small"]:return "Especiais"
 return "Comuns"
static func phases(id:String)->Array:
 if id=="executioner":return ["Normal","Agressivo"]
 if id=="demon":return ["Forma 1: início","Forma 1: intermediária","Forma 1: crítica","Forma 2"]
 if id=="horror":return ["Horror","Forma verdadeira"]
 return ["Inicial"]
static func number(value:float)->String:return str(roundi(value))
static func entry(game,id:String,phase:int=0)->Dictionary:
 var data:EnemyData=game.enemy_spawn_stats(id,game.coop.rules.scaling(1))
 var b=game.boss_balance;var c=game.campaign.config
 var result:Dictionary={"id":id,"name":data.title,"category":category(id),"description":TEXT.get(id,"Persegue e ataca o jogador."),"hp":data.health,"speed":data.speed,"reduction":data.damage_resistance,"fixed_defense":0,"attacks":[],"abilities":[],"phases":phases(id),"control":"Pode ser congelado. Após o efeito, pode resistir temporariamente ao mesmo controle."}
 if game.variant_data.has(id):result.abilities.append("Variante de "+game.enemy_data[game.variant_data[id].base].title+".")
 var damage_scale:float=1.0
 if id in ["executioner","demon","guardian","horror"]:result.control="Não congela. Pode receber lentidão, conforme o efeito."
 if id=="executioner":
  if phase==1:result.speed*=1.06
  result.attacks=["Execução: "+number(b.executioner_swing_damage),"Investida: "+number(b.executioner_charge_damage)]
  result.abilities=["Alterna execução e investida.","Na fase agressiva, move-se mais rápido e reduz o intervalo entre ataques."]
 elif id=="demon":
  if phase==3:
   result.hp=(result.hp-30*game.balance.enemy_health_multiplier)*b.second_health_multiplier+30*game.balance.enemy_health_multiplier
   damage_scale=b.second_damage_multiplier
  result.attacks=["Investida: "+number(b.demon_charge_damage*damage_scale),"Bola de fogo: "+number(b.fire_damage*damage_scale)]
  if phase>0:result.attacks.append("Raio: "+number(b.lightning_damage*damage_scale));result.attacks.append("Anel: "+number(b.lightning_damage*damage_scale))
  result.abilities=["Invoca aliados e dispara fogo.","Nas fases seguintes, adiciona raios, gelo e anéis de projéteis.","A transformação não conta como outra eliminação."]
 elif id in ["guardian","horror"]:
  if id=="horror" and phase==1:result.hp=(result.hp-30*game.balance.enemy_health_multiplier)*float(c.true_health_ratio)+30*game.balance.enemy_health_multiplier
  if id=="guardian":result.attacks=["Ataques de área: "+number(c.guardian_damage)]
  else:result.attacks=["Avanço: "+number(b.demon_charge_damage*b.second_damage_multiplier*c.horror_damage_ratio_to_demon_phase2),"Fogo: "+number(b.fire_damage*b.second_damage_multiplier*c.horror_damage_ratio_to_demon_phase2),"Raio: "+number(b.lightning_damage*b.second_damage_multiplier*c.horror_damage_ratio_to_demon_phase2)]
  result.abilities=["Ataques de área e barreiras.","Forma verdadeira combina padrões e mantém os avisos de combate." if id=="horror" and phase==1 else "Observe as marcações antes de avançar."]
 elif id=="plague":result.attacks=["Veneno por segundo: "+number(game.specials.balance.poison_damage)];result.abilities=["Frasco cria uma poça venenosa no destino marcado."]
 else:
  result.attacks=[("Flecha: " if id in ["skeleton_archer","siege_archer"] else "Magia: " if id=="necromancer" else "Emboscada: " if id=="shadow" else "Ataque: ")+number(data.damage)]
 if id=="devourer":result.abilities.append("Valores iniciais. Cada alimento aumenta vida, dano e tamanho; os valores crescidos variam.")
 if id in ["slime_large","slime_king","event_blue"]:result.abilities.append("Divide-se em descendentes de outra espécie. Consulte a ficha de cada tamanho.")
 return result
static func preview(game,id:String,phase:int=0)->Dictionary:
 var data:EnemyData=game.enemy_data[id];var kind:String="orc" if id=="ghoul" else data.visual_family
 if not kind.is_empty() and TinyCharacters.available(kind):
  var d:Dictionary=TinyCharacters.data(kind);return {"texture":TinyCharacters.texture(kind),"frames":d.frames,"cell":Vector2(d.cell[0],d.cell[1]),"start":d.clips.idle.start,"count":d.clips.idle.count,"height":d.get("visible_height",20),"phase":id=="executioner" and phase==1}
 var path:String=data.texture;var frames:int=data.frames
 if id=="demon":path="res://assets/v08/demon_"+("2" if phase==3 else "1")+".png";frames=32
 if id=="horror":path="res://assets/v10/"+("true_form" if phase==1 else "horror")+".png";frames=32
 var texture:Texture2D=load(path)
 return {"texture":texture,"frames":frames,"cell":Vector2(texture.get_width()/frames,texture.get_height()),"start":0,"count":mini(4,frames),"height":texture.get_height()*.7,"phase":false}
