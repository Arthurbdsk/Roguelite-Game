# Interface, coleção e consumíveis 0.15.0

## Implementado

Tema compartilhado azul-acinzentado, bordas douradas finas, seleção clara, ícones em fundo escuro e botões principais verdes. Fonte preservada. Coleção no menu inicial com os 12 armamentos, oito passivas e cinco consumíveis reais: 25 entradas, sem espaços de conteúdo inventado. O painel fixo mostra efeito e compatibilidades; a grade pode rolar. Descobertas ficam no campo adicional `discoveries` do perfil v4, sem alterar ranks, saldo, desbloqueios ou o formato dos dados antigos. Perfis antigos começam descobrindo itens conforme os recebem ou equipam. Testes DEV não salvam descobertas no perfil real.

Cinco desenhos originais em RGBA 32×32, feitos no pipeline de pixel art do projeto e inspirados nas referências: amuleto verde, frango, bolsa, ímã e relógio. Sem fundo branco, texto ou marca. Gerador editável: `tools/generate_consumables15.py`. Interface usa nearest, preserva proporção e compartilha as texturas com o chão.

| Consumível | Efeito |
|---|---|
| Comida | Até 30 de vida apenas ao coletor vivo. Não consome com vida cheia. |
| Bolsa de Ouro | 100 base compartilhados pelas regras atuais; cada bônus individual aplicado uma vez. Feedback mostra o valor efetivo do coletor. |
| Ímã de Experiência | Reserva os cristais presentes na ativação. Processa no máximo 96 por passo, preservando frações e os bônus existentes. Até 48 representações visuais compartilhadas; a experiência de todos os objetos continua contabilizada. Cristais criados depois não entram nessa coleta. |
| Relógio | Dez segundos para comuns, especiais, preparações e seus projéteis; afeta também novos comuns durante o efeito. Renova para dez, sem soma. Chefes recebem apenas 30% de desaceleração por três segundos; fases continuam. |
| Limpeza | Mortes reais e recompensas únicas na região lógica visível do coletor. Preserva chefes e alvos destrutíveis de ataques dos chefes; suprime divisões causadas por essas mortes. Remove projéteis da região. |

Host confirma proximidade, consumo e efeitos. Somente um coletor pode consumir cada objeto. Estado de chão, congelamento e representação limitada do Ímã seguem nos snapshots; feedback é evento separado. Clientes não aplicam dano, ouro ou XP por conta própria. O Devorador continua usando apenas os índices de moedas e cristais; os consumíveis não entram neles.

No DEV, aba Consumíveis: gerar os cinco tipos, limpar os itens, vida cheia/25%, 500 cristais e grupo de slimes/necromantes. A aba Desempenho mostra chance, próxima tentativa, quantidade, tempo do Relógio e cristais pendentes. Os controles de chefes existentes permitem testar fases com Relógio.

## Parâmetros e frequência

Dados centralizados em `data/consumables.json`: primeira tentativa aos 60 s, intervalo 30 s, chance-base 15%, cooldown 60 s, limite dois no chão, validade 90 s, piscada nos últimos dez. Sorte adiciona dois pontos percentuais por rank, até 21%; no cooperativo usa a média dos ranks conectados. O efeito anterior da quarta opção permanece.

Pesos: Comida 40, Bolsa 20, Ímã 20, Relógio 12, Limpeza 8. Não há sorteio por morte, nem geração para responder a dano. Tentativas durante congelamento são suspensas e não acumulam. Posições alternam os jogadores vivos e exigem chão livre e navegável.

200 sementes por cenário de vinte minutos, usando RNG e scheduler reais, mapa sem combate, passos de 30 segundos:

| Sorte | Itens retirados na aparição | Itens deixados até expirar |
|---|---:|---:|
| 0 | 4,98 aparições | 4,98 aparições |
| 3 | 6,82 aparições | 6,82 aparições |

Sem Sorte: 996 aparições nas 200 sementes, sendo 412 Comidas, 195 Bolsas, 204 Ímãs, 104 Relógios e 81 Limpezas. Os cenários de retenção coincidiram: com cooldown de 60 s e validade de 90 s o limite de dois não bloqueou a tentativa seguinte. A simulação não inclui combate, bloqueios móveis nem o uso real de Relógios. Não é renda ou frequência comprovada em partidas humanas.

## Execução e testes

- Comida cheia/baixa, cura exata, pausa, validade, duas coletas do mesmo objeto rejeitadas.
- Bolsa com bônus de 25% produz 125, sem pagamento duplicado; regras de ouro normal e devolução preservadas.
- Ímã mantém XP fracionária, exclui cristais posteriores e preserva o compartilhamento que já concede a base integral a cada participante online.
- Limpeza de slime e necromante, ausência de divisão, inimigo distante preservado. Relógio durante preparação, projétil parado, novo inimigo congelado, dano recebido durante congelamento, renovação e chefe apenas desacelerado.
- Perfil salvo e reaberto com descobertas e saldo preservados. Coleção renderizada em 640×360, 480×360 e 800×450; painel fixo sem sobrepor rolagem. Capturas em `test_output/15-collection-*.png`.
- Quatro processos separados verificam coletor remoto, disputa, ouro compartilhado/individual, estado congelado, limpeza, chão e 500 cristais com valor exato. O teste DEV confirma o arquivo original do perfil intacto.
- Regressões: colisões nos três mapas e gelo, geração contínua, campanha, fases, baús, preços/reembolso, XP e ouro antigos, painel DEV e pacote público sem F8.

Teste renderizado de carga no Godot 4.7.2, Ryzen 5 5600/RX 6600, Compatibility, viewport 640×360, quatro atores, seis armas nível 8, 200 inimigos físicos e 3.000 cristais. Fixture mantém inimigos vivos para medir carga; não altera dados distribuídos. 180 frames medidos: frame mediano 16,69 ms, p95 17,21 ms, p99 24,52 ms. Lote de Ímã mediano 0,368 ms, p95 0,693 ms, p99 1,086 ms. Depois da amostra, drenagem acelerada de teste confirmou exatamente 375 de XP-base e zero objetos pendentes. Não representa FPS comprovado da exportação release nem teste de quatro máquinas; não se afirma 60 FPS constantes.

```powershell
python tools/validate_dev11.py consumables15 consumable_frequency15
Godot_v4.7.2-stable_win64_console.exe --path . --script tests/collection15.gd -- --self-test
Godot_v4.7.2-stable_win64_console.exe --path . --script tests/load_consumables15.gd -- --self-test
node relay/match-test.mjs --survival --harness=tests/consumables_network15.gd
```

## Limites

O balanceamento da frequência ainda precisa de partidas humanas. O Ímã representa visualmente grupos grandes e pode demorar para terminar coleções enormes, mas não cria nem perde XP. O relay gratuito continua sujeito a suspensão, reinícios e limites do Render. Não foi repetida uma sessão pública de trinta minutos nem validada esta versão em quatro máquinas/redes distintas. Vida, dano, resistência, curva de XP e preços não foram modificados nesta atualização.
