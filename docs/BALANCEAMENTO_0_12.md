# Hordas 0.12.0

Implementado em 5 de novembro de 2026. Saves continuam no formato v4; o registro de gasto histórico foi preservado.

## Antes e depois

| Sistema | Antes | Agora |
|---|---|---|
| Água Benta, diâmetro no nível 1 | 72 px | 39,6 px |
| Água Benta, diâmetro no nível 8 | 120,42 px | 66,231 px |
| Experiência base por morte | 100% | 75%, com frações |
| Dano das 12 armas, oito níveis | 100% | 90%, com frações |
| Ouro comum | Garantido segundo o tipo | Um sorteio por morte: 10%, uma moeda de valor 1 |
| Resistência adicional | 0 | +5 pontos percentuais a cada duas hordas concluídas, teto 75% |
| Vida adicional | 0 | +35 pontos por estágio de duas hordas concluídas |

Os 35 pontos confirmados pelo usuário foram interpretados por estágio de duas hordas concluídas. São somados à vida máxima e atual depois dos multiplicadores existentes, preservando o dano recebido. Na transformação, essa parcela fixa é retirada antes de multiplicar a vida da fase e recolocada uma vez. A resistência também afeta inimigos vivos. Não modifica controle ou empurrão. O acréscimo de vida continua depois do teto da resistência.

Foram preservados os multiplicadores anteriores: vida 1,6; velocidade 1,3; velocidade comum 1,15. Nenhum deles foi reaplicado nesta atualização. Não existe outra redução de ouro de 90%, nem redução duplicada no dano final.

A Água Benta recebe área e duração sobre a nova base. Com os bônus máximos atuais, o nível 8 chega a aproximadamente 51,83 px de raio e 12,285 s de duração. Visual e dano usam o mesmo raio. Os outros atributos das armas foram preservados nesta redução de dano.

Devoluções do Devorador usam o valor armazenado, sem novo sorteio, sem bônus de Ouro novamente e protegidas de outros Devoradores. A experiência devolvida não recebe a redução base outra vez. Host decide os sorteios e coletas. Permanência de 60 segundos, pausa, atração e compartilhamento continuam funcionando.

Recompensas especiais fixas: Carrasco 30, Demônio 120, Guardião 90, Abominação/True Form 300. Total dos quatro encontros: 540. A recompensa final exige derrotar a True Form. Há ainda o sorteio comum na morte definitiva de cada chefe.

## Preços

| Grupo | Nível 1 | Nível 2 | Nível 3 | Nível 4 | Nível 5 | Total |
|---|---:|---:|---:|---:|---:|---:|
| Comuns de cinco níveis | 325 | 500 | 650 | 800 | 1.000 | 3.275 |
| Dano | 200 | 300 | 400 | 500 | 650 | 2.050 |
| Sorte | 325 | 500 | 650 | | | 1.475 |
| Quantidade | 325 | | | | | 325 |
| Reviver | 10.000 | | | | | 10.000 |

Nenhum aprimoramento permanente tem mais de cinco níveis. Os oito níveis pertencem aos itens da partida. Cada compra soma o preço realmente pago ao gasto registrado do item. Reembolso usa esse registro, sem bônus de Ouro. Não houve cobrança retroativa. A migração anterior continua usando o catálogo histórico, backup e proteção contra repetição.

## Renda observada

Três partidas completas controladas por um bot, com perfil zerado, nos Campos. Usaram física, armas, inimigos, drops e derrota reais; o relógio de execução foi acelerado com passos físicos de 1/60 s. Não representam habilidade humana nem renda de uma vitória. Nenhuma venceu o Carrasco.

| Semente | Duração | Horda | Nível | Abates | Ouro |
|---|---:|---:|---:|---:|---:|
| 12120 | 341,1 s | 5 | 14 | 264 | 16 |
| 12121 | 317,8 s | 6 | 14 | 273 | 27 |
| 12122 | 340,7 s | 5 | 12 | 270 | 23 |

Média: 22 de ouro. Pela amostra, cerca de 15 tentativas compram a melhoria comum inicial; 94 completam Dano; 455 compram Reviver. Essa progressão inicial está muito demorada. Os preços e drops pedidos foram mantidos.

