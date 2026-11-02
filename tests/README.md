# Verificação de integração

Execute a partir da pasta que contém `project.godot`, com Godot 4.7.2:

```powershell
& 'C:\Users\Arthur\Downloads\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --script res://tests/integration.gd -- --self-test --slice
& 'C:\Users\Arthur\Downloads\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --script res://tests/integration.gd -- --self-test
& 'C:\Users\Arthur\Downloads\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --script res://scenes/combat/combat_contract_test.gd
```

O modo slice cobre movimento com frames reais de física, velocidade diagonal, colisão com pilar, dano, invulnerabilidade, morte, reinício, ataque automático, experiência, seleção de três melhorias, pausa e preservação de dados permanentes.

O modo completo acrescenta geração fora da câmera nas quatro bordas, limite de 180 inimigos, antecipação fixa do chefe, janela de reação, condições de vitória e derrota aos 600 segundos e salvamento ausente, corrompido, de versão incompatível, com tipos inválidos e válido. Uma carga de 180 inimigos duráveis exercita seleção de alvo, separação, projéteis e orçamento de números de dano durante 240 frames reais de física em execução headless. Os arquivos de salvamento do teste têm prefixo único `integration_test_` em `user://`; o progresso normal não é carregado nem gravado.

O percurso completo avança os 600 segundos com 36.001 chamadas de simulação em delta 1/60. Um bot escolhe melhorias e recebe invulnerabilidade explicitamente. O teste cede a execução a cada 30 chamadas para liberar nós e atualizar o motor. As métricas registram tempo de parede, tempo gasto nas chamadas de simulação, pico de entidades, eliminações e nível. Esse percurso acelerado valida os sistemas e as transições; não mede FPS real, equilíbrio de dificuldade, compatibilidade com controle físico ou precisão da física em tempo real. Som e leitura visual precisam de teste interativo.

Critério: terminar com `INTEGRATION_PASS` ou `COMBAT_CONTRACT_PASS` e código de saída 0. Erros e avisos do motor devem ser investigados mesmo se as verificações funcionais passarem.
