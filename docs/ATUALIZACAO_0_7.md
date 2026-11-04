# Hordas 0.7.0

## Alterações e regras

Seis armas e quatro passivas por jogador. Primeira aquisição no nível 1, duplicatas avançam um nível, máximo 8. Sem novos itens em categoria cheia, sem opções duplicadas ou maximizadas. Menos de três melhorias válidas gera apenas as disponíveis. Sem melhorias: recuperar até 35 de vida ou receber 10 de ouro.

Coroa: bônus aditivo de 7% por nível, até 56%, calculado individualmente após a distribuição da experiência base. Armadura: redução absoluta de um por nível, conservando pelo menos 20% do dano e mínimo de um. Luvas: -6% do intervalo base por nível, mínimo de 0,15 s.

Lupa aumenta raio/largura em 5% por nível somente em Espada, poças, explosões, largura do feixe, contato das lâminas e Onda de gelo. Não altera o alcance de seleção do Raio. Ampulheta: +8% por nível para poças e lentidão normal da Onda de gelo. Não altera invulnerabilidade, paralisação da Lança Relógio nem controle em chefes.

Lança Relógio mantém três segundos de paralisação, com dois segundos de resistência global do inimigo após o efeito. Armas e jogadores distintos respeitam a mesma resistência. Onda de gelo desacelera em 30%; chefes, 15% por até um segundo.

Compras e identificadores permanentes preservados. Como a quarta passiva agora é universal, o antigo nó `pact` foi adaptado para Preparação: +10 de vida máxima inicial, mantendo a compra e os pré-requisitos. Não ocupa espaço na build.

## Densidade antes e depois

| Horda | Antes | Agora | Meta |
| --- | ---: | ---: | ---: |
| 1 | 8 | 12 | 1.5x |
| 2 | 14 | 21 | 1.5x |
| 3 | 23 | 34 | 1.5x |
| 4 | 34 | 68 | 2x |
| 5 | 50 | 100 | 2x |
| 6 | 74 | 148 | 2x |
| 7 | 99 | 297 | 3x |
| 8 | 144 | 432 | 3x |
| 9 | 194 | 582 | 3x |

Quantidades-base, antes do multiplicador cooperativo. Os acréscimos são Zumbis; a quantidade original de especiais foi preservada. Preparação entre hordas: 5 → 2,5 s. Limite simultâneo comum: 180 → 240. Surgimento continua fora de todas as câmeras e é distribuído por direções; intervalo mínimo de 0,12 s. Invocações dos chefes continuam em seus grupos próprios de 12/20 e limite 32.

Vida global 1,6x e velocidade global 1,3x anteriores foram mantidas. Somente Zumbi e os dois esqueletos recebem mais 1,15x de movimento. Sem novo aumento de vida ou dano. Multiplicadores cooperativos aplicados uma vez.

| Inimigo | Velocidade solo antes | Agora |
| --- | ---: | ---: |
| Zumbi | 32.5 | 37.375 |
| Esqueleto com espada | 40.3 | 46.345 |
| Esqueleto com arco | 36.4 | 41.86 |
| Cão | 62.4 | 62.4 |
| Besta | 61.75 | 61.75 |

Chefes e demais especiais preservam a velocidade da 0.6.0. O Cão ainda pode superar o jogador no cooperativo sem bônus de movimento.

## Tabelas de oito níveis

Valores-base sem bônus permanentes ou passivas. Raios e alcances em pixels. Intervalos e durações em segundos. Perfuração do Machado é o número máximo de inimigos atravessados por lançamento. Bumerangue acerta uma vez na ida e outra na volta; não usa o atributo de perfuração do Machado.

### Machado

| Atributo | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Dano | 28 | 35 | 35 | 43 | 43 | 52 | 60 | 68 |
| Intervalo | 2.3 | 2.3 | 2.2 | 2.2 | 2.1 | 2.1 | 2 | 1.9 |
| Raio/alcance | 240 | 240 | 240 | 240 | 240 | 240 | 240 | 240 |
| Quantidade | 1 | 1 | 2 | 2 | 2 | 3 | 3 | 3 |
| Duração | 1.5 | 1.5 | 2 | 2 | 2.5 | 2.5 | 3 | 3.5 |
| Perfuração | 2 | 2 | 3 | 3 | 4 | 4 | 5 | 6 |

### Lâminas orbitais

| Atributo | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Dano | 8 | 11 | 11 | 14 | 14 | 18 | 18 | 23 |
| Intervalo | 0.5 | 0.5 | 0.48 | 0.48 | 0.45 | 0.45 | 0.4 | 0.4 |
| Raio/alcance | 24 | 24 | 25 | 25 | 26 | 26 | 28 | 28 |
| Quantidade | 2 | 2 | 3 | 3 | 4 | 4 | 5 | 6 |
| Duração | 1.5 | 1.5 | 2 | 2 | 2.5 | 2.5 | 3 | 3.5 |
| Rotação rad/s | 3 | 3 | 3.4 | 3.4 | 3.8 | 3.8 | 4.2 | 4.6 |

