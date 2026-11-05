# Campanha e efeitos 0.10.0

## Implementado

A animação do herói usa deslocamento real, tolerância de controle e última direção. Empurrar um obstáculo sem sair do lugar termina a caminhada. Ataque, dano, queda e retorno mantêm prioridade. Réplicas online usam o estado oficial e encerram a caminhada ao chegar ao destino.

O tema de fonte está centralizado em `scripts/ui/game_fonts.gd`. O arquivo utilizável Kingdom não foi fornecido: apenas a imagem de apresentação foi recebida. A fonte anterior continua ativa e foi verificada com acentos, números e símbolos usados na interface. Para ativar a Kingdom, forneça o TTF autorizado em `assets/fonts/Kingdom.ttf` e reimporte o projeto. A fonte anterior fica como apoio aos caracteres ausentes. A aparência e a legibilidade da Kingdom ainda não foram verificadas.

O gelo do Demônio escolhe um jogador vivo, trava a posição e mostra toda a extensão antes da formação. O comprimento lógico de cada uma das duas barreiras passou de 560 para 1.120 pixels na horizontal; na vertical fica limitado a 1.100 pixels para caber entre os limites transitáveis da arena. Cada barreira tem uma abertura de 160 pixels, desencontrada da abertura da outra. Isso produz quatro segmentos de colisão/aviso, sem transformar o ataque em quatro paredes completas. O corredor entre barreiras é de 150 pixels. O posicionador rejeita jogadores, obstáculos e layouts que desconectam a área navegável. O ataque do Demônio conserva o efeito anterior de desaceleração; as paredes da Abominação são sólidas.

Flocos animados substituem os pontos azuis da Onda de Gelo, com formação, expansão e dissolução. A explosão da bomba tem oito quadros de clarão, fogo, fragmentos e dissipação durante a janela visual existente de 0,4 s. Dano, raio, atraso e contagem de acertos não foram alterados. Os efeitos foram recriados; a prévia com marcas não foi integrada.

## Cronograma e encontros

| Horário da partida | Encontro | Ao terminar |
|---|---|---|
| 5 min | Carrasco existente | Continua |
| 10 min | Demônio existente, duas fases | +120 ouro e retomada das hordas |
| 15 min | Guardião | +90 ouro e retomada das hordas |
| 20 min | Abominação e True Form | +300 ouro e vitória após a True Form |

Os horários usam o relógio da partida. Se um encontro estiver ativo, o seguinte fica pendente. O encontro não reinicia por passar novamente pelo mesmo horário. Recompensas normais de experiência, moeda e medalhas seguem os sistemas existentes. A tabela mostra o bônus direto de ouro dos encontros; cada morte final também deixa a moeda normal. A transformação não concede nenhuma dessas recompensas.

As hordas continuam usando a composição comum da nona horda depois do primeiro chefe. A quantidade cresce 8% por horda adicional, limitada a 80% extra sobre essa composição. O limite usual de geração permanece em 240 inimigos. Modificadores cooperativos e Desafio são aplicados uma vez. A curva de experiência, os seis espaços de armas, quatro passivas e o limite de oito níveis foram preservados.

## Atributos configurados

Valores abaixo para um jogador, Desafio zero, sem defesa do jogador. A base de referência é a segunda fase do Demônio na mesma dificuldade. O multiplicador anterior de vida 1,6 e velocidade 1,3 já está incluído; não foi aplicado novamente nesta expansão.

| Atributo | Demônio fase 2 | Guardião | Abominação | True Form |
|---|---:|---:|---:|---:|
| Vida máxima | 14.976 | 11.980,8 | 32.947,2 | 49.420,8 |
| Movimento, px/s | 91 | 72,8 | 109,2 | 109,2 |
| Bola de fogo, dano | 20,25 | Não usa | 40,5 | 40,5 |
| Energia/coluna, dano | 31,05 | 24 | 62,1 | 62,1 |
| Dash, dano | 40,5 | Não usa | 81 | 81 |

