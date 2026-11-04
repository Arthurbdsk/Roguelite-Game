# Hordas 0.6.0

## Implementado

- Devorador: busca periódica em índice espacial de itens, contato para consumir, prioridade para alimento, crescimento por objeto, +5 de vida máxima e atual e +0,5 de dano. Velocidade constante. Tamanho e colisão limitados a 2,2 vezes; os atributos continuam crescendo.
- Itens em atração ficam protegidos da disputa. O host remove cada objeto de forma única. Na morte, ouro e experiência consumidos voltam em até dois objetos protegidos contra novos Devoradores, além da recompensa normal. Valores são preservados sem reaplicar o multiplicador da moeda.
- Slime grande: morte com aviso de divisão e reserva de capacidade; gera exatamente quinze pequenos em posições válidas. Proteção inicial de 0,5 segundo, sem divisão recursiva. A família distribui quatro moedas e oito XP base, incluindo a recompensa do grande. Pequenos sem parcela de recompensa não geram objetos vazios.
- Lodo: rastro enquanto há deslocamento suficiente, duração inicial de três segundos e dano a cada 0,5 segundo. Sem desaceleração ou dano ao jogador. Mesma arma do mesmo dono não acumula dano por sobreposição.
- Água Benta: sorteio de chão válido na área visível, até 235 pixels do dono, sem mirar em inimigos ou cursor. Destino fixado no lançamento, frasco em arco, sombra, quebra e poça azul de quatro segundos no nível inicial. Cada dono mantém sua contribuição.
- Duas armas integradas às ofertas normais, três espaços de armas, níveis, painel, bônus permanentes de dano e intervalo, e replicação. Nenhum item raro adicionado.
- Vida-base dos inimigos multiplicada por 1,6 e velocidade por 1,3 uma vez. Inclui chefes, pequenos e invocações. Dano não recebeu multiplicador novo. A escala cooperativa e a transformação do demônio são aplicadas depois, sem duplicar os fatores.
- Novos sprites transparentes de poças, frasco, slimes, Devorador, Raio com ramificações e impacto, feixe dourado da Lança Relógio e fogo animado. Regras de ataque dos efeitos já existentes preservadas. Referências reinterpretadas com desenho original, sem copiar imagens inteiras ou marcas.
- Limpeza dos efeitos e reservas no encerramento e reinício. Índices espaciais nas poças e limite amplo de coleta para evitar buscas de jogadores para itens distantes, preservando atração e expiração.

## Valores e progressão

`data/enemies/devourer.tres`, `slime_large.tres`, `slime_small.tres`: aparência e atributos. As proporções dos pequenos em relação ao Zumbi são calculadas pelas propriedades de `EncounterBalance`.

`scripts/data/encounter_balance.gd`, editáveis no Resource `data/encounters/default.tres`: multiplicadores globais, busca, ganhos do Devorador, teto visual, quantidade e aviso da divisão, proteção e orçamento da família. O limite reservado para divisões é 420 entidades. Uma nova entrada de Slime grande aguarda capacidade, sem descartar pequenos prometidos.

`data/weapons/sludge.tres` e `holy_water.tres`: cinco níveis, dano, intervalo, raio, duração e quantidade. O nível 5 dessas armas não exige passiva de afinidade. A taxa de dano permanece em 0,5 segundo; efeitos de cada dono são separados.

| Nível | Lodo: dano / raio / duração / criação | Água Benta: dano / raio / duração / frascos / lançamento |
| --- | --- | --- |
| 1 | 3 / 16 / 3 s / 0,5 s | 8 / 36 / 4 s / 1 / 4 s |
| 2 | 5 / 16 / 3 s / 0,5 s | 12 / 36 / 4 s / 1 / 4 s |
| 3 | 5 / 20 / 3,5 s / 0,45 s | 12 / 42 / 5 s / 1 / 4 s |
| 4 | 7 / 20 / 3,5 s / 0,4 s | 16 / 42 / 5 s / 2 / 4 s |
| 5 | 9 / 24 / 4 s / 0,35 s | 20 / 48 / 6 s / 2 / 3,8 s |

Valores antes dos bônus do dono. O Lodo exige também deslocamento de 18 pixels, criação limitada a no mínimo 0,15 s e no máximo 60 poças por dono. O Devorador começa na horda 3 e o Slime grande na 4, com poucos exemplares e aumento gradual.

## Executado e testado

- Suítes novas: consumo e devolução, proteção contra disputa, quinze slimes, orçamento de recompensa, Lodo, Água Benta e multiplicadores de todas as espécies e chefes.
- Ouro e hordas: 684 verificações, incluindo 60 segundos, pausa, atração, coleta, persistência, valores e composição com os filhos adicionados separadamente ao total.
- Combate anterior: 224 verificações. Árvore e chefes: 2.109 verificações. Testes de Coroa, Raio, Lança Relógio, veneno, Shadow, duas fases, regras de rede e backpressure também executados.
- Percurso solo com bot invulnerável completou as dez hordas e venceu, sem gravar o perfil real. Isso verifica integração, sem comprovar dificuldade humana.
- Capturas renderizadas na arena de Lodo, Água Benta, Raio, feixe, fogo e build; limites do painel verificados.
- Dez suítes contra o PCK do executável 0.6.0 usando o runtime Godot correspondente. Executável nativo iniciado por 120 frames com perfil isolado.
- Partida de quatro processos pelo WSS público: 123 verificações, incluindo consumo oficial, crescimento replicado, quinze filhos, poças independentes, escolhas privadas, resgates, ouro, saída e derrota. O teste passou após substituir uma espera fixa de 0,3 segundo por uma espera limitada pela confirmação de saída do cliente.
- Sessão pública de carga por 60 segundos, quatro processos conectados até o fim. Os processos estavam neste computador através do túnel público; não representam quatro redes físicas.
- Carga renderizada com quatro contextos locais, 220 inimigos, 96 poças iniciais, 2.000 moedas, 240 cristais e 320 flechas iniciais. Em 180 frames na Radeon RX 6600: aproximadamente 41,4 FPS de média e 2.982 ms acumulados de atualização. Resultado de um cenário extremo curto, sem garantia de FPS em outros computadores. A versão anterior da mesma carga mediu 23,6 FPS; o método inicial também forçava snapshots completos sem conexão aceita.

Logs e capturas em `test_output/06-*`. Os testes usam perfis isolados e não substituem avaliação com jogadores humanos.

## Problemas e limites observados

- Cão com quatro jogadores: 99,84 px/s contra 96 px/s do jogador sem bônus. Em fuga reta, sem atacar, com separação inicial de 25 pixels, houve três acertos em seis segundos. Os percentuais pedidos foram mantidos. Atacar, controlar o inimigo ou usar melhorias de movimento ganha importância; recuar em linha reta pode não bastar.
- As investidas testadas do Carrasco e do demônio continuaram desviáveis por movimento lateral sem invulnerabilidade.
- A carga extrema ainda cai abaixo de 60 FPS e fica visualmente densa. Há espaço para mais otimização e revisão de leitura em sessões humanas prolongadas.
- Online ainda depende do relay deste computador e do túnel temporário. Não há reconexão nem migração de anfitrião. Todos devem usar 0.6.0.

## Entrega

`build/Hordas-0.6.0/Hordas-0.6.0.exe`, recursos e endereço online embutidos. O perfil continua em `app_userdata/Brasafria/profile.json`, com os identificadores permanentes anteriores preservados. Versões anteriores mantidas.
