# Verificação de integração

Execute a partir da pasta que contém `project.godot`, com Godot 4.7.2:

```powershell
& 'C:\Users\Arthur\Downloads\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --script res://tests/integration.gd -- --self-test --slice
& 'C:\Users\Arthur\Downloads\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --script res://tests/integration.gd -- --self-test
& 'C:\Users\Arthur\Downloads\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --script res://scenes/combat/combat_contract_test.gd
& 'C:\Users\Arthur\Downloads\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --script res://tests/hordes_gold.gd -- --self-test
```

O modo slice cobre movimento com frames reais de física, velocidade diagonal, colisão com pilar, dano, invulnerabilidade, morte, reinício, ataque automático, experiência, seleção de três melhorias, pausa e preservação de dados permanentes.

O modo completo acrescenta geração segura nas quatro bordas, limite de 180 inimigos, antecipação do chefe, vitória ao limpar a horda final e salvamentos ausentes, corrompidos, incompatíveis e válidos. Uma carga de 180 inimigos duráveis usa 240 frames reais de física headless. Os perfis de teste usam prefixo `integration_test_`; o progresso normal não é carregado nem gravado.

O percurso completo atravessa as dez hordas em passos 1/60. Um bot escolhe melhorias e recebe invulnerabilidade explícita. O teste cede execução a cada 30 chamadas. Isso valida progressão e transições, sem medir FPS real, dificuldade justa, controle físico ou a precisão da física em tempo real.

`hordes_gold.gd` cobre ataques de esqueletos, desvio, dano, paredes e descarte de flechas, ouro de todos os tipos, 60 segundos e pausa, atração e chegada, crédito único, morte, reinício, migração de perfil e composições exatas. Um percurso mata os inimigos por dano de teste para conferir cada quantidade, separadamente do bot de combate. A carga mistura 180 inimigos, 2.000 moedas, 240 itens de experiência e 320 flechas durante 240 frames reais headless. Arquivos de perfil dessa suíte usam prefixo `gold_test_`. O resumo fica em `test_output/hordes_gold_summary.json`.

Critério: terminar com `INTEGRATION_PASS` ou `COMBAT_CONTRACT_PASS` e código de saída 0. Erros e avisos do motor devem ser investigados mesmo se as verificações funcionais passarem.

Após exportar, `python tools/verify_export.py` roda a suíte de hordas e ouro contra o PCK embutido em `Brasafria-0.2.0.exe`, usando o runtime de editor Godot 4.7.2 e `--main-pack`. Esse comando distingue o teste dos recursos empacotados do smoke nativo de 120 frames realizado pela própria exportação.
