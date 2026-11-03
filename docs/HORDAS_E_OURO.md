# Brasafria 0.2.0

Registro histórico da versão 0.2. Na versão 0.3, a árvore usa o ouro e a horda final foi substituída pelo demônio, com Carrasco aos cinco minutos. Veja `ARVORE_E_CHEFES.md` para as regras atuais.

## Regras implementadas

A progressão depende da limpeza de hordas. Não existe mais derrota por prazo de dez minutos. A preparação inicial dura 2,5 segundos; entre hordas dura cinco segundos, com moedas ainda disponíveis para coleta. Flechas e áreas hostis restantes são retiradas durante a preparação. A horda final inclui o Rei sem Brasa; eliminar toda sua composição com o chefe derrotado vence.

| Horda | Quantidade total | Intervalo de surgimento | Limite vivo | Nova pressão |
| --- | ---: | ---: | ---: | --- |
| 1 | 8 | 1,35 s | 8 | Perseguidores |
| 2 | 14 | 1,05 s | 14 | Feras rápidas |
| 3 | 22 | 0,85 s | 22 | Esqueletos com espada |
| 4 | 32 | 0,65 s | 28 | Guardas resistentes |
| 5 | 48 | 0,50 s | 36 | Arqueiros |
| 6 | 68 | 0,38 s | 50 | Mais pressão à distância |
| 7 | 93 | 0,30 s | 70 | Carrasco elite |
| 8 | 130 | 0,23 s | 95 | Cerco misto |
| 9 | 174 | 0,17 s | 130 | Mais resistentes |
| 10 | 222 | 0,12 s | 180 | Rei sem Brasa e elite |

São 811 inimigos, incluindo elites e chefe. Vida e dano não crescem por tempo ou melhoria do jogador. O número crescente, a participação de resistentes e a combinação de comportamentos produzem a escalada. As direções de surgimento alternam entre setores, sempre fora da câmera e em posições seguras. Uma tentativa sem ponto válido adia o surgimento sem perder sua quantidade.

Esqueleto com espada: 48 de vida, velocidade 31, alcance 34, antecipação 0,55 s, dano 12, intervalo 1,7 s e recuperação 0,38 s. Trava a direção ao preparar o golpe e só decide dano uma vez. Não aplica dano de contato.

Arqueiro: 38 de vida, velocidade 28, aproximação até 150 pixels, recuo abaixo de 110, início do disparo até 245 pixels, antecipação 0,75 s, intervalo 2,8 s e recuperação 0,4 s. Uma linha curta indica a direção travada. A flecha não acompanha o jogador: velocidade 155, alcance 310, vida de três segundos e dano 10. Pilares bloqueiam a linha de tiro e as flechas. Não aplica dano de contato.

Todos os inimigos deixam pelo menos uma moeda no ponto da morte. Valor padrão 1; duração de 60 segundos de partida. Raio inicial de atração 44 e velocidade de coleta 230. O ímã também amplia esse raio. A moeda só credita ao chegar a oito pixels do corpo. Expiração vem antes de chegada em caso de empate. Nos cinco segundos finais, a moeda pisca. Coleta usa brilho curto e som com limite de frequência.

O ouro recebido é somente o já coletado, inclusive após morte. Vitória, reinício, abandono e fechamento normal liquidam uma tentativa uma vez. O perfil versão 2 guarda saldo e identificador da última tentativa liquidada. A migração da versão 1 preserva selos, construções e opções, começando ouro em zero. Nenhuma compra com ouro foi adicionada; a fortaleza anterior continua usando selos.

## Ajustar valores

- `data/encounters/default.tres`: índice das hordas, preparação, limite global, limite mínimo de intervalo, moedas e orçamento de flechas.
- `data/waves/01.tres` até `10.tres`: composição exata, intervalo, limite vivo, elite e chefe.
- `data/enemies/skeleton_sword.tres` e `skeleton_archer.tres`: vida, velocidade, dano, alcance, antecipação, intervalo e dados de flecha.
- Todos os dados de inimigo possuem `gold_value`, multiplicado pelo valor global da moeda.
- `tools/generate_skeletons.py`: arte original de seis frames por variante e moeda de quatro frames. Não altera a arte anterior.

## Execução e testes

Godot 4.7.2, Windows x64, 2 de novembro de 2026.

- `HORDES_GOLD_PASS`: 640 verificações, zero falhas. Testa os esqueletos, flechas, ouro, expiração, pausa, migração, duplicação, hordas e carga.
- `INTEGRATION_PASS`: 348 verificações. O bot invulnerável atravessou as dez hordas usando armas reais: 811 abates, chefe derrotado, 810 moedas coletadas e nível 36. Duração simulada 546,73 s; pico de 84 inimigos. Essa duração é resultado do bot, não limite da partida.
- `COMBAT_CONTRACT_PASS`: 224 verificações das armas anteriores.
- `UI_SMOKE_OK`: telas, 25 textos de melhorias, barras e documentos internos.
- Carga específica: 180 inimigos mistos, 2.000 moedas, 240 itens de experiência e 320 flechas iniciais durante 240 frames reais de física headless. Nenhuma moeda foi creditada por expiração. Flechas expiradas foram removidas. Orçamentos e posições permaneceram válidos. O tempo de atualização é de CPU, sem promessa de FPS renderizado.
- Capturas do viewport inspecionadas para diferenciar esqueletos, ouro, experiência, flechas, horda e resultado. As capturas são cenários controlados, não uma partida humana completa.
- Executável Windows exportado com recursos embutidos e teste headless de 120 frames, saída 0 e sem erros. O pacote embutido também passou nas 640 verificações de hordas e ouro usando `--main-pack` com o runtime de editor da mesma versão. Essa segunda execução verifica o conteúdo empacotado; não é um teste humano da janela final.

Total funcional: 1.212 verificações entre as três suítes, além dos testes de layout. Comandos em `tests/README.md`. Logs e métricas em `test_output/`.

## Limitações restantes

Falta avaliar o equilíbrio em partidas humanas sem invulnerabilidade. O teste automatizado não demonstra que a dificuldade é justa ou divertida. Controle físico continua sem teste. As animações agora distinguem preparação e ataque dos esqueletos, mas ainda não possuem conjuntos completos de oito direções ou morte. Sons são sintetizados e precisam de avaliação auditiva. Nenhuma loja ou progressão comprável com ouro foi criada.
