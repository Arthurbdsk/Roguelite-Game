# Correções PC 0.23.0

Somente PC, baseado na 0.22.0. Android não foi atualizado, sincronizado, testado ou compilado.

## Diagnóstico e mudanças

Não foi reproduzido desconto duplo de cooldown na simulação medida. Solo chama a atualização uma vez por passo e retorna antes dela quando o cooperativo está ativo; o host atualiza cada dono uma vez, e clientes reproduzem os efeitos sem decidir dano. Recarga usa o valor-base, multiplicador das Luvas e permanente sem modificar o recurso acumulativamente. Luvas 8 deixam 52% do intervalo e Recarga permanente máxima deixa outros 90%, resultando em 46,8% do intervalo-base. Sequências da Varinha Mágica usam 120 ms entre projéteis, independentemente da ativação. A percepção de alta cadência não comprovou uma aceleração global indevida. Os cooldowns gerais foram preservados.

[Medições](fixes23/frequencias.md): passo de 1/60 s, 30 segundos simulados por combinação, níveis 1/8, sem bônus e com Luvas 8/Recarga permanente 5. Existem 52 combinações com ativações mensuráveis. Alho, esfera orbital e rastro de Lodo usam modelos contínuos/periódicos próprios, sem ativações equivalentes nesta instrumentação. Não confundir contagem de rajadas com contagem de projéteis. Os resultados brutos anteriores e posteriores estão na mesma pasta. O primeiro sinalizador PASS indica execução do ensaio, não comprovação de ausência de todos os bugs.

Flechas remotas eram enviadas apenas com posição e velocidade, sem identidade e limite de vida visual. Foram adicionados ID monotônico, idade e vida derivada do voo; os clientes removem réplicas expiradas mesmo antes de outro snapshot. IDs não são reiniciados em reset. O host continua encerrando por colisão varrida, perfuração, parede e distância de voo. Arrays de snapshots substituem integralmente as réplicas. Não existe pool de objetos de flecha a devolver: são registros em arrays. Não foi reproduzida uma flecha solo presa após colisão nos testes executados. O tratamento de Runa e Bumerangue foi preservado.

A afirmação inicial de que o cliente não movia machados estava incorreta; o trecho completo já atualizava sua posição. O problema confirmado do Machado era seu descarte por tempo de voo curto, além de começar com apenas dois acertos herdados do valor padrão. Agora tem totais explícitos de acertos `[3,3,4,4,5,5,6,7]`, sem repetir inimigo, mantendo o arco até gastar perfuração ou sair completamente da câmera lógica atual do dono. Margem de descarte 14 px; desenho 16 → 18,4 px e raio de contato 5 → 5,75 px. Sem alteração no dano ou frequência do Machado.

Varinha Mágica: bases `[1,1,0.85,0.85,0.85,0.85,0.85,0.85]` → `[2,2,1.85,1.85,1.85,1.85,1.85,1.85]` segundos antes de Recarga. Espaçamento da sequência preservado.

Fogo aliado: dano `[33.6,38.4,43.2,48,52.8,57.6,63.6,70.8]` → `[67.2,76.8,86.4,96,105.6,115.2,127.2,141.6]`. Não altera fogo inimigo, chefes ou esfera orbital. Direção aleatória e cooldown 9,8 s preservados.

Herói e inimigos: escala visual multiplicada por 1,1, inclusive chefes e crescimento do Devorador. Pivôs ajustados junto com os sprites. Colisores físicos mantidos para preservar corredores; armas, alcance e velocidade não são escalados. Sombras do herói por código removidas tanto para local quanto remotos; atlas do Soldado já registrado como versão sem sombra. Fonte do cronômetro preservada.

Vida: soma absoluta de 30 depois de obter a base da variante e antes dos multiplicadores existentes. Não é aplicada nas transições, snapshots ou reinícios. Alvos destrutíveis de ataques não recebem o bônus de inimigo. Sem novo dano, resistência ou velocidade. Com multiplicador global 1,6, solo inicial sem Desafio: Orc 38,4 → 86,4; Morcego 24 → 72; espada 76,8 → 124,8; arqueiro 60,8 → 108,8; Necromante 112 → 160; Orc montado 192 → 240; Slime grande 144 → 192; Slime pequeno 5,76 → 53,76. Pequeno do evento: 107,52. Os bônus temporais de +35 continuam separados. A vida-base do Rei já inclui seu fator próprio, recebendo +30 uma vez; seus descendentes partem das respectivas bases, sem herdar novamente os bônus do pai.

## Visuais pendentes

O dash corresponde a `guard`, exibido como Soldado, com comportamento `charge`. Não foram modificados todos os inimigos com investida.

Médico da Peste, Devorador e esse Soldado mantêm seus desenhos atuais. Foram pesquisados os arquivos locais e referências via Pinterest, sem encontrar material apropriado com origem/permissão verificada para esses três substitutos nesta rodada. A origem da família visual foi conferida em [Zerie/Tiny RPG](https://zerie.itch.io/tiny-rpg-character-asset-pack); a versão gratuita não resolve esses três desenhos. Não houve compra nem incorporação de prévias. Conforme a regra do pedido, essa parte permanece pendente, sem personagem genérico novo.

## Validação e limites

`fixes23.gd`: intervalos da Varinha, dano de fogo, três acertos do Machado, saída da tela, limpeza, vida do slime pequeno e escala. Aprovado; o encerramento desse harness reportou quatro objetos retidos, sem comprovação de vazamento durante partidas.

Regressões aprovadas: weapons16, refinement21, rune21, garlic21, variants21, limits7, network_foundation, network_backpressure e holy_water. A expectativa do teste antigo de dano foi atualizada somente para o dobro solicitado do fogo. Houve erro de indentação durante desenvolvimento, corrigido antes das exportações.

Renderização: art22, 1.318 verificações, nos três mapas. Público e DEV iniciados. Host e três clientes em processos separados pelo relay WSS público, uma janela renderizada, três mapas e builds completas. Não equivale a quatro máquinas em redes diferentes nem a uma sessão longa. Não foi validada subjetivamente a diversão ou o acabamento final por jogador humano.

Benchmark curto documentado nos JSONs `fixes23/bench-*.json`: mesmo harness, hardware e configuração, quatro donos com seis armas no nível 8, 150 inimigos iniciais misturados, poças e invocações; runtime do editor com PCK exportado, não FPS nativo release. Não comprova 60 FPS em carga máxima ou estabilidade prolongada. Não foram reduzidas quantidades para melhorar os números.

Executáveis: `build/Hordas-0.23.0/Hordas-0.23.0.exe` e `build/Hordas-DEV-0.23.0/Hordas-DEV-0.23.0.exe`. Todos precisam usar PC 0.23.0; protocolo 2 permanece, com verificação da versão. Saves mantêm IDs e equipamentos.

Média observada 0.22 → 0.23: Pátio 60,00 → 60,00 FPS; Biblioteca 60,00 → 59,98; Campos 59,95 → 60,00. p99: 20,07 → 18,09 ms; 19,43 → 23,07; 21,76 → 19,68. Houve piora na cauda da Biblioteca. Benchmark realizado antes do último ajuste de pivô, que não mudou regras de simulação. Não tratar como promessa de desempenho.
