# Hordas 0.18.0

## Implementado e valores antes/depois

| Sistema | Antes | Agora |
|---|---|---|
| Catálogo | 17 armas, incluindo Lâminas Orbitais | 16 armas. Lâminas removidas de dados, assets, ofertas, baús, coleção e DEV. Esfera de fogo orbital preservada. Coleção: 29 entradas. |
| Varinha de Fogo, níveis 1 a 8 | Intervalo-base 2800 ms; direção de alvo aleatório | Intervalo-base 9800 ms. Direção uniforme entre 0 e 360 graus, inclusive sem inimigos. Mesmo leque, quantidade, velocidade, dano e simultaneidade. |
| Runa Traçante, níveis 1 a 8 | Intervalo-base 2400 ms | Intervalo-base 6400 ms. Duração, ricochetes, perfuração, quantidade, velocidade e dano preservados. |
| Alho | Dano anterior, sem lentidão ou empurrão inicial | Dano anterior × 110%, uma vez. Movimento limitado a 85% dentro da aura, sem acumular auras; empurrão inicial de intensidade 35. |
| Proteção por acerto comum | Invulnerabilidade global de 850 ms | Sem proteção global automática. Bloqueio de 400 ms por jogador/entidade atacante, compartilhado por seus tipos de ataque. |
| Intervalos inimigos | Base anterior | 85% da base para inimigos comuns/especiais. Preparação e recuperação visual preservadas; intervalos de chefes preservados. |
| Machado | Machado pequeno de uma lâmina | Duas lâminas azuis, bordas claras, cabo marrom/vermelho, fundo transparente. Mesmo tamanho físico e trajetória/rotação/perfuração/dano. |
| Texto numérico | Casas decimais em estatísticas e comparações | Inteiros; tempos fracionários em milissegundos; regeneração descrita por período. Precisão interna preservada. |
| Fonte | Fonte anterior; Kingdom pendente | Aurusenthial Gothic aplicada, com apoio somente nos caracteres ausentes. |
| Áudio | Efeitos sintetizados; não havia player contínuo de música | Trilha fornecida de aproximadamente 114 s, um player, loop com fades e volume Música separado. |
| Interface | Estilos planos existentes | Dois elementos do freefantasy: placa de madeira para botões/estados e moldura de madeira/metal integrada ao azul existente. |

Os aumentos de 7000 ms e 4000 ms são gravados nas tabelas-base, antes de Recarga. Não há uma segunda soma no disparo. Os multiplicadores globais antigos de dano não foram reaplicados. Os valores exatos, inclusive frações, estão em [balance18_final.json](balance18_final.json); `data/balance18_audit.json` conserva a base anterior para os testes.

### Alho por nível

Para registrar exatamente as frações sem confundi-las com os números inteiros mostrados no jogo, a tabela usa **centésimos de dano**: 100 centésimos equivalem a 1 ponto de dano.

| Nível | Antes, centésimos | Depois, centésimos | Intervalo preservado |
|---|---:|---:|---:|
| 1 | 720 | 792 | 1200 ms |
| 2 | 840 | 924 | 1200 ms |
| 3 | 960 | 1056 | 1050 ms |
| 4 | 1200 | 1320 | 1050 ms |
| 5 | 1440 | 1584 | 900 ms |
| 6 | 1800 | 1980 | 900 ms |
| 7 | 1920 | 2112 | 750 ms |
| 8 | 2400 | 2640 | 750 ms |

A aura consulta a grade espacial existente. Cada inimigo guarda referências fracas dos donos presentes; a verificação de distância remove a lentidão ao sair. Usa a lentidão mais forte, inclusive ao combinar com outros controles. Chefes não recebem a nova lentidão nem o empurrão. A suscetibilidade anterior a empurrão/congelamento permanece nos inimigos elegíveis. O registro do primeiro contato é separado do timer de dano, portanto sair/voltar não concede outro empurrão. A correção física existente continua bloqueando paredes e corpos.

### Dano recebido

O host usa a identidade da instância atacante, não sua espécie. Identidade acompanha flechas, fogo, magia, frascos/veneno, golpes, investidas e áreas de chefes. Campos de propriedade usados para limpar invocações continuam separados quando necessário. Mensagens atrasadas não reutilizam a identidade de um novo inimigo.

Um acerto bloqueia somente aquele atacante por 400 ms. Inimigos distintos podem acertar juntos. Cada golpe único continua tendo seu registro de execução; feixes que já possuíam intervalo maior preservam esse intervalo. O veneno mantém um efeito renovável, sem empilhar instâncias: dez ticks isolados continuam causando 20 de dano-base. Quando há outro ataque do mesmo Médico dentro do bloqueio de 400 ms, o tick também respeita esse bloqueio. Proteções explícitas de reanimação/Reviver, estados protegidos e DEV impedem dano, inclusive veneno.

