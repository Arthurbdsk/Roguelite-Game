# Hordas 0.13.0

## Implementado

- Inimigos com colisão física entre corpos, modo flutuante para movimento em duas dimensões, separação e restrição de aproximação. Busca espacial em células de 16 px para corpos; grade de 40 px preservada para armas. Surgimento procura posições livres e evita jogadores. Não há reposicionamento visível para resolver congestionamento. Devorador adia crescimento físico/visual se o novo corpo não couber; vida e ataque continuam recebendo seus bônus. Shadow não bloqueia corpos enquanto desaparecido.
- Geração contínua desde o início, sem esperar eliminar grupos. Taxa-base solo de 48 surgimentos por minuto, preparação inicial de 2,5 s. Estágio = piso(tempo simulado / 120). Taxa = 48 × (1 + 0,10 × estágio) × modificador existente de quantidade multiplayer/Desafio, aplicado uma vez.
- Por estágio: +35 de vida máxima e atual, preservando o dano recebido, e +5 pontos percentuais de resistência até 75%. Vida e taxa continuam crescendo depois do teto. O estágio também atualiza inimigos vivos. Catálogo antigo de hordas permanece como recurso histórico, sem participar da geração ou da dificuldade.
- Composição: zumbis e cães inicialmente; espadas aos 60 s; arqueiros e guardas aos 120 s; slimes grandes e Devoradores aos 180 s; demais especiais aos 240 s. Participação dos especiais cresce 6% por estágio sobre seus pesos, até +200%. Comuns continuam predominantes.
- Limite normal de 240 inimigos e orçamento de 420 para divisões/eventos. Dívida de surgimentos não é descartada. Divisões têm prioridade e filas quando falta capacidade ou posição livre. Invocações aguardam espaço. Chefes preservam seus horários e suas regras específicas de geração.

## Infinito e vitória

A escolha aparece após a morte definitiva da True Form, com tempo, ouro, build e nível preservados. Encerrar liquida uma vitória; continuar retoma a geração e o relógio atuais, sem repetir a campanha. Vencer a campanha é registrado antes da animação final terminar. Morrer depois no infinito continua contando como vitória da campanha, com uma única liquidação de ouro por sessão.

No multiplayer, todos os participantes conectados precisam concordar. Um voto contrário encerra com vitória; falta de resposta por 30 segundos também encerra. Participante desconectado sai da votação. Clientes não podem iniciar ou resolver o encontro sozinhos. Permanecem seis armas, quatro passivas, oito níveis e as alternativas de cura/ouro ao maximizar a build.

## Eventos sem anúncio

Sorteio único a cada 60 segundos, a partir de 180 segundos: 15% de cerco, 10% de Rei, 75% de nenhum. Nunca começam durante chefes, transições ou decisão do infinito. Não são simultâneos. Há pelo menos 180 segundos de intervalo depois do evento anterior terminar. Pausa solo interrompe os temporizadores; menus individuais online não interrompem.

Cerco: vinte arqueiros, centro fixo num jogador vivo, raio nominal 420 px adaptado ao terreno. Vida exatamente quatro vezes a de um arqueiro normal na mesma dificuldade, intervalo atual +2 s, alcance de ataque 700 px, flechas com alcance 760 px e vida 6 s. Preparação de 0,75 s preservada e primeiros disparos alternados. Não perseguem, exibem detalhe dourado e podem morrer normalmente. Aos 45 segundos, sobreviventes somem com fade de 0,35 s e suas flechas são removidas, sem recursos por desaparecimento. Quantidade não é multiplicada pelo multiplayer.

Rei: sprite verde próprio, oito quadros de 72x72, corpo de raio 32 px, vida-base oito vezes a do Slime grande e velocidade-base 70% dele. Cada morte produz exatamente quinze azuis; cada azul produz quinze pequenos. Azuis têm 50% da vida máxima do Slime grande normal na dificuldade atual. Pequenos têm duas vezes a vida e velocidade 25% maior que os pequenos normais, com o mesmo dano baixo. Frações e modificadores são preservados, sem aplicar a escala novamente em cada geração. Os pequenos não se dividem.

A cadeia completa possui 1 Rei, 15 azuis e 225 pequenos. As divisões usam fila e 0,5 s de proteção antes do dano de contato. O orçamento da família é 20 de ouro-base e 120 de XP bruto, que resulta em 90 de XP após a redução base vigente de 25%, antes dos bônus individuais. Distribuição: Rei 5 de ouro e 15 XP brutos; cada azul 1 de ouro e 1 XP bruto; cada pequeno 0 de ouro e 0,4 XP bruto. O ouro/XP comuns dessas variantes são substituídos pelo orçamento, não somados novamente. O evento só termina quando toda a família e todas as filas terminarem.

## Baús

Arte própria inspirada na referência do usuário, com quatro quadros transparentes e filtro nearest. Primeiro sorteio aos 120 s, depois a cada 30 s elegíveis, com intervalo mínimo de 90 s após gerar e no máximo um fechado. Baú permanece até abrir ou encerrar a sessão. Chefes e transições bloqueiam sorteios; tentativas bloqueadas não acumulam.

