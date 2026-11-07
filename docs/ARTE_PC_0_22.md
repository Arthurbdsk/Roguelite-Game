# Arte original PC 0.22.0

Base: PC 0.21.0, commit `091d93f1b2d8e121bb1b111d07c2f839f7d0ef41`.
Esta entrega é exclusivamente PC. Android continua congelado, sem sincronização, testes ou compilação.

## Implementado

Arte própria baseada nas referências enviadas pelo usuário. As spritesheets novas não são arquivos oficiais Tiny RPG e não usam os GIFs de prévia com texto como personagens.

| Personagem | Atlas e altura visível inicial | Animações utilizadas |
| --- | --- | --- |
| Morcego, ID `hound` preservado | `assets/v22/bat.png`, 15 px | Espera em voo, voo, ataque de contato, dano, morte |
| Necromante | `assets/v22/necromancer.png`, 24 px | Espera, caminhada, preparação/liberação da magia, conjuração, dano, morte |
| Esqueleto com espada | `assets/v22/skeleton_sword.png`, 18 px | Espera, caminhada, preparação/golpe/recuperação, dano, morte |
| Esqueleto com arco e arqueiro do cerco | `assets/v22/skeleton_archer.png`, 18 px | Espera, caminhada, puxar/soltar arco, dano, morte |
| Esqueleto com armadura | `assets/v22/skeleton_armored.png`, 19 px | Espera, caminhada, espada e escudo, dano, morte |
| Orc com armadura | `assets/v22/orc_armored.png`, 18 px | Espera, caminhada, machado, dano, morte |
| Orc de elite | `assets/v22/orc_elite.png`, 18 px | Espera, caminhada, espada e escudo vermelho, dano, morte |
| Orc montado, ID `beast` preservado | `assets/v22/orc_mounted.png`, 27 px | Espera, trote, preparação/ataque montado, dano, morte |
| Slimes comuns e azuis do evento | `assets/v22/slime_*.png`, 16 px grandes e 5 px pequenos | Compressão, salto, contato, dano, divisão/morte |
| Slime Rei | `assets/v22/slime_king.png`, 48 px incluindo coroa | Corpo e coroa próprios, movimento pesado, contato, dano, divisão/morte |

Cada atlas tem 24 quadros. O registro compartilhado em `data/original_characters22.json` define quadro, pivô, textura, clips e altura. As texturas são carregadas uma vez e reutilizadas. O pivô é comum a todos os quadros, sem recentralizar espada, asas ou cadáver por sua caixa visível. Pixels com alpha binário, paleta limitada e nearest.

O Soldado e o Orc comum gratuitos existentes foram preservados. Os chefes e personagens não listados também foram preservados.

O cerco conserva detalhe dourado e tonalidade própria. Armaduras agora aparecem no corpo; os indicadores provisórios de armadura foram retirados dessas variantes. As resistências continuam 5%, 10% e 15%, com os mesmos horários e orçamento.

Conjuração: a animação mostra preparação e recebe o quadro de liberação quando o sistema real consegue criar os sete esqueletos. Não há dano ou invocação disparados por quadro de animação. Corrigido o feedback de dano do arqueiro do cerco, que poderia ficar preso após receber dano.

Água Benta: frasco azul com cruz, rolha, arco e rotação; quebra com fragmentos e respingos; poça azul/ciano com caústicas, bolhas, borda irregular, oito quadros de loop e quatro de dissolução. O mesmo frasco aparece como ícone em melhorias, build, coleção, baús e DEV. O impacto e a poça seguem o destino e o relógio já sincronizados. O rastro de divisão do slime deixou de usar o desenho antigo.

## Valores preservados

Nenhuma alteração em vida, velocidade, dano, alcance, intervalos, chances, quantidades, resistências, recompensas, curva de experiência ou preços. A velocidade dos projéteis não foi modificada.

Água Benta continua com raio 19,8 no nível 1 e aproximadamente 33,12 no nível 8, antes dos bônus. Duração 4 e 6,5 segundos, respectivamente. Com os bônus máximos verificados, raio aproximado 51,83 e duração 12,285 segundos. A interface continua sem casas decimais. Esses números técnicos não são novos valores de balanceamento.

IDs de saves/rede preservados. `hound` passou a exibir Morcego e `beast` passou a exibir Orc montado. Protocolo de transporte 2 preservado, versão de compatibilidade PC 0.22.0. Todos os participantes devem usar 0.22.0 pública ou todos DEV 0.22.0. Android 0.20.0 continua incompatível.

## Evidências visuais

- [Comparação dos atlases anteriores e novos](art22/comparacao-atlases.png). Ampliação 2x; não representa uma captura de interface antiga. Os indicadores provisórios de armadura não fazem parte do atlas anterior.
- [Personagens na arena](art22/arena-fields.png).
- [Água Benta nos Campos](art22/water-fields.png).
- [Água Benta na Biblioteca](art22/water-library.png).
- As páginas `art22/original_*.png` mostram todos os quadros ampliados e os nomes dos clips.
- [Prompts e origem](art22/PROMPTS.md).

