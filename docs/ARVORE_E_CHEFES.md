# Brasafria 0.3.0

## Árvore permanente

São 16 nós em quatro ramificações. A interface é provisória: dados, compra e aplicação estão separados do desenho. As referências visuais futuras poderão substituir `SkillTreeView` sem alterar as compras ou o salvamento.

| Ramo | Nó | Custo por nível | Efeito total por nível | Exige |
| --- | --- | --- | --- | --- |
| Combate | Aço temperado | 12 / 24 | Dano +6% / +12% | Nada |
| Combate | Ritmo de ferro | 26 / 42 | Intervalo de ataques -5% / -10% | Aço 1 |
| Combate | Fenda na guarda | 40 / 65 | Crítico 5% / 10%; dano crítico 160% | Ritmo 1 |
| Combate | Passo decisivo | 100 | Mover 48 px prepara crítico; intervalo de 4 s | Fenda 1 |
| Sobrevivência | Vigor da vigília | 12 / 24 | Vida +15 / +30 | Nada |
| Sobrevivência | Malha recuperada | 26 / 42 | Defesa +1 / +2; dano mínimo recebido 1 | Vigor 1 |
| Sobrevivência | Fôlego teimoso | 40 / 65 | Após 4 s sem dano, cura 1 / 2 a cada 6 s | Malha 1 |
| Sobrevivência | Última centelha | 120 | Uma morte evitada por partida; 15 de vida e 2 s de proteção | Fôlego 1 |
| Movimento | Passo do exílio | 12 / 24 | Velocidade +6 / +12 | Nada |
| Movimento | Chamado do ouro | 26 / 42 | Raio de coleta +14 / +28 | Passo 1 |
| Movimento | Passo entre ruínas | 50 | Moedas atraídas 60% mais rápidas entre hordas | Chamado 1 |
| Movimento | Coletor de brasas | 90 | Dez moedas curam 3 de vida, uma vez por horda | Passo entre ruínas 1 |
| Especialização | Contraguarda | 50 | Arco traseiro da espada desde o nível 1, sem duplicar o arco normal | Aço 1 |
| Especialização | Ponta partida | 50 | Virote atravessa um inimigo adicional | Passo do exílio 1 |
| Especialização | Brasa desperta | 50 | Uma brasa orbital adicional | Chamado do ouro 1 |
| Especialização | Pacto das três | 120 | Quarta vaga de passiva ao equipar as três armas | As três especializações |

Os valores de múltiplos níveis são totais, sem crescimento ilimitado. As habilidades não substituem as melhorias temporárias da partida. Regeneração, proteção de morte e cura por coleta possuem limites próprios.

A interface mostra conexões, saldo, nível, próximo efeito e estados bloqueado, disponível, sem ouro, comprado e maximizado. Mouse seleciona e compra pelo painel; setas navegam; Espaço compra; Esc volta. O botão guarda o nível que foi exibido, impedindo cobrança repetida de um botão antigo.

Compra só ocorre fora da expedição. A gravação é imediata; falha de gravação reverte ouro e nível. O perfil versão 3 aceita versões 1 e 2, preservando os dados existentes e iniciando a árvore vazia. Bônus são reconstruídos sobre os atributos básicos a cada nova partida, sem acúmulo em reinícios.

## Carrasco

Chega aos 300 segundos de partida, com surgimento fora da câmera. O encontro final espera sua derrota quando necessário. A vida anterior era 312; o multiplicador 3 resulta em 936. Velocidade de perseguição 64, maior que os inimigos comuns e menor que os 96 da sentinela básica.

Alterna execução e investida. Execução: preparação de 1,1 s, acompanhamento apenas nos primeiros 0,62 s, direção então travada, alcance 88 e dano 28. Investida: preparação de 1 s, direção travada depois de 0,45 s, avanço 210 por até 0,72 s, dano 25 e recuperação de 1,1 s. Abaixo de 50%, o intervalo cai de 1,8 para 1,3 s e a perseguição ganha 6% de velocidade. Não existe ajuste de vida conforme o poder do jogador.

## Demônio

O Devorador de Brasas é uma criatura original de 96x96 pixels, com asas rasgadas, chifres, garras e núcleo em brasa. Possui 12 frames para marcha, preparações distintas e morte. O Carrasco usa oito frames de 48x64.

Mantém a chegada na horda 10. A composição normal dessa horda foi substituída pelo encontro, conforme o pedido de suspender reforços normais. As nove hordas anteriores contêm 588 inimigos; com Carrasco e demônio, são 590 encontros programados, mais as invocações limitadas do demônio.

A vida inicial é duas vezes a do novo Carrasco: 1.872. O multiplicador fica em `data/bosses/balance.tres`. A perseguição usa velocidade 70.

Entrada no centro (900,630): pentagrama acende por 1,2 s; portal abre em 0,9 s; emergência dura 1 s; fechamento dura 0,6 s. Duração total 3,7 s. O jogador conserva movimento e não sofre dano de aparição. O chefe não recebe dano nem é alvo durante a entrada. Após fechar o portal, ganha controle com uma breve margem antes de atacar.

Fase 1, acima de 70%: perseguição, leques de fogo, invocação e investida. Fase 2, até 70%: introduz raios e gelo. Fase 3, abaixo de 35%: intervalos menores, ataques alternados e segundo leque defasado. As transições usam a vida restante; builds fortes podem atravessar uma fase rapidamente.