Os intervalos foram reduzidos na cópia de atributos de cada inimigo, uma vez. A recarga de conjuração do Necromante e a espera da investida comum usam o mesmo fator. O intervalo de contato de 400 ms e o tick de veneno de 1 s não recebem outra redução. Chefes ficam fora do multiplicador de ataque.

### Precisão e interface

`DisplayNumbers` centraliza inteiros, durações, regeneração e comparações. Exemplos: `400 ms`, `1200 ms`, `1 de vida a cada 10 s`. Comparações que arredondariam para o mesmo número incluem a mudança percentual ou indicam mudança menor que 1%. Valores positivos muito pequenos não aparecem como dano zero. Acúmulos de experiência, ouro, dano e regeneração permanecem fracionários.

As telas não percorrem/reformatam toda a árvore a cada frame. As conversões acontecem quando seus textos são atualizados; expressões de compatibilidade legadas também passam pelo formatador. O DEV mostra multiplicadores em porcentagem e custos de rede em microssegundos inteiros.

## Fonte, áudio e pacote de UI

Aurusenthial Gothic foi copiada do arquivo fornecido. Sua licença interna foi preservada. O usuário confirmou licença comercial para incorporar ao jogo. Por isso os executáveis contêm a fonte; o TTF avulso não é publicado no GitHub. Para exportar em outra máquina, coloque o arquivo licenciado em `assets/fonts/AurusenthialGothic.ttf`. O exportador verifica sua presença. O editor pode abrir com a fonte de apoio quando o arquivo não estiver disponível.

A fonte principal não possui vários acentos portugueses e a seta. A fonte de apoio existente cobre os acentos; fontes de símbolos do sistema cobrem símbolos ausentes. Não há substituição da fonte principal em textos pequenos. A renderização ajusta proporção/espaçamento sem regravar o TTF. Altura mínima dos rótulos passa a respeitar a métrica da fonte, e cards longos calculam a própria altura. Isso corrigiu um título de subida de nível inicialmente invisível por ter uma linha maior que seu retângulo.

A música usa uma única instância `GameMusic`, stream carregado uma vez e loop do próprio MP3. Há fade de 600 ms nas pontas e transição gradual de ganho entre menu/partida. Avisos importantes abaixam a trilha temporariamente. Volume Música é separado dos efeitos e persistido, com padrão 35% para saves antigos. O MP3 permanece idêntico ao fornecido. Não havia ID3 nem licença adicional nos arquivos recebidos; o nome original foi mantido nos créditos, sem inventar autoria/licença. A avaliação auditiva humana do volume final continua necessária.