## Testes executados

- `tests/art22.gd`: execução renderizada nos três mapas, 1.318 verificações; atlas, clips, efeitos, dano/morte, limpeza, preparação e liberação reais, conjuração de sete e apresentação da Água Benta em quatro momentos.
- `tests/death22.gd`: 104 comparações pixel a pixel entre Sprite2D e o renderizador de morte, nos dois sentidos, mais 40 mortes consecutivas.
- 21 suítes de regressão em `tools/validate_refinement21.py`: arco, Runa, Alho, variantes, textos, armas, limites da build, aprimoramentos, rede, grade espacial, Devorador, slimes, Água Benta, Soldado, Orc, morte e telas. Todas aprovadas.
- `tests/events13.gd`: vinte arqueiros, vida quadruplicada, expiração sem recompensa aos 45 segundos e cadeia completa de quinze azuis/225 pequenos. Atualizadas apenas as expectativas antigas do teste para os multiplicadores de ataque/experiência já existentes.
- `tests/special_enemies.gd`: 24 verificações de conjuração, descendentes, atributos e veneno.
- `tests/art_network22.gd`: host e três clientes em processos separados pelo relay público WSS, uma instância renderizada, três mapas, seis armas e quatro passivas por dono no nível 8, novas espécies/quadros e mortes de Morcego, Necromante e Orc montado recebidas nas posições do host. Quatro processos aprovados, sem erros. Isso não equivale a quatro máquinas em redes distintas.
- Executáveis público e DEV iniciados com sucesso. O pacote público foi carregado em uma pasta vazia para confirmar JSON/atlases embutidos, ausência de DEV e ausência das artes antigas excluídas.

## Desempenho observado e limites

Comparação reproduzível `tools/benchmark22.py`: seed 21007, Ryzen 5 5600, RX 6600, Compatibility OpenGL, janela 1280x720, viewport 640x360, limite 60 FPS. Quatro jogadores simulados com seis armas e quatro passivas no nível 8, 150 inimigos iniciais misturados, necromantes podendo invocar normalmente. Dois segundos de aquecimento e dez de amostra por mapa. Executa o runtime do editor com os PCKs exportados em pasta vazia; **não é benchmark nativo de FPS release**.

| Mapa | FPS 0.21 / 0.22 | Mediana frame, ms | p95, ms | p99, ms |
| --- | --- | --- | --- | --- |
| Pátio | 60,00 / 60,00 | 16,66 / 16,67 | 16,75 / 17,02 | 19,56 / 18,28 |
| Biblioteca | 60,00 / 60,00 | 16,67 / 16,67 | 16,74 / 16,88 | 19,39 / 20,07 |
| Campos | 60,00 / 60,00 | 16,66 / 16,67 | 16,84 / 17,09 | 19,28 / 19,76 |

Picos de até 60 poças e 60 projéteis aliados na amostra final. RSS máximo do processo: 237,93 MiB antes e 236,25 MiB depois. As invocações levaram a Biblioteca a 150 inimigos antes e 156 depois, e os Campos a 150/154; não são estados finais idênticos. Menos draw calls e nós por remover os indicadores provisórios não provam melhora geral de desempenho.

A primeira amostra teve 59,11 FPS nos Campos e p95/p99 de 22,23/27,28 ms, contra 60 FPS e 16,91/20,71 ms antes. Está preservada nos arquivos `amostra-inicial-before.json` e `amostra-inicial-after.json`. A repetição com o executável final ficou próxima de 60 FPS nos três mapas, com valores na tabela. A oscilação entre amostras impede concluir ganho ou regressão sustentada. Não foi reduzida quantidade ou regra para compensar. O primeiro ensaio inválido tentou reservar divisões de slimes demais para a capacidade e parou; a fixture foi corrigida para dois slimes grandes e 148 outros inimigos, igualmente nas duas versões, sem alterar o limite do jogo. A medição curta não comprova ausência de engasgos, vazamentos ou estabilidade de sessões longas. Os JSONs finais registram o hash de cada executável.

Não houve teste com quatro computadores, novas redes externas nem avaliação humana de jogabilidade nesta entrega. A aprovação estética final cabe ao usuário; as artes estão integradas, não são apenas conceitos. Os engasgos em carga pesada já registrados na 0.21 continuam uma limitação, sem promessa de 60 FPS constantes.

## Arquivos editáveis e exportação

Fontes geradas: `assets/v22/sources/`. Atlases finais: `assets/v22/`. Registro: `data/original_characters22.json`. Reempacotamento: `tools/pack_original22.py` e `tools/pack_water22.py`. Catálogo: `tools/catalog_art22.py`.

As fontes grandes, catálogos, testes e desenhos antigos não utilizados ficam fora do executável. Os arquivos antigos permanecem no projeto/Git para recuperação. Público: `build/Hordas-0.22.0/Hordas-0.22.0.exe`. DEV: `build/Hordas-DEV-0.22.0/Hordas-DEV-0.22.0.exe`, F8.