Cinco medições controladas de eliminação e coleta integral, sem medir sobrevivência: três hordas e 67 mortes renderam 3 a 9 de ouro; oito hordas e 1.232 mortes renderam 117 a 140; dezoito hordas e 9.750 mortes renderam 952 a 974. São cenários otimistas de coleta, sem garantir o tempo real de combate ou a chegada ao chefe final.

## Campos

TileMapLayer editável com seis tiles de grama e dois de terra. São 48 árvores em oito agrupamentos e seis casas com quatro modelos. Colisão na base, profundidade pelo eixo vertical e transparência quando encobrem jogadores. Área central ampla e corredores preservados. Foram corrigidos espaços isolados entre troncos. Todos os nós de navegação válidos ficaram conectados nos raios 8, 16, 32 e 48.

Surgimento verifica chão, câmeras e acesso à área central. Ouro e experiência são reposicionados para chão livre quando necessário. Poças e invocações usam suas verificações de posição. Pátio e Biblioteca preservados.

## Novos padrões

| Padrão | Configuração inicial |
|---|---|
| Espiral Dupla | 32 passos com dois projéteis em sentidos opostos; intervalo 0,105 s |
| Anéis com Abertura | Quatro anéis; 32 direções candidatas; abertura de 85 graus; intervalo 0,65 s |
| Chuva de Lanças | Cinco faixas de 640 por 28 px, separadas por 80 px; avisos sequenciais |
| Orbes de Cerco | Seis orbes em chão livre e com linha de tiro; sete disparos por orbe; alvo fixado |
| Cristais de Gelo | Seis alvos com 65 de vida; quatro segundos de carga; 16 projéteis por sobrevivente |
| Feixes Giratórios | Três braços; alcance 280 px; largura 10 px; espaço interno de 56 px; quatro segundos |
| Selos de Perseguição | Cinco marcações sucessivas sob jogadores vivos; raio 25 px; aviso de 1,15 s; posição fixa |
| Totens de Canalização | Quatro alvos com 95 de vida; carga de 4,5 s; destruir um remove seu setor de 90 graus |

A primeira forma incorpora os quatro primeiros padrões; a True Form usa os oito. Combinações: Espiral com Selos, Anéis com Orbes, Lanças com Cristais e Feixes com Totens. Ataques anteriores preservados. Há preparação adicional de 1,35 s. Nos novos padrões da True Form: dano multiplicado por 1,2 e velocidade compatível por 1,12. Dano solo de referência: 62,1 na primeira forma e 74,52 na True Form, antes da defesa do jogador.

Controlador: até dois padrões, 384 projéteis novos e 16 alvos destrutíveis. Rajadas aguardam capacidade inteira. O orçamento anterior dos outros projéteis continua separado. Terreno, paredes, projéteis existentes e veneno entram na previsão das rotas. Ataques e combinações aguardam uma rota livre; o motivo aparece no painel DEV. Totens mantêm abertura mínima de 28 graus mesmo sem destruição. Alvos destrutíveis recebem dano das armas reais, sem recursos ou contagem de abates.

F8, somente no executável DEV: aba Chefe executa, repete e combina os novos padrões. Transformação, reinício, derrota e saída limpam alvos, áreas, filas, projéteis e paredes. O pacote público exclui painel e presets.

## Testes executados

- Água Benta níveis 1 e 8, bônus máximos, limites de dano e 24 poças simultâneas.
- Dez mil mortes com semente 1212: 998 positivos, valor 1. Todas as espécies reais, morte duplicada, expiração, pausa e devolução protegida.
- Experiência de 75%, frações, Coroa e permanente somadas, devolução sem redução repetida.
- Resistência por estágio, teto, +35 de vida, inimigos vivos e novos, multiplayer, fases e reinício.
- Doze armas em oito níveis: dados, comparação da melhoria e dano real de 90%.
- Preços, gasto histórico, reembolso exato, persistência, cliques repetidos e migração única.
- Navegação, colisões, spawn, invocações, coleta e transparência dos Campos.
- Oito padrões individuais nos três mapas, quatro combinações, colisões, destruição, expiração e limpeza.
- Renderização real dos padrões, cristal, Campos e painel; sandbox, 18 encontros/mapas e 46 ataques/transições.
- Regressões de build, progressão, aprimoramentos, Reviver, Devorador, quinze slimes, Lodo, Água Benta, Raio e Lança Relógio.
- Quatro processos Godot em relay local: builds, mapa, autoridade do host, orbes, cristais, destruição, estágios, fases, reinício e saves originais. Outra suíte verificou a campanha e liquidação final.

