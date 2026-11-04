"""Editable catalog and direct import of user-provided pixel icons, in supplied order."""
from pathlib import Path
import json, shutil
rows=[
('damage','Dano',5,.05,'Dano de todas as armas.', 'e4d57b9b-a3ac-43fb-adc8-2d14f7752594'),
('armor','Armadura',5,.03,'Aplica o percentual após a defesa fixa. Dano final nunca cai abaixo de 20% do dano original (redução total máxima de 80%).','b9ec4fbd-3f91-4545-828d-26edb113f764'),
('health','Vida máxima',5,.05,'Aumenta a vida máxima inicial.','b7273425-b56c-46af-b816-1e5271a39f3a'),
('regen','Regeneração',5,.1,'Recupera vida por segundo. Não funciona enquanto caído.','068f5aa8-d247-4e55-807e-dc30d6409b20'),
('cooldown','Recarga',5,.02,'Reduz o intervalo. Intervalo mínimo global: 0,15 s.','4d2dea71-0709-4ee9-a37b-8f1b157df65c'),
('area','Área',5,.05,'Aumenta a área de Espada, Lodo, Água Benta, Bombas e Onda de Gelo. Raio recebe a raiz quadrada do bônus.','f8b16677-6d32-45f1-ae78-121132a5480d'),
('projectile_speed','Velocidade dos projéteis',5,.05,'Acelera Arco, Machado, Bumerangue e o voo dos frascos e bombas. Preserva destinos e perfuração.','0ffc9022-3f65-4bb6-947d-dec7a2c1ca26'),
('duration','Duração',5,.05,'Aumenta a duração de Lodo, Água Benta e lentidão da Onda de Gelo. Não amplia controle de chefes.','98bbef6c-d122-4fec-806e-1a3c0e6b9b32'),
('amount','Quantidade',1,1,'+1 por ativação no Arco, Machado, Bumerangue, Bombas e Água Benta.','ab229ac5-9f16-4ca4-97d3-6711fabc25cb'),
('move','Movimento',5,.03,'Aumenta a velocidade de movimento.','30fa3189-b047-43eb-a7ec-1e3b5227abae'),
('pickup','Coleta',5,.1,'Aumenta o raio de atração de ouro e experiência.','c8306378-13ca-4ce3-af0b-19eb79e4337e'),
('luck','Sorte',3,.1,'Chance de quarta opção. Um sorteio por seleção, respeitando os limites da build.','193a77db-25f1-49fc-8aa7-66a1754b54ca'),
('experience','Experiência',5,.02,'Bônus somado ao da Coroa, com frações preservadas.','2fc27f7d-7216-4ad2-b725-4af8a6361f19'),
('gold','Ouro',5,.05,'Bônus no ouro coletado. Frações acumulam. Não bonifica reembolsos.','276ae843-9ee8-48b4-b6cc-3a7cee0716d0'),
('challenge','Desafio',5,.05,'Por nível ativo: +5% de vida, dano e quantidade dos inimigos. Não altera velocidade.','cad9cfa0-cc7b-45f8-b99e-e2f279102e9e'),
('revive','Reviver',1,1,'Um retorno por partida: 40% da vida e 2 s de proteção. Reanimação por aliado não consome.','7aac57c8-24ac-4d6c-95bb-7e6a8650d2df')]
out=[];icons=Path('assets/permanent');icons.mkdir(exist_ok=True)
for id,name,cap,step,desc,source in rows:
 target=icons/(id+'.png')
 src=Path.home()/'AppData/Local/Temp'/('codex-clipboard-'+source+'.png')
 if src.exists():shutil.copy2(src,target)
 costs=[10,25,50,90,150][:cap]
 if id=='luck':costs=[25,60,120]
 if id=='amount':costs=[250]
 if id=='revive':costs=[300]
 out.append(dict(id=id,name=name,cap=cap,step=step,description=desc,costs=costs,icon='res://'+target.as_posix()))
Path('data/permanent.json').write_text(json.dumps(out,ensure_ascii=False,indent=2),encoding='utf-8')
