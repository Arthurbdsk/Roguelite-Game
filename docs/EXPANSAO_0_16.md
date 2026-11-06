# Expansão 0.16: estado parcial

## Disponível no jogo

Novas partidas começam com Arco 1 e sem Espada. Perfis/equipamentos replicados não são migrados retroativamente. Apoios opcionais antigos foram preservados. Arco recebeu 30% específico, seguido de 20% global. O bônus global foi gravado uma vez nas tabelas de dano dos 17 recursos; não há segunda multiplicação no impacto. Intervalo, quantidade e perfuração do Arco foram preservados.

Resistência automática por tempo removida, inclusive nos inimigos vivos, pois era calculada na recepção do dano. Não havia resistências próprias nos recursos atuais. Armadura do jogador preservada. +35 de vida por estágio continua usando a escala existente. Taxa-base 48 → 60/min; estágio e multiplayer continuam aplicados uma vez. Setores menos usados têm prioridade; chão, corpos, visibilidade de todos os participantes e caminho são verificados, com motivos de bloqueio registrados no DEV. A perseguição ainda pode concentrar grupos.

## Mecânicas prontas para teste DEV, visuais pendentes

Alho: aura com cooldown por alvo persistente ao sair/voltar. Vulnerabilidade por dois segundos: empurrão 1,3x e congelamento 1,15x, limitado a um segundo adicional; não ignora resistência ativa nem imunidade de chefes.

Chicote: preparação 0,1 s, golpes horizontais alternados e escalonados em 0,09 s, cada um mais alto; ignora terreno. Fogo: alvo aleatório válido, leque fixo, três projéteis base, primeiro impacto encerra, terreno bloqueia. Runa: região lógica 640×360 fixada no lançamento, ricochete em terreno/limites e cooldown de 0,5 s por alvo. Varinha Mágica: sequência a cada 0,12 s, seleção nova do mais próximo por disparo, sem perseguição, perfuração 2 nos níveis 7/8.

Todas usam tabelas de oito níveis, limite de seis armas, dano/controle reais, ofertas e baús comuns quando habilitadas. Estado e região dos projéteis são replicados pelo host. O sistema adia uma ativação se sua capacidade estiver cheia (256 projéteis, 64 golpes/rajadas), em vez de eliminar disparos prometidos.

**Não estão concluídas visualmente.** Cinco imagens citadas não estavam anexadas. Não foram criados ícones ou animações genéricos para preencher a ausência. Por isso estas cinco armas ficam fora das ofertas e da coleção públicas até terem arte final; estão equipáveis pelo laboratório DEV nos níveis 1 a 8. Não há alegação de acabamento de aura, rastro, recolhimento ou fogo aliado concluído.

## Referências e fonte

As cinco URLs indicadas de vampire.survivors.wiki foram consultadas, mas o acesso foi recusado pelo serviço de navegação. As mecânicas implementadas seguem a especificação fornecida pelo usuário; os danos não foram copiados do outro jogo.

Pesquisa no Pinterest: https://br.pinterest.com/search/pins/?q=pixel%20art%20garlic e https://br.pinterest.com/search/pins/?q=pixel%20art%20whip%20magic%20wand%20runetracer . Candidato https://br.pinterest.com/pin/332070172531568001/ foi descartado: é um personagem-cebola, não Alho. Origem identificada: https://twitter.com/modsama/status/1391343935327547392 . Candidato para varinhas: https://br.pinterest.com/pin/636485359860658190/ identifica Wildan Rahmat/ArtStation, mas a origem/licença e a seleção final ainda não foram verificadas. Nenhum arquivo de terceiros foi incorporado. As cinco referências visuais originais continuam necessárias para concluir a direção sem inventar substitutos.

