# Validação histórica do protótipo 0.1.0

Este registro preserva os testes da primeira entrega. A versão 0.2 substitui o prazo de dez minutos por hordas; sua validação está em `HORDAS_E_OURO.md`.

Executado em 2 de novembro de 2026, Windows x64, Godot 4.7.2 stable. Este registro separa execução técnica de avaliação de diversão e dificuldade.

## Etapa 1: combate básico

Implementado: arena, movimento, espada automática, perseguidor, colisão com obstáculos, vida, invulnerabilidade, experiência, seleção pausada, derrota e reinício.

Executado: 26 verificações integradas cobrem esses fluxos. Movimento, diagonal normalizada e colisão com pilar usam frames reais de física. A partida abriu no Windows e o combate e a seleção de melhorias foram observados.

Problemas encontrados e corrigidos: controles de interface cresciam além dos limites por causa do tamanho mínimo; foco adiado tentava acessar botões removidos. Reiniciar limpa o estado temporário.

## Etapa 2: armas e escolhas

Implementado: três armas, cinco passivas, três vagas de passivas, cinco níveis de arma, evolução por afinidade, opções sem repetição dentro do trio, opções de reserva e apoios da fortaleza.

Executado: `COMBAT_CONTRACT_PASS`, 224 verificações, saída 0. Cobre arco frontal e traseiro, virote com colisão varrida e ordem de impacto, intervalo da órbita por alvo, limites, pré-requisitos de evolução, 100 trios de ofertas e reinício.

## Etapa 3: partida completa e persistência

Implementado: três tipos de inimigos, elite aos 5 minutos, chefe aos 9 minutos, áreas com antecipação e posição fixa, altar de risco e recompensa, vitória ou derrota aos 10 minutos, dois desbloqueios permanentes e salvamento versionado.

Executado: `INTEGRATION_PASS mode=complete assertions=340`, saída 0, sem erros ou avisos do motor na execução final. Esses 340 incluem os 26 do recorte inicial. Foram verificados surgimentos seguros em todas as bordas, limite de entidades, antecipação do chefe, fuga da área marcada, vitória, derrota, pagamento único, opções persistentes, compra e recuperação de perfil.

Arquivos ausentes, JSON inválido, versão incompatível e tipos incorretos foram exercitados sem usar o progresso normal. A gravação válida foi recarregada e a cópia anterior `.bak` foi confirmada. O diretor foi corrigido para aplicar o mesmo limite de entidades à elite e ao chefe.

A carga específica manteve 180 inimigos duráveis durante 240 frames reais de física em modo headless. Seleção de alvo, separação, posições finitas, projéteis e números de dano passaram. Tempo total de CPU nas chamadas de combate: 1.394 ms. Isso não mede FPS de uma janela renderizada.

O percurso acelerado atravessou 600 segundos com 36.001 passos de 1/60. Um bot explicitamente invulnerável escolheu melhorias, enfrentou a elite e matou o chefe. Na última execução: 1.854 abates, nível 46, pico de 89 inimigos, 1.904 surgimentos, 17,79 segundos de tempo de parede. O cenário de carga separado alcança 180. Esses números validam transições e limites; a invulnerabilidade impede usá-los como evidência de dificuldade justa.

## Etapa 4: interface e entrega Windows

Executado: `UI_SMOKE_OK`, todas as telas, 25 textos de progressão, privacidade e termos. Foram corrigidos transbordamentos de descrições e verificadas barras com 7, 5 e 6 pixels internos para vida, experiência e chefe.

Capturas do viewport foram inspecionadas: título, fortaleza, arena com as três armas e chefe, melhorias, opções e vitória. As capturas em `test_output/` usam cenários de teste controlados; a imagem de vitória é uma montagem de estado da interface, e a regra de vitória foi testada separadamente na integração.

O executável foi reexportado com os recursos embutidos. `build/Brasafria.exe` abriu no Windows e sua tela inicial foi inspecionada. O teste headless do executável por 120 frames terminou com saída 0 e sem erros. O manifesto em `build/build_manifest.json` registra tamanho, versão e SHA256.

Total funcional: 564 verificações automáticas entre integração e contrato de combate, além das verificações de layout e da inspeção visual. Os comandos reproduzíveis estão em `tests/README.md`; exportação em `README.md`.

## Problemas restantes e próxima entrega

- Falta avaliar dificuldade e ritmo em partidas reais sem invulnerabilidade.
- A animação usa quatro frames simples, sem conjuntos direcionais completos ou animações próprias de morte e ataques.
- O piso e os pontos de interesse ainda são repetitivos.
- Os sons sintetizados precisam de avaliação auditiva e de uma trilha ou ambiente sonoro.
- Controle físico, outras máquinas, Linux, macOS e versão web não foram testados.
- Equipamentos persistentes, outros personagens, mais biomas e famílias adicionais de armas são conteúdo futuro.

Próxima entrega jogável: ajustar o combate após a avaliação do jogador, melhorar as animações de dano e morte e tornar o altar mais fácil de localizar. O critério é preservar a leitura da sentinela e dos ataques do chefe sem ampliar o número de sistemas.