A chance inicial de 25% deu média de 5,3345 baús em 2.000 partidas simuladas de vinte minutos. Foi ajustada para 21%, resultando em média de 4,7015, mínimo 0 e máximo 9. Simulação do agendador real, com 195 s de bloqueios por chefes e recolhimento entre 15 e 90 s. Não existe limite obrigatório de cinco. A renda e frequência humanas dependem da duração real dos chefes e de abrir os baús.

E abre perto do baú. Reanimação de aliado no mesmo alcance tem prioridade. O host valida proximidade e aplica a abertura uma vez. Valor-base inteiro uniforme entre 50 e 200, igual para todos os conectados, com bônus individual de Ouro aplicado uma vez e frações preservadas. Cada participante recebe, com chances iguais, um nível em um dos seus itens equipados abaixo do nível 8. Não recebe item novo ou outro espaço. Sem item elegível, recebe só ouro e a mensagem “Todos os itens estão no nível máximo”. A apresentação informa item, níveis e ouro, sem bloquear movimento nem pausar a partida online.

## Modo DEV

F8 na build DEV, aba Contínuo:

- Iniciar teste contínuo ou diretamente no infinito.
- Ajustar tempo ou estágio.
- Forçar cerco, Rei ou baú.
- Ver estágio, resistência, vida adicional, taxa/minuto, entidades, dívida e adiamentos.
- Ver evento, tempo do cerco, família viva e lotes pendentes.
- Mostrar colisores e limpar eventos.

O painel usa os sistemas reais com perfil temporário. O executável público exclui painel, presets e scripts de desenvolvimento. Encerrar o modo restaura o perfil original.

## Validação executada

- body_collision13: 65 corpos de tamanhos variados em cada um dos três mapas, 90 passos físicos; nenhuma sobreposição acima da tolerância de 0,7 px. Mais quarenta perseguidores contra parede de gelo ativa, sem penetrar a parede.
- continuous13: limites 119,999/120 s, vida/resistência, estágio sem repetição, teto e taxa aditiva; geração mesmo com sobreviventes e adiamento por capacidade sem perda da dívida.
- campaign13: horários exatos de 5/10/15/20 minutos, fases reais, bônus fixo aplicado uma vez, escolha somente após True Form e geração retomada no infinito.
- endless13: continuidade da build/tempo/nível/ouro, vitória após derrota posterior, persistência e liquidação única, timeout.
- voting13: participantes válidos, voto único, rejeição de remetente inexistente, veto e vitória.
- events13 e event_scheduler13: sorteio uma vez por período, bloqueios, cooldown, cerco completo/expiração, cadeia completa e orçamento de recursos.
- chests13 e chest_frequency13: item existente, limite 8, bônus individual, abertura única, fallback maximizado, pausa e 2.000 sessões simuladas.
- dev_survival13, dev_encounters13, dev_attacks13 e dev_panel11: controles, isolamento do save, dezoito combinações de mapa/encontro, 46 ataques e transições.
- Regressões de XP/ouro, gastos históricos/reembolso, progressão, seis/quatro espaços, armas, Devorador e rede.
- Renderização real: Rei, baú fechado/aberto, resultado e painel inspecionados na arena.
- Quatro processos em relay local: melhorias e ouro individuais, prioridade da reanimação, 15 azuis e 225 pequenos, 225 corpos em movimento, cerco e flechas, votação após desconexão e saves originais preservados.
- Segunda suíte de quatro processos no modo normal: movimento, escala, escolhas individuais sem pausa, recursos compartilhados, reanimação, saída de participante, derrota coletiva e liquidação persistida.

## Desempenho observado e limites

Ryzen 5 5600, Radeon RX 6600. No teste de quatro processos e 225 corpos em movimento por 180 passos, CPU mediana caiu de 32,77 ms para 13,77 ms e p95 para 22,94 ms após separar a grade física fina. Sem sobreposições persistentes no resultado. Esse teste de sockets foi local.

Teste renderizado com quatro atores locais, seis armas no nível 8 cada, 225 pequenos e pico de 120 poças: 240 passos em 3,98 s, CPU mediana 12,62 ms, p95 23,37 ms e desenho médio 16,9 FPS. Portanto, o caso extremo ainda apresenta quedas fortes de renderização. Não foi reduzida silenciosamente a quantidade de filhos ou de inimigos para melhorar o resultado.

Ainda falta validação humana da campanha/infinito, legibilidade com quatro pessoas e balanceamento de criaturas muito rápidas. Os pequenos do evento preservam o aumento de 25% pedido e podem ultrapassar a velocidade de personagens sem Botas. Não há alegação de 60 FPS constantes ou de validação pela internet. O serviço público de salas continua sem endpoint configurado nesta publicação.

## Dados editáveis

- data/survival.json: geração, eventos, atributos das variantes, recompensas e baús.
- scripts/data/encounter_balance.gd: intervalo dos estágios e limites existentes.
- assets/v13/: atlas finais; produção e prompts em SOURCES.md e sources/.
- scripts/world/director.gd, special_events.gd e reward_chests.gd: sistemas de execução.
- scripts/bosses/late_campaign.gd: escolha e votação do infinito.
- scripts/dev/: painel e visualização exclusivos de desenvolvimento.

Saves continuam v4. Saldos, compras históricas e desbloqueios preservados. Nenhuma nova raridade de itens ou frango frito foi adicionada.
