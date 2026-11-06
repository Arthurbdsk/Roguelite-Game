# Validação do painel DEV 0.11

`python tools/validate_dev11.py` verifica isolamento de save, seis encontros nos três mapas, 30 ataques, controle do jogador e painel renderizado. `node relay/match-test.mjs --dev` usa quatro processos reais com um relay local para verificar comandos do host, builds individuais, fases, reinícios e preservação dos perfis.

O pacote público é verificado com `python tools/validate_dev11.py --packed=build/Hordas-0.12.0/Hordas-0.12.0.exe dev_public11`. O pacote DEV aceita as suítes `dev_feature11`, `dev_sandbox11`, `dev_encounters11`, `dev_attacks11` e `dev_panel11`. Instruções completas em `docs/MODO_DEV_0_11.md`.

Os testes de atalhos de desenvolvimento antigos só fazem sentido no editor ou no pacote DEV. O pacote público deve rejeitá-los. Os registros abaixo são históricos.

# Validação atual, versão 0.10

`python tools/validate_campaign10.py` executa as verificações atuais por etapa, com perfis isolados. Os testes de captura precisam do renderizador real; o runner escolhe esse modo automaticamente. `tests/full_campaign10.gd` percorre a campanha completa com um bot invulnerável em passos 1/60. Não mede dificuldade humana nem FPS.

- `node relay/match-test.mjs --campaign`: quatro processos, encontros, paredes, invocações, transformação, recompensa e salvamento individual.
- `node relay/match-test.mjs`: regressão do combate cooperativo, coleta, melhorias, resgate, carga e derrota.
- Acrescente `--packed=build/Hordas-0.10.0/Hordas-0.10.0.exe` para verificar o PCK exportado.
- `python tools/verify_export.py --suite true10`: barra, transição e vitória final no pacote.
- `Godot --path . --script res://tests/load_campaign10.gd -- --self-test --representative`: carga renderizada de quatro atores locais, seis armas por ator e a cadeia de vinte Necromantes. Retire `--representative` para a sobrecarga artificial acima do limite normal de inimigos.

Medições e limitações estão em `docs/ATUALIZACAO_0_10.md`. Os comandos abaixo registram verificações históricas. Alguns roteiros antigos de árvore e vitória na décima horda foram substituídos pelos testes de aprimoramentos 0.9 e campanha 0.10; eles não são critérios atuais de aprovação.

# Verificação de integração

Execute a partir da pasta que contém `project.godot`, com Godot 4.7.2:

```powershell
& 'C:\Users\Arthur\Downloads\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --script res://tests/integration.gd -- --self-test --slice
& 'C:\Users\Arthur\Downloads\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --script res://tests/integration.gd -- --self-test
& 'C:\Users\Arthur\Downloads\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --script res://scenes/combat/combat_contract_test.gd
& 'C:\Users\Arthur\Downloads\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --script res://tests/hordes_gold.gd -- --self-test
& 'C:\Users\Arthur\Downloads\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --script res://tests/skills_bosses.gd -- --self-test
```

O modo slice cobre movimento com frames reais de física, velocidade diagonal, colisão com pilar, dano, invulnerabilidade, morte, reinício, ataque automático, experiência, seleção de três melhorias, pausa e preservação de dados permanentes.

O modo completo acrescenta geração segura nas quatro bordas, limite de 180 inimigos, antecipação do chefe, vitória ao limpar a horda final e salvamentos ausentes, corrompidos, incompatíveis e válidos. Uma carga de 180 inimigos duráveis usa 240 frames reais de física headless. Os perfis de teste usam prefixo `integration_test_`; o progresso normal não é carregado nem gravado.

O percurso completo atravessa as dez hordas em passos 1/60. Um bot escolhe melhorias e recebe invulnerabilidade explícita. O teste cede execução a cada 30 chamadas. Isso valida progressão e transições, sem medir FPS real, dificuldade justa, controle físico ou a precisão da física em tempo real.

`hordes_gold.gd` cobre ataques de esqueletos, desvio, dano, paredes e descarte de flechas, ouro de todos os tipos, 60 segundos e pausa, atração e chegada, crédito único, morte, reinício, migração de perfil e composições exatas. Um percurso mata os inimigos por dano de teste para conferir cada quantidade, separadamente do bot de combate. A carga mistura 180 inimigos, 2.000 moedas, 240 itens de experiência e 320 flechas durante 240 frames reais headless. Arquivos de perfil dessa suíte usam prefixo `gold_test_`. O resumo fica em `user://hordes_gold_summary.json`; `--summary-path=CAMINHO` permite escolher outro destino.

Critério: terminar com `INTEGRATION_PASS` ou `COMBAT_CONTRACT_PASS` e código de saída 0. Erros e avisos do motor devem ser investigados mesmo se as verificações funcionais passarem.

`skills_bosses.gd` cobre a árvore, migração, compras inválidas, salvamento, compra pela interface com Espaço e efeitos sem duplicação. Exercita o Carrasco em frames reais, o portal completo, fases, limites, limpeza e vitória com ouro persistido. Mede os chefes com builds de referência sem habilidades permanentes, usando um bot invulnerável a 4x de tempo em 240 ticks de física por segundo. O tempo de simulação continua em passos de 1/60; os resultados não demonstram dificuldade justa para humanos ou FPS renderizado.

Após exportar, `python tools/verify_export.py` roda a suíte de árvore e chefes contra o PCK embutido em `Brasafria-0.4.0.exe`, usando o runtime de editor Godot 4.7.2 e `--main-pack`. `--suite hordes_gold` seleciona a outra suíte. Esse comando distingue o teste dos recursos empacotados do smoke nativo de 120 frames realizado pela própria exportação.


