# Aprimoramentos permanentes 0.9.0

A árvore foi substituída por 16 aprimoramentos independentes. A interface usa os ícones anexados em sua ordem, a fonte existente, cards cinza, fundo azulado, bordas douradas e painel inferior fixo. Quatro colunas em 640 pixels; três abaixo de 590 e duas abaixo de 440. A grade rola sem mover os detalhes. O texto dos cards maximizados e os indicadores preenchidos mostram o limite.

Código editável: `scripts/ui/skill_tree_view.gd`. Custos, limites, textos e ícones: `data/permanent.json`. Sprites fornecidos pelo usuário copiados diretamente para `assets/permanent`, preservando sua pixel art e o fundo azul interno da referência. Não há preço ou indicadores adicionados aos PNGs. O importador opcional `tools/permanent_catalog.py` documenta a correspondência dos 16 arquivos.

## Valores e custos

| Aprimoramento | Por nível | Limite | Preços por nível, em ouro |
|---|---|---|---|
| Dano | +5% | 5, +25% | 10, 25, 50, 90, 150 |
| Armadura | -3% após defesa fixa | 5, -15% | 10, 25, 50, 90, 150 |
| Vida máxima | +5% | 5, +25% | 10, 25, 50, 90, 150 |
| Regeneração | +0,1 vida/s | 5, 0,5/s | 10, 25, 50, 90, 150 |
| Recarga | -2% de intervalo | 5, -10% | 10, 25, 50, 90, 150 |
| Área | +5% de área | 5, +25% | 10, 25, 50, 90, 150 |
| Velocidade dos projéteis | +5% | 5, +25% | 10, 25, 50, 90, 150 |
| Duração | +5% | 5, +25% | 10, 25, 50, 90, 150 |
| Quantidade | +1 projétil | 1 | 250 |
| Movimento | +3% | 5, +15% | 10, 25, 50, 90, 150 |
| Coleta | +10% de raio | 5, +50% | 10, 25, 50, 90, 150 |
| Sorte | +10 pontos percentuais de quarta opção | 3, 30% | 25, 60, 120 |
| Experiência | +2% | 5, +10% | 10, 25, 50, 90, 150 |
| Ouro | +5% | 5, +25% | 10, 25, 50, 90, 150 |
| Desafio | +5% vida, dano e quantidade inimiga | 5, +25% | 10, 25, 50, 90, 150 |
| Reviver | 40% da vida, 2 s de proteção | 1 uso/partida | 300 |

A medição em execução eliminou e coletou integralmente os inimigos das três primeiras hordas sem bônus: 12, 21 e 34 moedas, total de 67. São ganhos coletáveis no teste automatizado, não uma média de partidas humanas. O primeiro nível custa menos que uma primeira horda completa; os níveis seguintes e os aprimoramentos de alto impacto exigem mais hordas ou tentativas. Um aprimoramento regular completo custa 325. Quantidade custa 250; Reviver, 300. O ritmo da economia ainda deve ser avaliado por jogadores reais. A curva-base de experiência não foi alterada.

## Regras de integração

Os valores permanentes são capturados no início de cada partida. Não ocupam espaços e não se reaplicam em trocas de mapa. O painel de build inclui os atributos finais e os bônus permanentes.

Armadura: dano recebido = máximo entre 20% do dano original e `(dano original - defesa fixa) × (1 - redução permanente)`. Assim, o limite combinado é 80% de redução, inclusive para veneno. Regeneração usa ponto flutuante por segundo e para quando caído. Recarga respeita 0,15 s de intervalo mínimo.

Área multiplica o raio por `sqrt(1 + bônus)`, pois a área é proporcional ao quadrado do raio. Afeta Espada, Lodo, Água Benta, Bombas e Onda de Gelo. Não altera alcance de seleção do Raio, coleta ou controle da Lança Relógio. O bônus anterior da Lupa conserva sua regra própria.

Velocidade afeta Arco, Machado, Bumerangue e o voo de frascos e bombas. Destinos, alcance e perfuração são preservados. Bombas podem chegar antes, mantendo o instante de detonação. Duração beneficia Lodo, Água Benta e a lentidão da Onda de Gelo; o limite de lentidão de chefes é preservado. Quantidade beneficia Arco, Machado, Bumerangue, Bombas e Água Benta.

Sorte realiza um único sorteio por seleção. O teste com semente fixa gerou 284 quartas opções em 1.000 seleções com 30%. As opções continuam únicas, respeitam níveis e espaços; a lista de escolhas rola quando necessário. Teclas 1 a 4 selecionam.