O encerramento normal interrompe música/efeitos e espera 250 ms pelo mixer antes de fechar. A exportação DEV inicialmente expôs um playback MP3 ainda em uso no encerramento imediato; o caminho de saída foi corrigido e os dois smokes finais ficaram limpos. O smoke executa 120 frames e usa a mesma função de saída do botão Sair/janela, em vez de forçar o desligamento do motor no meio do áudio. O comportamento assíncrono do áudio e relatos relacionados constam no [rastreador oficial do Godot](https://github.com/godotengine/godot/issues/76745).

Do UI Bundle foram usados somente dois recortes de `freefantasy.png`. O centro da moldura foi ajustado à paleta azul existente. Folhas de cassino, pastel, horror/cozy e imagens completas não entram no executável. Não havia README/LICENSE/autor no ZIP fornecido; o crédito registra o nome do pacote e a autorização do usuário, sem presumir licença CC0. Veja os arquivos de crédito em `assets/audio`, `assets/fonts` e `assets/v18`.

## Executado e testado

- Etapas individuais: remoção/compatibilidade, Fogo sem alvos em 256 direções sorteadas, intervalos dos oito níveis antes de Recarga, Alho por entrada/saída e reentrada, dano fracionário e controles, Machado em janela.
- `adjustments18`: entidades diferentes no mesmo instante; mesmo atacante bloqueado em 399 ms e aceito em 400 ms; dois projéteis compartilhando bloqueio; proteção explícita/DEV; veneno isolado por dez segundos; intervalos dos seis tipos especiais/comuns; chefe preservado; persistência de Música sem perder ouro.
- `ui18`: dez telas em janela, menus/coleção/build/resultado/retorno/infinito, painel DEV, ausência de números decimais, opções de velocidade inteiras, glifos/fallback, slider Música e cards longos. Coleção também renderizada nos três tamanhos do teste existente.
- `music18`: reprodução efetiva do MP3 em execução, transição menu/partida sem recarregar stream, passagem pelo fim do arquivo/loop, mute/retorno de volume, um player e abaixamento para avisos. Executado em janela e headless; a avaliação auditiva humana não foi substituída por esse teste.
- Pacote público: `adjustments18`, `music18`, `weapons16`, `expansion16`, `consumables15`, `prices12`, `dev_public11`; as telas e o Machado também executados em janela contra os recursos embalados.
- Regressões adicionais: progressão de todos os itens até 8, seis armas/quatro passivas, efeitos permanentes, encontros DEV nos três mapas, 46 ataques DEV, sobrevivência/eventos e isolamento do save. Duas fixtures antigas foram atualizadas: o limite pressupunha Espada inicial e o cenário de carga equipava a arma removida. As regras do jogo não foram alteradas para fazê-las passar.
- Quatro processos locais reais no roteiro completo do jogo público: movimento, opções individuais, chefes/fases, Devorador, divisão de slimes, poças, reanimação, 2000 objetos de ouro, saída e saldo. Todos passaram. Exemplo do roteiro: host enviou 324528 bytes em aproximadamente 20 s; fila máxima do relay 19 ms. Esses totais não são uma taxa sustentada de tráfego.
- Quatro processos pelo relay WSS público, um renderizado: replicação das armas, dano autorizado pelo host, recusa de dano no cliente, remoção das Lâminas, fonte embutida e save original preservado. Todos passaram. Roteiro curto: host tick mediano 4226 µs, p95 8653 µs; 209821 bytes enviados pelo host.
- Executáveis público e DEV exportados, com protocolo 2/versão 0.18.0 e smoke de 120 frames mais saída normal. A versão pública não contém os recursos DEV, e F8 continua exclusivo da versão DEV.
- O executável público também foi aberto diretamente com janela e fechou pelo caminho normal de smoke, com OpenGL/RX 6600 registrado e sem erros no log final.

## Risco medido de cerco e enxame

Fixture de seis segundos sem comandos de movimento, sem defesa e com vida artificialmente alta para medir todos os impactos, sem encerrar cedo por morte:

| Cenário real | Inimigos iniciais | Acertos aceitos | Vida perdida, aproximadamente |
|---|---:|---:|---:|
| Cerco | 20 arqueiros | 3 | 30 |
| Enxame | 225 slimes pequenos | 177 | 283 |

O enxame ultrapassa a vida inicial normal rapidamente. Não houve compensação de dano, quantidade, velocidade ou dificuldade para suavizar essa consequência. Esses roteiros não determinam se o balanceamento ficou agradável para uma pessoa jogando.

## Desempenho renderizado

Windows local, Radeon RX 6600, Godot 4.7.2, Compatibility/OpenGL. Viewport lógico 640×360, janela do projeto 1280×720. Quatro jogadores simulados na mesma instância; seis armas nível 8 e quatro passivas nível 8 por jogador, 200 inimigos. Música decodificando durante o teste com saída silenciada. Semente 18018; RNG das armas 18001 a 18004. Cada mapa usa 60 frames de aquecimento e 180 medidos. Não é uma sessão de quatro máquinas.

| Mapa | Frame mediano / p95 / p99, µs | Host tick mediano / p95 / p99, µs | Pico de projéteis novos | Draw calls finais | Memória estática aproximada |
|---|---|---|---:|---:|---:|
| Pátio | 16666 / 17763 / 18731 | 10773 / 14494 / 15578 | 30 | 541 | 65 MiB |
| Biblioteca | 16615 / 18324 / 19683 | 10993 / 15344 / 16462 | 28 | 537 | 65 MiB |
| Campos | 16588 / 19962 / 24883 | 11542 / 17153 / 21536 | 28 | 544 | 66 MiB |

A mediana é próxima de 60 FPS, com quedas nos piores frames. Não foi estabelecido ganho de desempenho comparativo: os intervalos pedidos de Fogo/Runa naturalmente alteram a carga de projéteis, portanto comparar diretamente com o teste da versão anterior seria enganoso. Buscas espaciais, colisões e limites anteriores foram preservados. Referências fracas da aura são reutilizadas e a limpeza de contatos é periódica.

## Limitações restantes

Ainda falta avaliação humana de legibilidade/volume e dificuldade durante uma partida normal, especialmente cercos/enxames após remover a proteção global. Não houve teste prolongado em quatro computadores/redes distintas. O relay público continua no plano gratuito, com as limitações e picos de atraso já observados anteriormente. Não houve cobrança ou mudança de hospedagem.

Para jogar, use `Hordas-0.18.0.exe`. Todos os amigos precisam da mesma versão. Para o laboratório, use `Hordas-DEV-0.18.0.exe` e F8.