### Arco

| Atributo | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Dano | 14 | 17 | 18 | 23 | 27 | 30.24 | 30.24 | 33.87 |
| Intervalo | 1.2 | 1.15 | 1.25 | 1.1 | 1 | 0.94 | 0.94 | 0.88 |
| Raio/alcance | 240 | 255 | 260 | 290 | 310 | 347.2 | 347.2 | 388.86 |
| Quantidade | 1 | 1 | 3 | 3 | 3 | 3 | 4 | 4 |

### Bombas

| Atributo | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Dano | 30 | 38 | 38 | 48 | 48 | 60 | 60 | 75 |
| Intervalo | 3 | 3 | 3 | 2.8 | 2.8 | 2.6 | 2.6 | 2.5 |
| Raio/alcance | 230 | 230 | 230 | 230 | 230 | 230 | 230 | 230 |
| Quantidade | 1 | 1 | 2 | 2 | 2 | 2 | 3 | 3 |
| Duração | 1.5 | 1.5 | 2 | 2 | 2.5 | 2.5 | 3 | 3.5 |
| Raio da explosão | 40 | 40 | 44 | 44 | 48 | 48 | 52 | 56 |

### Bumerangue

| Atributo | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Dano | 12 | 16 | 16 | 20 | 20 | 25 | 25 | 32 |
| Intervalo | 1.7 | 1.7 | 1.6 | 1.6 | 1.5 | 1.5 | 1.4 | 1.4 |
| Raio/alcance | 160 | 160 | 180 | 180 | 200 | 200 | 220 | 240 |
| Quantidade | 1 | 1 | 1 | 2 | 2 | 2 | 3 | 3 |
| Duração | 1.5 | 1.5 | 2 | 2 | 2.5 | 2.5 | 3 | 3.5 |

### Lança Relógio

| Atributo | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Dano | 1 | 1 | 2 | 2 | 3 | 3.36 | 3.36 | 3.76 |
| Intervalo | 0.9 | 0.82 | 0.74 | 0.66 | 0.58 | 0.55 | 0.55 | 0.52 |
| Raio/alcance | 160 | 180 | 200 | 220 | 240 | 268.8 | 268.8 | 301.06 |
| Quantidade | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 |
| Largura | 8 | 10 | 12 | 14 | 16 | 18 | 20 | 22 |

### Água Benta

| Atributo | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Dano | 8 | 12 | 12 | 16 | 20 | 22.4 | 22.4 | 25.09 |
| Intervalo | 4 | 4 | 4 | 4 | 3.8 | 3.57 | 3.57 | 3.36 |
| Raio/alcance | 36 | 36 | 42 | 42 | 48 | 53.76 | 53.76 | 60.21 |
| Quantidade | 1 | 1 | 1 | 2 | 2 | 2 | 3 | 3 |
| Duração | 4 | 4 | 5 | 5 | 6 | 6 | 6.5 | 6.5 |

### Onda de gelo

| Atributo | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Dano | 12 | 17 | 17 | 22 | 22 | 28 | 28 | 36 |
| Intervalo | 3.8 | 3.8 | 3.6 | 3.6 | 3.4 | 3.4 | 3.2 | 3 |
| Raio/alcance | 90 | 90 | 105 | 105 | 120 | 120 | 140 | 155 |
| Quantidade | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 |
| Duração | 1.5 | 1.5 | 2 | 2 | 2.5 | 2.5 | 3 | 3.5 |

### Raio

| Atributo | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Dano | 42 | 52 | 64 | 78 | 95 | 106.4 | 106.4 | 119.17 |
| Intervalo | 2.6 | 2.5 | 2.4 | 2.2 | 2 | 1.88 | 1.88 | 1.77 |
| Raio/alcance | 150 | 175 | 200 | 225 | 250 | 280 | 280 | 313.6 |
| Quantidade | 1 | 2 | 3 | 4 | 5 | 5 | 6 | 6 |

### Orbes

| Atributo | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Dano | 9 | 13 | 15 | 19 | 25 | 28 | 28 | 31.36 |
| Intervalo | 0.42 | 0.4 | 0.38 | 0.36 | 0.32 | 0.3 | 0.3 | 0.28 |
| Raio/alcance | 42 | 46 | 48 | 53 | 60 | 67.2 | 67.2 | 75.26 |
| Quantidade | 3 | 3 | 4 | 4 | 5 | 5 | 6 | 6 |

### Lodo

| Atributo | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Dano | 3 | 5 | 5 | 7 | 9 | 10.08 | 10.08 | 11.29 |
| Intervalo | 0.5 | 0.5 | 0.45 | 0.4 | 0.35 | 0.33 | 0.33 | 0.31 |
| Raio/alcance | 16 | 16 | 20 | 20 | 24 | 26.88 | 26.88 | 30.11 |
| Quantidade | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 |
| Duração | 3 | 3 | 3.5 | 3.5 | 4 | 4 | 4.5 | 4.5 |

### Espada