Experiência soma com a Coroa e conserva frações. Ouro acumula frações por jogador e salva o restante para a próxima partida. O ouro base continua compartilhado no cooperativo; cada jogador recebe seu próprio bônus sobre a base compartilhada. Recursos consumidos pelo Devorador ainda não tinham sido coletados: recebem o bônus uma única vez quando finalmente coletados após a devolução. Reembolsos de compras não passam pelo bônus.

Desafio pode ser ativado de zero até o nível comprado. No cooperativo é escolhido pelo criador no lobby, visível para todos e limitado pelo nível do criador. Não soma aprimoramentos de participantes. Vida, dano e quantidade das hordas recebem o fator uma vez, junto aos fatores já existentes. Velocidade não muda. Invocações especiais dos chefes mantêm suas quantidades próprias.

Reviver abre uma escolha antes da derrota no solo e preserva a build. Online, use R quando caído ou o botão no menu individual. O host valida e consome uma vez; a reanimação por aliado não consome esse uso. A derrota da equipe aguarda enquanto algum jogador conectado ainda pode retornar. O pedido remoto é tratado ao chegar, evitando que outro pacote de movimento o substitua.

## Salvamento e migração

Formato 4, com níveis, livro de gastos, revisão de operações, Desafio selecionado e fração de ouro. O save pessoal foi copiado para `profile.json.pre_upgrades_v4.bak` antes da substituição. O carregador também cria esse backup quando necessário, antes de migrar. Saldo, desbloqueios, preferências e campos adicionais são preservados.

Equivalências, arredondadas para um efeito novo próximo sem exceder os limites: Dano antigo níveis 1/2 vira Dano 1/2; Intervalo vira Recarga 2/5; Vigor vira Vida máxima 3/5; Botas vira Movimento 2/4; Ímã vira Coleta 3/5. O preço contabilizado dessas conversões é o gasto histórico, não o custo atual dos níveis concedidos. Isso permite um reembolso exato posterior, sem gerar ouro pela diferença de tabelas.

Os demais efeitos antigos são incompatíveis e são reembolsados. Se existir `skill_spent`, seu valor registrado prevalece. No formato antigo existente esse campo não era gravado: usa-se a soma dos preços históricos preservados em `data/skills/catalog.tres`. IDs antigos desconhecidos permanecem no registro legado; não se inventa reembolso para preços desconhecidos. A migração só acontece para versões anteriores a 4. Saves já migrados não ganham crédito novamente.

Comprar e reembolsar são operações com rollback em caso de falha de gravação. Compras verificam o nível esperado, limite e saldo. A interface bloqueia o segundo clique rápido. O reembolso pede confirmação e verifica a revisão antes de devolver o livro de gastos e apagar os níveis. O bônus de Ouro não interfere.

O backup permite retorno à versão anterior. Evite usar um executável antigo sobre o perfil já migrado, pois o formato 4 não era conhecido por ele.

## Validação executada

- Migração de save de teste, backup, segundo carregamento sem duplicação, livro de gastos e reembolso exato.
- Compra pelos botões, bloqueio do segundo clique, confirmação de reembolso, seleção, rolagem e detalhes fixos; renderização com quatro e duas colunas.
- Atributos máximos, redução global, regeneração fracionária, área pela raiz quadrada, quantidades compatíveis, duração, velocidade e reinício sem acumular bônus.
- Experiência somada à Coroa, ouro fracionário e restauração da fração pelo save, Sorte, Reviver uma vez no solo.
- Quatro processos de jogo: aprimoramentos individuais, Desafio do criador, retorno remoto autorizado e ouro individual salvo. Repetido após corrigir a disputa entre pedido de retorno e pacote de movimento.
- Regressões de limites, oito níveis, defesa, Devorador, quinze slimes, poças, chefe em duas fases e animações.
- Carga renderizada: quatro contextos locais com aprimoramentos máximos, seis armas por personagem, 240 inimigos incluindo Necromantes e invocações, 2.000 moedas, 240 cristais, 320 flechas e poças. Aproximadamente 32,6 FPS na máquina de desenvolvimento; não é teste com quatro pessoas em redes distintas.

Limitações: economia ainda sem amostra de partidas humanas; carga extrema abaixo de 60 FPS; transporte online depende do relay/túnel ativo. Como os perfis são locais e não há contas nem servidor de progressão, o host deriva os atributos de níveis limitados e validados, mas não pode provar criptograficamente que um perfil local não foi editado. A explosão nova da remodelação anterior permanece pendente e não integra esta mudança de aprimoramentos.
