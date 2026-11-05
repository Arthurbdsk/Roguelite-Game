"""Publish measured local results; never labels local sockets as internet validation."""
from pathlib import Path
import json,re
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'test_output';DEST=ROOT/'docs/benchmarks';DEST.mkdir(exist_ok=True)
names={'initial':'Início','four_builds':'Quatro builds, 225 inimigos','boss_necro':'Chefe e necromantes','king_225':'225 descendentes','siege':'Cerco de arqueiros','infinite30':'Infinito em 30:00','stress420':'420 inimigos, 320 flechas, 120 poças'}
def load(tag):
 d=json.loads((OUT/f'benchmark14_{tag}.json').read_text())
 d['background_note']='Hordas 0.12.0 was left open in both runs; four-process tests stopped during measurement.'
 (DEST/f'{tag}.json').write_text(json.dumps(d,indent=2),encoding='utf8');return d
def trio(values):return ' / '.join(f'{values[k]:.2f}' for k in ['median','p95','p99'])
b=load('before_final');a=load('after_final')
section='Tempos em milissegundos. Cada célula mostra mediana / p95 / p99. Menor é melhor.\n\n| Cenário | Frame antes | Frame depois | Simulação antes | Simulação depois |\n|---|---:|---:|---:|---:|\n'
for old,new in zip(b['results'],a['results']):
 section+=f"| {names[new['scenario']]} | {trio(old['frame_ms'])} | {trio(new['frame_ms'])} | {trio(old['simulation_ms'])} | {trio(new['simulation_ms'])} |\n"
section+='\n| Cenário | Inimigos antes/depois | Poças antes/depois | Projéteis antes/depois | Draw calls antes/depois | RSS MB antes/depois | Nós antes/depois |\n|---|---:|---:|---:|---:|---:|---:|\n'
for old,new in zip(b['results'],a['results']):
 k=new['scenario'];x=old['peaks'];y=new['peaks']
 section+=f"| {names[k]} | {x['enemies']:.0f}/{y['enemies']:.0f} | {x['pools']:.0f}/{y['pools']:.0f} | {x['projectiles']:.0f}/{y['projectiles']:.0f} | {x['draw_calls']:.0f}/{y['draw_calls']:.0f} | {b['rss_peak_mb'][k]:.1f}/{a['rss_peak_mb'][k]:.1f} | {x['nodes']:.0f}/{y['nodes']:.0f} |\n"
section+='\nCustos separados na carga de quatro builds. Navegação é parte de IA; os valores não devem ser somados novamente.\n\n| Componente | Antes, ms | Depois, ms |\n|---|---:|---:|\n'
old=b['results'][1]['sections_ms'];new=a['results'][1]['sections_ms']
for key,title in [('enemy_ai_physics','IA, movimento e pares'),('physics_bodies','Corpos físicos, incluídos na linha anterior'),('navigation_planning','Planejamento, incluído em IA'),('weapons_damage','Armas e dano'),('collection','Ouro e índice de comida'),('xp_collection','Coleta de XP'),('enemy_effects','Ataques e efeitos inimigos'),('render_cpu','Desenho CPU do viewport'),('render_gpu','Desenho GPU do viewport')]:
 section+=f'| {title} | {trio(old.get(key,dict(median=0,p95=0,p99=0)))} | {trio(new.get(key,dict(median=0,p95=0,p99=0)))} |\n'