Invocação sinaliza pontos por 1 s e usa zumbis, espadachins e arqueiros existentes. Vivos e pontos pendentes dividem o limite de 14. Pontos próximos do jogador ou inválidos são rejeitados. Se o jogador entrar sobre um ponto sinalizado, a aparição é adiada ou cancelada.

Fogo: leques de 5, 6 ou 7 projéteis; fase 3 adiciona seis após 0,4 s. Separação angular 0,34 rad, velocidade inicial 135, dano 15, duração de 5 s. Limite de 72 bolas de fogo e 120 projéteis hostis totais na luta. Cenário bloqueia os projéteis.

Raios: três marcas, ou quatro na fase 3, travadas antes do impacto. Aviso de 1,1 s, raio 24 e dano 23. O posicionamento deixa uma direção de fuga. Gelo: duas áreas afastadas 78 px do centro do jogador, raio 36, formação de 0,85 s e duração de 4 s. Reduz movimento a 68%, sem congelar. Um corredor central permanece aberto.

O controlador recusa gelo enquanto houver raios e recusa raios enquanto houver gelo ou outro conjunto de raios. Não dispara todos os poderes juntos. Investidas mantêm a direção travada e possuem recuperação.

Na morte, ataques e avisos pendentes são cancelados, projéteis e áreas são removidos e invocações são retiradas sem recompensas adicionais. A morte animada dura 1,5 s; depois vem a vitória. Bônus únicos de conclusão: Carrasco 30 de ouro, demônio 120. São separados das moedas e passam pela liquidação única da partida. Derrota e reinício também limpam portal, efeitos, invocações e lentidão.

## Modo de desenvolvimento

F9 fora da partida abre o laboratório. Os arquivos `Testar_Carrasco.cmd` e `Testar_Demonio.cmd` oferecem acesso direto. A build do Carrasco usa as três armas nível 4; a do demônio usa três armas evoluídas nível 5. Passo, Selo e Ímã estão no nível 2. Habilidades permanentes são desativadas para comparação consistente. O modo não concede ouro ou selos permanentes. Reiniciar repete o chefe escolhido.

## Arquivos de ajuste

- `data/skills/catalog.tres`: nós, custos, níveis, efeitos e pré-requisitos.
- `scripts/progression/`: regras de compra e efeitos durante a partida.
- `scripts/ui/skill_tree_view.gd`: layout provisório e navegação.
- `data/bosses/balance.tres` e `scripts/data/boss_balance.gd`: vida, velocidades, dano, tempos, limites e multiplicadores.
- `scripts/bosses/horde_boss.gd`: estados e alternância de ataques.
- `scripts/bosses/boss_arena.gd`: portal, controlador de poderes, invocações e limpeza.
- `tools/generate_bosses.py`: arte original editável dos chefes. O antigo `boss.png` foi preservado como material anterior e não representa o novo encontro.

## Validação executada

Em 3 de novembro de 2026, Godot 4.7.2, Windows x64:

- Árvore e chefes: 2.100 verificações, zero falhas. Compra e pré-requisitos, nível máximo, saldo não negativo, botão antigo, reversão de gravação inválida, persistência, migração, aplicação única, compra por Espaço, efeitos especiais e limpeza.
- Desvio do Carrasco exercitado com movimento e frames reais de física, sem invulnerabilidade nesses casos. Foram confirmados o acompanhamento breve, o travamento da direção e a recuperação da investida.
- Portal completo, proteção durante a entrada, movimento livre, três fases, leques, avisos fixos de raio, gelo temporário, rotas abertas, limites de invocação e bloqueio das combinações de áreas.
- Vitória normal salva ouro e recarrega o mesmo saldo. A repetição do resultado não paga novamente. No laboratório, o saldo permanece inalterado.
- Ensaio de duração com bot invulnerável, frames reais e tempo acelerado 4x: Carrasco 9,72 s com armas nível 4; demônio 17,95 s com armas evoluídas nível 5. Nenhuma habilidade permanente. Isso mede a duração sob dano sustentado, não a dificuldade para uma pessoa.
- Fase intensa: 480 frames de física, limite de 72 bolas de fogo, 120 projéteis e 14 invocações vivas ou pendentes. Áreas permaneceram no orçamento e gelo não coincidiu com raios. Tempo registrado é de CPU em headless, sem promessa de FPS renderizado.
- Regressões: 341 verificações de integração, 639 de hordas e ouro, 224 de armas, mais smoke de interface. O bot invulnerável percorreu as dez hordas com 590 abates programados e vitória.
- Capturas do viewport foram inspecionadas para árvore, preparação do Carrasco, etapas do portal, poderes, morte e resultado. O portal foi corrigido para ficar abaixo do corpo do demônio.
- Executável independente abriu no smoke headless de 120 frames, saída 0. O pacote embutido também passou nas 2.100 verificações usando o runtime de editor da mesma versão e `--main-pack`.

Total funcional: 3.304 verificações entre as quatro suítes, além de layout e inspeção visual. Comandos reproduzíveis em `tests/README.md`.

## Pontos pendentes

O layout da árvore aguarda as referências visuais. O equilíbrio ainda precisa de partidas humanas sem invulnerabilidade; os tempos do bot são referência de dano, não uma garantia de dificuldade. Sons sintetizados exigem avaliação auditiva. Controle físico e outras máquinas continuam sem teste. As animações têm poses próprias, mas não um conjunto completo de oito direções.
