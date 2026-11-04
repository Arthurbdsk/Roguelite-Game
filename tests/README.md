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