| Atributo | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Dano | 18 | 23 | 26 | 32 | 40 | 45 | 51 | 60 |
| Intervalo | 0.8 | 0.8 | 0.76 | 0.72 | 0.66 | 0.62 | 0.62 | 0.58 |
| Raio/alcance | 58 | 65 | 67 | 76 | 88 | 98.56 | 98.56 | 110.39 |
| Quantidade | 1 | 1 | 2 | 2 | 2 | 2 | 2 | 2 |

## Passivas

| Item | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Armadura | 1 defesa | 2 defesa | 3 defesa | 4 defesa | 5 defesa | 6 defesa | 7 defesa | 8 defesa |
| Botas | 8 px/s | 16 px/s | 24 px/s | 32 px/s | 40 px/s | 48 px/s | 56 px/s | 64 px/s |
| Ímã | 14 px | 28 px | 42 px | 56 px | 70 px | 84 px | 98 px | 112 px |
| Luvas | 6% | 12% | 18% | 24% | 30% | 36% | 42% | 48% |
| Coroa | 7% XP | 14% XP | 21% XP | 28% XP | 35% XP | 42% XP | 49% XP | 56% XP |
| Lupa | 5% raio/largura | 10% raio/largura | 15% raio/largura | 20% raio/largura | 25% raio/largura | 30% raio/largura | 35% raio/largura | 40% raio/largura |
| Ampulheta | 8% duração | 16% duração | 24% duração | 32% duração | 40% duração | 48% duração | 56% duração | 64% duração |
| Coração | 10 vida | 20 vida | 30 vida | 40 vida | 50 vida | 60 vida | 70 vida | 80 vida |

## Mapas e edição

Pátio preservado, Biblioteca horizontal com estantes e corredores abertos, Campos com caminhos de terra, ruínas e árvores periféricas. Mesmos atributos de inimigos, hordas e chefes nos três mapas.

Pisos editáveis em `scenes/maps/courtyard_floor.tscn`, `library_floor.tscn` e `fields_floor.tscn`, usando TileMapLayer e o atlas `assets/map_tiles7.png`. Obstáculos com colisão em `data/maps/*.tres`, propriedade `blocks`. Decoração complementar em `scripts/world/arena.gd`. O piso usa células, não uma imagem única.

Solo escolhe o mapa antes da partida. O host escolhe no lobby; mudar o mapa retira a prontidão de todos. O servidor envia preparação, cada participante carrega a mesma cena e confirma, e só então inicia a partida e sua preparação inicial. A geometria e os pisos têm semente fixa 81391 e são empacotados na mesma versão.

## Testes e limites

- Limites de inventário, tabelas dos 12 itens ativos e oito passivas, bloqueio no nível 8, Coroa aditiva e fallback.
- Cada arma nova executada separadamente, com verificação de dano e limpeza. O Machado exigiu correção da trajetória antes de avançar.
- Compatibilidades de área e duração, piso do intervalo, resistência global à paralisação e limite de redução de dano.
- Caminhos conectados, início seguro, surgimento fora da tela, portal e 12 invocações válidas nos três mapas. Revisão das capturas com personagens, inimigos, moedas, ataques e interface.
- Percurso solo completo: vitória, 1.696 inimigos programados, nível 46 em aproximadamente 570 segundos de simulação. Bot invulnerável, não uma partida humana. Curva de XP preservada após a medição; a versão anterior ficou perto do nível 38.
- Partidas com quatro processos na Biblioteca e Campos: escolha/carregamento sincronizados, controle individual, resgates, ouro, saída, derrota e persistência.
- Executável nativo por 120 frames e testes de limites/progressão contra os recursos empacotados.
- Executável pelo WSS público nos Campos, mais 60 segundos na Biblioteca com seis armas por jogador: os quatro processos permaneceram conectados. Rodaram neste computador, sem comprovar quatro redes físicas.
- Carga renderizada curta: quatro contextos locais com seis armas, 220 inimigos e muitas poças/projéteis, aproximadamente 32,4 FPS. Com 240 inimigos, três necromantes e 21 esqueletos invocados, aproximadamente 28,8 FPS na RX 6600. Não representa quatro jogadores humanos nem garantia de desempenho em outros computadores.

Otimizações: busca de colisão dos projéteis no índice espacial, descarte antecipado das lâminas fora do alcance, culling de moedas fora da câmera e pisos em tiles. Quantidades e regras de ataque não foram reduzidas para os testes. A carga extrema continua abaixo de 60 FPS; precisa de mais otimização e avaliação humana da leitura.

O visual mantém alguns módulos simples e repetidos, especialmente as estantes. Ainda cabe acabamento artístico. O online depende do túnel temporário e deste computador ligado. Sem reconexão ou migração de anfitrião. Todos precisam usar 0.7.0.

## Entrega

`build/Hordas-0.7.0/Hordas-0.7.0.exe`. Saves continuam em `app_userdata/Brasafria/profile.json`; versões anteriores preservadas. Logs e imagens: `test_output/07-*`.