Kingdom original: https://gleeson.itch.io/kingdom-pixel-font . Página do autor consultada: US$ 10, TTF 20 px, cerca de 450 glifos e suporte português. Uso pessoal/comercial permitido; a licença impede disponibilizar o arquivo isolado. Não existe arquivo utilizável no projeto, anexos ou Downloads consultados. A fonte anterior foi preservada; **Kingdom não aplicada**. É necessário o ZIP/TTF licenciado. Não publicar o TTF bruto no repositório aberto.

## Danos do Arco

| Nível | Antes | +30% específico | Final após +20% global |
|---|---:|---:|---:|
| 1 | 12.6 | 16.38 | 19.656 |
| 2 | 15.3 | 19.89 | 23.868 |
| 3 | 16.2 | 21.06 | 25.272 |
| 4 | 20.7 | 26.91 | 32.292 |
| 5 | 24.3 | 31.59 | 37.908 |
| 6 | 27.216 | 35.3808 | 42.457 |
| 7 | 27.216 | 35.3808 | 42.457 |
| 8 | 30.483 | 39.6279 | 47.5535 |

## Tabelas mecânicas das cinco armas

Valores base já com os 20% globais, antes dos bônus individuais. Área/quantidade/duração só afetam compatibilidades especificadas.

### garlic

| Nível | Dano | Intervalo s | Alcance/raio | Quantidade | Duração s | Velocidade | Perfuração |
|---|---:|---:|---:|---:|---:|---:|---:|
| 1 | 7.2 | 1.2 | 28 | 1 | 0 | 0 | 1 |
| 2 | 8.4 | 1.2 | 38 | 1 | 0 | 0 | 1 |
| 3 | 9.6 | 1.05 | 38 | 1 | 0 | 0 | 1 |
| 4 | 12 | 1.05 | 43 | 1 | 0 | 0 | 1 |
| 5 | 14.4 | 0.9 | 43 | 1 | 0 | 0 | 1 |
| 6 | 18 | 0.9 | 49 | 1 | 0 | 0 | 1 |
| 7 | 19.2 | 0.75 | 49 | 1 | 0 | 0 | 1 |
| 8 | 24 | 0.75 | 55 | 1 | 0 | 0 | 1 |

### whip

| Nível | Dano | Intervalo s | Alcance/raio | Quantidade | Duração s | Velocidade | Perfuração |
|---|---:|---:|---:|---:|---:|---:|---:|
| 1 | 21.6 | 1.3 | 70 | 1 | 0 | 0 | 1 |
| 2 | 21.6 | 1.3 | 70 | 2 | 0 | 0 | 1 |
| 3 | 26.4 | 1.3 | 70 | 2 | 0 | 0 | 1 |
| 4 | 31.2 | 1.3 | 80 | 2 | 0 | 0 | 1 |
| 5 | 36 | 1.3 | 80 | 2 | 0 | 0 | 1 |
| 6 | 42 | 1.3 | 92 | 2 | 0 | 0 | 1 |
| 7 | 48 | 1.3 | 92 | 2 | 0 | 0 | 1 |
| 8 | 55.2 | 1.3 | 92 | 2 | 0 | 0 | 1 |

### fire_wand

| Nível | Dano | Intervalo s | Alcance/raio | Quantidade | Duração s | Velocidade | Perfuração |
|---|---:|---:|---:|---:|---:|---:|---:|
| 1 | 33.6 | 2.8 | 300 | 3 | 0 | 160 | 1 |
| 2 | 38.4 | 2.8 | 300 | 3 | 0 | 160 | 1 |
| 3 | 43.2 | 2.8 | 300 | 3 | 0 | 180 | 1 |
| 4 | 48 | 2.8 | 300 | 3 | 0 | 180 | 1 |
| 5 | 52.8 | 2.8 | 300 | 3 | 0 | 205 | 1 |
| 6 | 57.6 | 2.8 | 300 | 3 | 0 | 205 | 1 |
| 7 | 63.6 | 2.8 | 300 | 3 | 0 | 230 | 1 |
| 8 | 70.8 | 2.8 | 300 | 3 | 0 | 230 | 1 |

### runetracer