section+='\nA meta de 60 FPS constantes não foi atingida em toda a distribuição de frames: 16,67 ms é o orçamento por frame, e os p95 dos cenários densos ainda o excedem. Houve redução forte dos picos, sem reduzir a população. Draw calls não melhoraram em todos os casos; o gargalo principal medido foi CPU.\n'
if (OUT/'benchmark14_stress_after.json').exists():
 sb=load('stress_before');sa=load('stress_after');x=sb['results'][0];y=sa['results'][0]
 section+='\nCarga extrema adicional, em exportações release com janela e roteiro próprio: 420 corpos físicos, 320 flechas repostas pelo fixture e 120 poças mantidas por duração artificial de teste. Isso não altera os dados do jogo distribuído.\n\n| Carga extrema | Antes | Depois |\n|---|---:|---:|\n'
 for title,key in [('Frame ms','frame_ms'),('Simulação ms','simulation_ms')]:section+=f'| {title} | {trio(x[key])} | {trio(y[key])} |\n'
 section+=f"| RSS MB | {sb['rss_peak_mb']['stress420']:.1f} | {sa['rss_peak_mb']['stress420']:.1f} |\n"
 section+=f"| Inimigos / flechas / poças, picos | {x['peaks']['enemies']:.0f}/{x['peaks']['projectiles']:.0f}/{x['peaks']['pools']:.0f} | {y['peaks']['enemies']:.0f}/{y['peaks']['projectiles']:.0f}/{y['peaks']['pools']:.0f} |\n"
for tag in ['before','after']:
 text=(OUT/f'spawn-cost-{tag}14.log').read_text(encoding='utf8')
 value=json.loads(next(line.split('SPAWN_COST14 ',1)[1] for line in text.splitlines() if line.startswith('SPAWN_COST14 ')))
 (DEST/f'spawn_{tag}.json').write_text(json.dumps(value,indent=2),encoding='utf8')
 if tag=='before':spawn_before=value
 else:spawn_after=value
section+=f"\nPico de criação, medição única de CPU headless com quatro atores e os PCKs release: quinze azuis {spawn_before['fifteen_cpu_ms']:.2f} → {spawn_after['fifteen_cpu_ms']:.2f} ms; 225 pequenos {spawn_before['two_hundred_twenty_five_cpu_ms']:.2f} → {spawn_after['two_hundred_twenty_five_cpu_ms']:.2f} ms. Não é medição de FPS. A nova distribuição espacial procura posições ao redor da morte antes da busca local, mantendo todos os filhos. Ainda existe hitch no nascimento simultâneo; os percentis de combate acima excluem essa preparação.\n"
traffic=[]
for filename in ['network14-1793906465104.json','network14-1793906487113.json']:
 d=json.loads((OUT/filename).read_text());events=[e for e in d['diagnostics'] if e['event']=='close'];host=next(e for e in events if e['host']);clients=[e for e in events if not e['host']]
 traffic.append((host,clients))
 for i,e in enumerate(d['diagnostics']):
  if 'peer' in e:e['peer']='host' if e.get('host') else 'client-'+str(i)
 (DEST/('traffic_before.json' if len(traffic)==1 else 'traffic_after.json')).write_text(json.dumps(d,indent=2),encoding='utf8')
section+='\nRede, mesmo roteiro local de quatro processos, 180 inimigos, 2.000 moedas e 240 cristais. Bytes de aplicação; não incluem cabeçalhos TCP, WebSocket ou TLS. Taxas médias sobre a duração de cada conexão, não pico de banda.\n\n| Medida | Antes | Depois |\n|---|---:|---:|\n'
for title,calc in [('Upload do host, KB/s',lambda h,c:h['metrics']['rx_bytes']/h['age_ms']),('Recebimento médio por cliente, KB/s',lambda h,c:sum(e['metrics']['tx_bytes']/e['age_ms'] for e in c)/len(c)),('Upload total do relay para os três clientes, KB/s',lambda h,c:sum(e['metrics']['tx_bytes']/e['age_ms'] for e in c)),('Maior mensagem do host, bytes',lambda h,c:h['max_payload'])]:
 section+=f'| {title} | {calc(*traffic[0]):.2f} | {calc(*traffic[1]):.2f} |\n'
section+='\nO estado foi reduzido por codificação e compressão, não por deixar de enviar inimigos ou recompensas. Os ensaios de atraso/banda e a sessão longa são separados dessa comparação de tráfego.\n'
path=ROOT/'docs/DESEMPENHO_0_14.md';text=path.read_text(encoding='utf8');start=text.index('## Resultados\n');end=text.index('## Testes e limites',start);path.write_text(text[:start]+'## Resultados\n\n'+section+'\n'+text[end:],encoding='utf8')
print('Measured frame/CPU/entity/memory/traffic tables written. Long-session results must be appended only after completion.')