A Abominação usa 2,2 vezes a vida da fase 2, duas vezes o dano equivalente e 1,2 vez o movimento do Demônio. A True Form multiplica a vida máxima já calculada por 1,5. Com quatro participantes, o multiplicador de vida atual é 2,5: Abominação 82.368 e True Form 123.552 antes do Desafio. A transformação não aplica 2,5 novamente. Com os multiplicadores atuais de dano cooperativo, um dash pode ser fatal para um jogador sem bônus de vida; os percentuais pedidos não foram reduzidos para esconder essa situação.

Guardião: seis asas, rosto oculto e vestes longas. Alterna dois feixes cruzados, doze penas que param e depois partem em direções fixas, e anel expansivo com abertura de 72 graus. Avisos de 1,2 a 1,3 s, recuperação de 0,8 s, temporizador base de 2,2 s. O dano inicial de 24 e a vida foram comparados à build obtida pela simulação aos quinze minutos: nível 80, seis armas nível 8, quatro passivas nível 8 e 180 de vida. Isso não demonstra equilíbrio humano.

Abominação: silhueta baixa, membros coordenados, olhos claros e segmentos alaranjados. Colisão central de raio 22; os braços decorativos não causam contato. Alterna leque de 180 graus com treze bolas por rajada e dez rajadas espaçadas em 0,42 s, invocação, paredes sólidas, sete colunas em sequência, dash travado, lanças de gelo com corredores e faixas de luz alternadas. Preparação de 1,25 s e recuperação de 0,8 s. O controlador limita as categorias simultâneas e evita combinar padrões extensos de chão.

True Form: transformação de 1,6 s, limpeza dos ataques e invocações anteriores, caveira clara, boca alongada e manto negro animado. O temporizador base cai de 1,8 para 1,3 s, além da preparação. Acrescenta ondas com abertura de 80 graus que gira a 0,4 rad/s. A barra de vida tem moldura, caveira, nome e preenchimento separados. A barra do jogador continua visível.

## Invocações e navegação

A primeira leva contém exatamente vinte Necromantes, sem multiplicar a quantidade pela equipe. Cada um começa a preparação da conjuração ao entrar. Cada conjuração completa gera doze criaturas válidas aleatórias. O sorteio pode incluir Necromantes na primeira geração; a segunda e última geração exclui Necromantes. Chefes, minibosses e Slime grande não participam desse sorteio.

Cada invocador espera seus doze filhos diretos morrerem antes de conjurar novamente. O orçamento da cadeia é 220 entidades vivas, incluindo os vinte iniciais; lotes de doze são reservados inteiros. Com vinte casters vivos, cabem dezesseis lotes, totalizando 212 entidades e oito vagas insuficientes para um novo lote. Conjurações adicionais aguardam. Nenhum inimigo é apagado para abrir orçamento. As ferramentas F9 mostram solicitados, gerados e adiados.

Pontos de surgimento têm aviso e rejeitam proximidade de jogadores e obstáculos. Paredes sólidas atualizam obstáculos de física e os campos de navegação na formação e remoção. Transição, morte, derrota e reinício limpam os efeitos e colisores correspondentes.

## Arquivos editáveis e atalhos

- `data/late_campaign.json`: horários, atributos, padrões, recompensas e orçamento.
- `scripts/data/boss_balance.gd`: comparação com o Demônio e parâmetros de gelo.
- `scripts/bosses/late_campaign.gd`, `late_boss.gd`, `late_arena.gd`, `chain_budget.gd`, `ice_layout.gd`: controladores.
- `scripts/ui/true_health_bar.gd`: barra ornamental.
- `assets/v10`: PNGs com alpha e quadros alinhados. `assets/v10/SOURCES.md` descreve a origem e o empacotamento.
- F9 no menu ou os três arquivos `Testar_*.cmd`: Guardião, Abominação e True Form com builds representativas, sem gravar ouro ou progresso.
- CLI: `-- --encounter-test=guardian`, `horror` ou `true`.

O nome interno Brasafria e o formato 4 do perfil foram preservados. O progresso permanece em `%APPDATA%/Godot/app_userdata/Brasafria/profile.json`. Esta atualização não executa nova migração nem altera a tabela de aprimoramentos permanentes.