| Nível | Dano | Intervalo s | Alcance/raio | Quantidade | Duração s | Velocidade | Perfuração |
|---|---:|---:|---:|---:|---:|---:|---:|
| 1 | 12 | 2.4 | 300 | 1 | 2.5 | 155 | 1 |
| 2 | 14.4 | 2.4 | 300 | 1 | 3 | 155 | 1 |
| 3 | 14.4 | 2.4 | 300 | 1 | 3 | 180 | 1 |
| 4 | 18 | 2.4 | 300 | 2 | 3 | 180 | 1 |
| 5 | 18 | 2.4 | 300 | 2 | 3.5 | 200 | 1 |
| 6 | 21.6 | 2.4 | 300 | 2 | 3.5 | 200 | 1 |
| 7 | 21.6 | 2.4 | 300 | 3 | 4 | 220 | 1 |
| 8 | 26.4 | 2.4 | 300 | 3 | 4.5 | 220 | 1 |

### magic_wand

| Nível | Dano | Intervalo s | Alcance/raio | Quantidade | Duração s | Velocidade | Perfuração |
|---|---:|---:|---:|---:|---:|---:|---:|
| 1 | 13.2 | 1 | 260 | 1 | 0 | 280 | 1 |
| 2 | 13.2 | 1 | 260 | 2 | 0 | 280 | 1 |
| 3 | 13.2 | 0.85 | 260 | 2 | 0 | 280 | 1 |
| 4 | 13.2 | 0.85 | 260 | 3 | 0 | 280 | 1 |
| 5 | 19.2 | 0.85 | 260 | 3 | 0 | 280 | 1 |
| 6 | 19.2 | 0.85 | 260 | 4 | 0 | 280 | 1 |
| 7 | 19.2 | 0.85 | 260 | 4 | 0 | 280 | 2 |
| 8 | 26.4 | 0.85 | 260 | 4 | 0 | 280 | 2 |

## Validação

Executados: expansion16 (início, Arco, valores compostos, resistência zero, taxa-base), weapons16 (aura/reentrada, vulnerabilidade, faixa, rajada, sequência, oito níveis, colisão varrida em parede e ricochete real), sectors16 (80 inimigos em cada mapa e distribuição após cinco segundos simulados de perseguição), regressões de consumíveis e compras/reembolsos. network16: quatro processos reais locais, seis armas nível 8 por jogador e regiões de ricochete iguais nos clientes. Primeiro ensaio: CPU host mediana 3,904 ms/p95 6,937 ms em 120 passos com 80 inimigos; aproximadamente 204 kB enviados no roteiro. Isso não mede FPS, quatro máquinas nem internet real; arte/efeitos novos ausentes tornam a carga incompleta.

Não foram concluídos: acabamento visual das cinco armas, aplicação da Kingdom, avaliação humana do início/builds, comparação renderizada final sob carga máxima e validação prolongada desta expansão pela internet. Não se afirma que o jogo ficou mais divertido por testes automáticos. Os dados de distribuição antes/depois da perseguição ficam em docs/benchmarks/sectors16.json.

O pacote DEV final também passou no mesmo roteiro de quatro processos pelo relay público WSS: CPU host mediana 3,58 ms, p95 6,637 ms, 203.747 bytes enviados no roteiro. É simulação headless curta, sem os visuais novos: não comprova FPS nem estabilidade prolongada. A versão pública exportada passou pelo início somente com Arco, eliminação de inimigo básico sem segunda arma, valores de dano, consumíveis e ausência do painel DEV.

Na medição de perseguição, o jogador se moveu para cima. Embora a geração inicial tenha distribuído aproximadamente dez inimigos em cada setor, após cinco segundos a maior concentração foi 32/80 no mapa antigo, 38/80 na Biblioteca e 36/80 nos Campos. Isso demonstra concentração por perseguição mesmo com surgimento equilibrado; não é uma promessa de eliminar filas em partidas humanas.