## Cooperativo

- `Godot --headless --path . --script res://tests/network_foundation.gd`: 66 verificações de regras, entradas e interrupções do resgate, incluindo dano curado no mesmo frame.
- `Godot --headless --path . --script res://tests/coop_bosses.gd -- --self-test`: 73 verificações de velocidades reais, desvio sem invulnerabilidade e surgimento fora de todas as câmeras. Física real com tempo acelerado; não representa quatro humanos.
- Em `relay/`, `node --test test.mjs` verifica o protocolo e o isolamento de eventos privados agrupados. `node godot-test.mjs` verifica transporte com quatro processos.
- `node match-test.mjs` executa quatro processos com a partida real. Verifica builds privadas, combate replicado, XP/ouro, queda no menu, resgates em ambas as direções, dano interrompendo resgate, duplicações, carga máxima, coleta de 2.000 moedas no mesmo frame, saída de cliente, derrota e salvamento individual.
- `node match-test.mjs --disconnect` verifica encerramento do host, mensagem e saldo nos clientes.
- `node match-test.mjs --packed=../build/Brasafria-0.4.0.exe` usa o pacote exportado com o runtime de editor correspondente. `--disconnect` também pode ser combinado com `--packed`.
- `python tools/verify_export.py --suite coop_bosses` ou `--suite network_foundation` verificam essas suítes contra o pacote.

Os processos da suíte usam slots `cooptest<TIMESTAMP>_<INDEX>` e removem seus perfis ao terminar; não usam o perfil normal. Logs ficam em `test_output/coop-combat-peer-*.log` e `coop-disconnect-peer-*.log`. Cada execução usa um arquivo de código exclusivo para permitir suítes paralelas.

`tests/render_coop.gd` captura título, entrada, lobby, combate/resgate, melhoria e menu em `test_output/coop_*.png`. Execute sem `--headless`, com `-- --self-test`. A captura usa quatro contextos locais preparados para revisão visual, separada do teste de rede com quatro processos.

As verificações locais não comprovam WSS público, latência real, disponibilidade do provedor, FPS renderizado ou equilíbrio humano. A hospedagem e o teste entre redes diferentes continuam pendentes.

Regressão 0.4.1: `node --test test.mjs` também verifica uma rajada de 180 mensagens e bloqueio de flood. `network_backpressure.gd` testa dez cenários de envio recusado e repetição correta. `match-test.mjs --soak-seconds=310` mantém a simulação real com quatro processos por mais de cinco minutos. `--relay-url=wss://...` direciona o teste ao túnel público; `--packed=...` escolhe o executável e `--embedded-endpoint` usa o endereço embutido.

Os eventos confiáveis pendentes são enviados em lotes de até aproximadamente 60 KiB; os dez casos de backpressure verificam preservação de ordem e ausência de perda ou duplicação em uma fila de 500 eventos.

## Balanceamento 0.12

python tools/validate_dev11.py water12 gold12 xp12 resistance12 damage12 prices12 fields12 pattern_integration12

Os testes pattern_spiral12, pattern_rings12, pattern_spears12, pattern_orbs12, pattern_crystals12, pattern_beams12, pattern_seals12 e pattern_totems12 verificam cada ataque separadamente. load_balance12 mede carga renderizada. income12 mede coleta integral por horda; bot_income12 executa três partidas com escolhas e movimento automáticos, com --fixed-fps 60 para acelerar apenas o tempo de execução.

node relay/match-test.mjs --balance

Quatro processos reais em relay local. Pode receber --packed=build/Hordas-DEV-0.12.0/Hordas-DEV-0.12.0.exe. Suítes --packed usam o Godot da mesma versão para carregar o PCK exportado; o executável nativo recebe teste de inicialização separado por tools/export_windows.py --smoke.

## Interface e consumíveis 0.15

```powershell
python tools/validate_dev11.py consumables15 consumable_frequency15
Godot_v4.7.2-stable_win64_console.exe --path . --script tests/collection15.gd -- --self-test
Godot_v4.7.2-stable_win64_console.exe --path . --script tests/load_consumables15.gd -- --self-test
node relay/match-test.mjs --survival --harness=tests/consumables_network15.gd
```

`collection15` e `load_consumables15` usam janela real. A carga com quatro atores usa transporte simulado e não mede custo real de sockets. O harness de rede usa quatro processos com sockets reais e perfis temporários. Relatório em `docs/ATUALIZACAO_0_15.md`.

## Desempenho e rede 0.14

```powershell
python tools/validate_dev11.py spatial14 codec14 network_foundation network_backpressure
node --test relay/test.mjs relay/binary-test.mjs
python tools/build_baseline14.py
python tools/benchmark14.py
python tools/stress14.py
```

As medições de renderização usam executáveis release nativos com janela. Testes de rede, condições TCP e sessão de trinta minutos estão documentados em `docs/ONLINE_0_14.md`. Resultados e limitações estão em `docs/DESEMPENHO_0_14.md`. Os cenários DEV e testes de save usam perfis temporários. Uma execução headless não comprova FPS.

## Sobrevivência 0.13

python tools/validate_dev11.py body_collision13 continuous13 campaign13 endless13 voting13 events13 event_scheduler13 chests13 chest_frequency13 dev_survival13

node relay/match-test.mjs --survival
node relay/match-test.mjs --normal13

render_survival13 gera capturas na arena; load_survival13 mede a carga renderizada com quatro atores e seis armas por jogador. Estes testes usam o motor real. A simulação estatística de baús não equivale a campanhas humanas completas. Testes antigos com valores fixos por horda são históricos, substituídos por continuous13 e campaign13.