## Desempenho e pendências

Teste extremo renderizado em Ryzen 5 5600 e RX 6600: quatro personagens locais com seis armas no nível 8, 20 necromantes iniciais, 212 descendentes registrados, pico de 240 inimigos, 126 projéteis, 120 poças, 240 cristais e 2.000 moedas artificiais. Em 360 passos: CPU mediana 10,40 ms, p95 33,30 ms, desenho médio 12,9 FPS. A quantidade de moedas excede a observada normalmente, mas o pior caso ainda não está fluido.

O segundo par de ataques foi adiado seis vezes porque o cenário estacionário não tinha rotas previstas seguras. Não foi disparado à força. Itens e poças fora da câmera deixam de ser desenhados; suas regras continuam simuladas. Nenhuma quantidade de inimigos foi reduzida para mascarar o resultado.

Ainda precisa de ajuste: desempenho extremo, legibilidade com quatro humanos e calibração humana da renda/dificuldade. O bônus fixo de +35 também torna os slimes pequenos consideravelmente mais resistentes nas hordas posteriores. Foi mantido conforme solicitado.

Os testes de conexão usaram relay local. A publicação não resolve a ausência de um serviço público de salas configurado.

## Configuração editável

- scripts/data/encounter_balance.gd e data/encounters/default.tres: chance, XP e estágios.
- data/weapons/*.tres: dano por nível e base da Água Benta.
- data/permanent.json: preços; catálogo histórico separado.
- data/final_patterns.json: ataques, limites, tempos, multiplicadores e combinações.
- data/maps/fields.tres e scenes/maps/fields_floor.tscn: objetos, colisões e tiles.
- assets/v12/: sprites finais; fontes de produção em sources/, fora dos executáveis.

## Dano dos oito níveis

| Arma | Antes, níveis 1 a 8 | Agora, níveis 1 a 8 |
|---|---|---|
| Machado | 28, 35, 35, 43, 43, 52, 60, 68 | 25.2, 31.5, 31.5, 38.7, 38.7, 46.8, 54, 61.2 |
| Lâminas orbitais | 8, 11, 11, 14, 14, 18, 18, 23 | 7.2, 9.9, 9.9, 12.6, 12.6, 16.2, 16.2, 20.7 |
| Arco | 14, 17, 18, 23, 27, 30.24, 30.24, 33.87 | 12.6, 15.3, 16.2, 20.7, 24.3, 27.216, 27.216, 30.483 |
| Bombas | 30, 38, 38, 48, 48, 60, 60, 75 | 27, 34.2, 34.2, 43.2, 43.2, 54, 54, 67.5 |
| Bumerangue | 12, 16, 16, 20, 20, 25, 25, 32 | 10.8, 14.4, 14.4, 18, 18, 22.5, 22.5, 28.8 |
| Lança Relógio | 1, 1, 2, 2, 3, 3.36, 3.36, 3.76 | 0.9, 0.9, 1.8, 1.8, 2.7, 3.024, 3.024, 3.384 |
| Água Benta | 8, 12, 12, 16, 20, 22.4, 22.4, 25.09 | 7.2, 10.8, 10.8, 14.4, 18, 20.16, 20.16, 22.581 |
| Onda de gelo | 12, 17, 17, 22, 22, 28, 28, 36 | 10.8, 15.3, 15.3, 19.8, 19.8, 25.2, 25.2, 32.4 |
| Raio | 42, 52, 64, 78, 95, 106.4, 106.4, 119.17 | 37.8, 46.8, 57.6, 70.2, 85.5, 95.76, 95.76, 107.253 |
| Orbes | 9, 13, 15, 19, 25, 28, 28, 31.36 | 8.1, 11.7, 13.5, 17.1, 22.5, 25.2, 25.2, 28.224 |
| Lodo | 3, 5, 5, 7, 9, 10.08, 10.08, 11.29 | 2.7, 4.5, 4.5, 6.3, 8.1, 9.072, 9.072, 10.161 |
| Espada | 18, 23, 26, 32, 40, 45, 51, 60 | 16.2, 20.7, 23.4, 28.8, 36, 40.5, 45.9, 54 |