## Executado e verificado

1. Espera/caminhada: deslocamento real, obstáculo, ruído, direção e prioridades; fonte de apoio com caracteres portugueses. Kingdom indisponível.
2. Gelo renderizado e posicionado nos três mapas; passagem do jogador bloqueada pelas paredes sólidas; Ghoul e Besta contornam os segmentos; colisores e navegação removidos ao terminar.
3. Explosão renderizada na arena: mesmo dano e raio, um único evento de dano, expiração correta.
4. Campanha completa em passos 1/60: Carrasco, Demônio, Guardião, Abominação e True Form. Vitória aos 1.510,28 s simulados, nível 120, 8.079 mortes, 8.153 ouro. Build máxima aos quinze minutos. O bot escolhe melhorias, busca experiência e recebe invulnerabilidade. Não mede controle humano, FPS ou justiça da dificuldade.
5. Guardião: feixes com quadrantes seguros, penas paradas, anel, entrada, morte e recompensa única.
6. Abominação: relações de atributos, leque, vinte casters, doze descendentes, profundidade, orçamento, paredes nos três mapas, dash desviável e colunas fixas.
7. True Form: vida 1,5 vez, transição sem pagamento antecipado, barra independente, vitória e recompensa únicas.
8. Regressões: níveis de itens, limites da build, Coroa, Lança Relógio, Raio, Devorador, slimes, poças, aprimoramentos permanentes, frações, backup/migração, Desafio e Reviver.
9. Quatro processos Godot reais: combate, escolhas privadas, coleta de 2.000 moedas, resgate, morte e salvamento individual. Novo roteiro de campanha passou localmente e através do túnel público WSS com o PCK exportado antes do ajuste final do limite vertical e do encerramento desse túnel. A exportação final foi verificada com quatro processos locais. Não são quatro pessoas em redes distintas.
10. Exportação Windows com recursos embutidos, smoke nativo de 120 frames e verificações de campanha, True Form e explosão usando o PCK exportado.

## Desempenho observado e limitações

Máquina de desenvolvimento: Windows, Godot 4.7.2, OpenGL de compatibilidade, Radeon RX 6600. Cena 640×360, quatro atores locais com seis armas de nível 8. Valores medidos durante 600 ticks de física; contagem de quadros renderizados separada da quantidade de ticks.

| Carga | Pico de inimigos | Poças | Projéteis | FPS renderizado | CPU mediana/p95 por tick |
|---|---:|---:|---:|---:|---:|
| Vinte Necromantes e cadeia, 100 moedas, 240 cristais | 213 | 120 | 161 | 21,1 | 9,06 / 20,77 ms |
| Sobrecarga artificial, mais cem comuns e 2.000 moedas | 307 | 120 | 162 | 5,1 | 15,50 / 42,57 ms |

A segunda carga ultrapassa o limite normal de 240 entidades do diretor de hordas, para verificar reserva e limpeza sob sobrecarga. Os inimigos receberam vida artificialmente alta para manter a saturação. As regras e as quantidades prometidas não foram reduzidas. Houve otimizações no cálculo dos atributos durante o combate, no índice espacial das poças, na consulta das órbitas e na codificação dos estados online; ainda há queda de desempenho importante. Não está resolvido para 60 FPS nessas cargas. A próxima melhoria técnica deve reduzir o custo das entidades e das atualizações de rede, sem alterar a quantidade de invocações.

Também permanecem pendentes o arquivo real da fonte Kingdom e a avaliação humana de equilíbrio, desvio com latência e duração dos novos encontros. O túnel temporário foi encerrado. Na conferência final, relay e túnel estavam desligados; a revisão automática bloqueou a tentativa de reabri-los com o motivo "blocked by policy". A publicação não inclui um endereço público ativo. O código cooperativo e a configuração externa por `network.cfg` foram preservados; é necessário um serviço WSS ativo para conectar redes diferentes. A ausência de configuração apresenta uma mensagem imediata de indisponibilidade.
