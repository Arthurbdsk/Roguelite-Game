# Brasafria

Proposta e especificação do protótipo 0.1.0. O comportamento descrito está no código atual; esta documentação não comprova teste de execução ou equilíbrio. Resultados de validação devem ser registrados separadamente.

## 1. Conceito geral

Uma sentinela mantém a última vigília em um pátio tomado por mortos. O objetivo é resistir dez minutos e derrotar o Rei sem Brasa antes do amanhecer.

Pilares: posicionamento legível, armas com funções distintas, escolhas com limites e tentativas curtas. A fantasia sombria usa ferro gasto, pedra com musgo, brasa oxidada e luz fria.

O diferencial proposto é o apoio da fortaleza. O Arsenal prepara a besta para a próxima tentativa, mas reduz a rotação das brasas. A Biblioteca prepara as brasas, mas atrasa os disparos da besta. Apenas um apoio pode ser escolhido. As construções mudam a preparação e favorecem a progressão da família escolhida; não acumulam bônus permanentes de dano ou vida.

Decisões abertas: nome Brasafria, paleta, relação entre construções e armas, severidade das trocas e balanceamento dos dez minutos. As imagens citadas no pedido não foram recebidas; a direção visual usa somente o texto como referência. A arte atual é original e provisória.

## 2. Gameplay loop

1. Entrar com a Sentinela e a Lâmina da vigília.
2. Escolher, na fortaleza, nenhum apoio ou uma construção desbloqueada.
3. Explorar o Pátio dos Esquecidos, eliminar ameaças e recolher experiência.
4. Subir de nível, pausar a ação e escolher uma entre três melhorias.
5. Decidir entre manter distância, abrir caminho e ocupar o anel das brasas.
6. Arriscar o altar, enfrentar o Carrasco e preparar a luta final.
7. Vencer aos 600 segundos com o chefe derrotado, ou encerrar por morte, abandono ou prazo sem derrotá-lo.
8. Receber selos, comprar uma construção e tentar novamente.

| Camada | Conteúdo | Após a tentativa |
| --- | --- | --- |
| Temporária | Experiência, nível, armas encontradas, níveis das armas e passivas | Reinicia |
| Permanente | Selos, Arsenal, Biblioteca, estatísticas e opções | Salva localmente |
| Equipamento persistente | Inventário, peças e comparação de equipamento | Conteúdo futuro |

O protótipo tem um personagem e uma região. Não apresenta seleções sem alternativas reais.

## 3. Mecânicas principais

### Movimento e sobrevivência

WASD, setas, analógico esquerdo e direcional digital movem a Sentinela. Movimento diagonal é normalizado. A base possui 100 de vida, velocidade 96 pixels por segundo e raio de coleta 42 pixels. Pilares e bordas usam colisores físicos.

Contato e áreas inimigas causam dano. Cada acerto concede 0,85 segundo de invulnerabilidade e um pequeno recuo. A armadura reduz o dano recebido, respeitando o mínimo de 1. Esc ou Start alternam pausa e continuação. Reiniciar começa uma tentativa limpa com o apoio escolhido. Não há esquiva ou habilidade ativa nesta versão; seu benefício precisa ser validado antes da inclusão.

### Mira, experiência e escolhas

Os ataques procuram o inimigo vivo mais próximo dentro do alcance. Empates usam a ordem de criação. A lâmina aponta seu arco para esse alvo; o virote fixa a direção ao disparar e não o persegue. As brasas giram ao redor do jogador.

O primeiro nível exige 6 pontos de experiência. Cada nível seguinte exige mais 5. Experiência excedente é preservada e pode gerar outra escolha. Ao subir de nível a simulação para e três ofertas diferentes aparecem. Teclas 1, 2 e 3, botões e foco nativo permitem selecionar.

Limites: três armas, três passivas, armas até nível 5 e passivas até nível 2. Há cinco passivas disponíveis, portanto uma tentativa não pode reunir todas. O quinto nível de cada arma exige uma passiva de afinidade, pelo menos no nível 1. Uma oferta de arma é garantida enquanto houver progressão válida. Ofertas recentes recebem peso menor; o apoio favorece sua arma. Não há garantia de que uma opção desapareça por completo no próximo sorteio.

Quando faltam escolhas válidas, entram consumíveis: cura de 35, dois selos ou repulsão com 80 de dano em alcance 160. Cura com vida cheia concede dois selos. Consumíveis não ocupam vaga.

### Armas

Valores por nível, do 1 ao 5. Alcances usam pixels da resolução interna. O intervalo das brasas é o tempo mínimo entre acertos no mesmo inimigo, não o tempo de uma volta.

| Arma | Dano | Intervalo em segundos | Alcance | Quantidade |
| --- | --- | --- | --- | --- |
| Lâmina da vigília | 18 / 23 / 26 / 32 / 40 | 0,80 / 0,80 / 0,76 / 0,72 / 0,66 | 58 / 65 / 67 / 76 / 88 | 1 / 1 / 2 / 2 / 2 arcos |
| Besta de ossos | 14 / 17 / 18 / 23 / 27 | 1,20 / 1,15 / 1,25 / 1,10 / 1,00 | 240 / 255 / 260 / 290 / 310 | 1 / 1 / 3 / 3 / 3 virotes |
| Brasas votivas | 9 / 13 / 15 / 19 / 25 | 0,42 / 0,40 / 0,38 / 0,36 / 0,32 | 42 / 46 / 48 / 53 / 60 | 3 / 3 / 4 / 4 / 5 brasas |

- **Lâmina:** abre espaço próximo e repele ameaças. No nível 3 ganha arco traseiro; no 4 amplia a abertura. Exige Selo da muralha para evoluir em Juramento partido. Depende de enfrentar a direção certa e não cobre longa distância.
- **Besta:** elimina ameaças em linha antes do contato. No nível 2 atravessa dois inimigos; no 3 forma leque. Exige Passo do exílio para evoluir em Rosário de ferro, com um ricochete. Alvos móveis podem sair da trajetória.
- **Brasas:** controlam um anel próximo. Aumentam quantidade, raio e dano ao evoluir. Exigem Ímã funerário para a Coroa de cinzas. A área entre o jogador e o anel continua vulnerável; posicionamento altera o dano efetivo.

### Passivas

| Passiva | Efeito por escolha | Limitação ou afinidade |
| --- | --- | --- |
| Passo do exílio | +18 de velocidade | Libera evolução da besta |
| Ímã funerário | +32 de coleta, depois +40 | Libera evolução das brasas |
| Coração de âmbar | +25 de vida máxima e cura 30 | Ocupa uma das três vagas |
| Selo da muralha | Bloqueia 2 de dano por acerto | Libera evolução da lâmina |
| Sino rachado | Reduz o intervalo da lâmina e besta em 12%, depois 24% no total | Não acelera a órbita |

A composição e os limites existem no código. Ausência de combinação dominante ainda depende de sessões de jogo e ajustes medidos.

## 4. Inimigos e chefes

| Ameaça | Função | Base de vida / velocidade / dano | Leitura |
| --- | --- | --- | --- |
| Esquecido | Perseguidor comum | 24 / 25 / 8 | Silhueta humana verde, aproximação contínua |
| Rasga-bruma | Fera rápida e frágil | 15 / 48 / 6 | Silhueta baixa violeta, desvio lateral |
| Carrasco | Pesado com investida | 78 / 18 / 14 | Escudo largo; prepara 0,85 s antes de investir |
| Carrasco elite | Pressão no quinto minuto | 4 vezes a vida normal e dano de contato 25% maior | Tamanho e contorno ferrugem |
| Rei sem Brasa | Chefe final | 1350 / 22 / 20 | Silhueta grande com coroa, barra própria e áreas antecipadas |

Vida dos inimigos comuns cresce com o tempo da tentativa. A elite usa o Carrasco como base. A investida tem aproximação, preparação, ataque de 0,65 segundo e recuperação de 1,25 segundo. A direção é fixada antes do avanço.

O chefe fixa uma área na posição observada do jogador, avisa por 1,3 segundo e atinge depois. Seis áreas ao redor dele avisam por 1,6 segundo. Ele desacelera ao preparar o padrão e reduz o intervalo dos padrões abaixo de metade da vida. As áreas não seguem o jogador durante o aviso. Ao morrer, o chefe concede cinco selos e remove suas áreas restantes.

O diretor aumenta frequência e tamanho dos lotes. Começa com Esquecidos, introduz feras após 90 segundos e pesados após 210. A elite aparece a partir de 300 segundos e o chefe a partir de 540. O limite é 180 inimigos. Pontos de surgimento são rejeitados quando estão na câmera ampliada por 40 pixels ou em posição insegura. Caso não encontre um ponto válido, o surgimento é adiado.

Atiradores, outros modificadores de elite e novos chefes ficam fora do protótipo.

## 5. Level design

O Pátio dos Esquecidos mede 1800 × 1200 pixels. O início fica no centro, com avenidas largas, um selo no piso, oito pilares sólidos e bordas fechadas. Lápides e braseiros atuais são decoração. A colisão dos pilares se concentra na base visível.

O altar fica em (1260, 810). A partir de 120 segundos, permanecer em seu raio por seis segundos recupera 25 de vida, concede 10 de experiência e dois selos. Sair reduz o progresso gradualmente. A recompensa é única por tentativa. O círculo e a indicação de tempo mostram a área de interação.

| Tempo | Função no ritmo |
| --- | --- |
| 0:00 a 1:30 | Aprender alcance, coleta e primeira melhoria |
| 1:30 a 3:30 | Feras exigem reposicionamento; altar oferece risco e recompensa |
| 3:30 a 5:00 | Pesados interrompem rotas previsíveis |
| 5:00 a 9:00 | Elite e pressão crescente exigem concluir a build |
| 9:00 a 10:00 | Chefe e horda combinam antecipação e controle de espaço |

As rotas foram desenhadas para oferecer espaço de manobra. A legibilidade e a possibilidade de prender inimigos atrás de obstáculos precisam ser observadas nos testes.

## 6. Direção de arte

Resolução interna de 640 × 360, ampliação inteira, filtro Nearest e ajuste de posições ao pixel. Janela inicial 1280 × 720. Não há suavização nos PNGs.

Paleta base: noite `#11191c`, pedra `#243035`, musgo `#424c3a`, marfim `#d7c9a1`, ferrugem `#b65f42` e frio `#83c4bd`. Cenário usa menor contraste; o jogador combina armadura clara, capa vermelha e marca fria junto aos pés. Avisos inimigos usam ferrugem e ocre.

Personagens possuem quatro quadros horizontais: Sentinela e Esquecido em 24 × 32, fera em 24 × 24, Carrasco em 32 × 40 e chefe em 64 × 64. Piso usa blocos de 32 × 32. Ícones têm 16 × 16. A interface utiliza controles nativos, bordas retas e a fonte Pixelify Sans com licença incluída.

HUD: vida, nível, experiência, cronômetro, armas, passivas, abates, selos e vida do chefe. Menus distinguem o que dura uma tentativa e o que é permanente. Opções incluem volume, tela cheia, intensidade dos efeitos e tremor da câmera.

Áudio atual é sintetizado para ataques, impacto, dano, coleta, nível, seleção, elite, chefe, vitória e derrota. Há oito vozes e intervalo mínimo por categoria para limitar ruído. Não há trilha musical final.

## 7. Lista de assets

### Presentes para o protótipo

- Cinco spritesheets originais: jogador, três inimigos e chefe.
- Atlas com 16 variantes de piso, pilar, lápide e braseiro.
- Fortaleza ilustrada em 256 × 160 para título e base.
- Oito ícones de armas e passivas, fragmento de experiência e selo.
- Ícone do aplicativo, fonte com licença e sons sintetizados.
- Arcos, projéteis, órbitas e avisos desenhados pelo próprio jogo.

As fontes dos PNGs são o gerador `tools/generate_assets.py` e os parâmetros nele definidos. `assets/README.md` registra dimensões e origem recomendada. O conjunto é provisório, funcional e editável.

### Futuro

Animações direcionais, ataques e mortes próprios, equipamento visível, novas regiões, inimigos à distância, eventos adicionais, áreas persistentes, raios encadeados, impactos lentos, música e sons finais. Nenhum desses itens é requisito oculto para encerrar a versão mínima.

## 8. Fortaleza e progressão

As duas construções implementadas custam oito selos cada. Compras são permanentes. O jogador pode desbloquear as duas, mas escolhe somente um apoio por tentativa.

| Construção | Preparação | Troca |
| --- | --- | --- |
| Arsenal | Começa com besta e favorece suas ofertas | Rotação orbital 15% mais lenta |
| Biblioteca | Começa com brasas e favorece suas ofertas | Intervalo dos disparos da besta 15% maior |
| Sem apoio | Começa somente com lâmina | Sem penalidade de apoio |

As três armas também podem ser obtidas pelas ofertas de nível. A construção antecipa e favorece uma família, sem bloquear o combate básico atrás de repetição obrigatória.

Selos recebidos ao encerrar:

`floor(segundos / 30) + floor(abates / 30) + selos coletados + 10 se venceu`

Elite concede três selos; chefe, cinco; altar, dois. Tributo e cura com vida cheia também podem conceder dois. A mesma fórmula vale após morte ou abandono, sem o bônus de vitória. O resultado é concedido uma vez por tentativa. Experiência não se converte em selos.

Forja, equipamentos persistentes, Tesouraria, Quartel e Bestiário são futuros. Cada um só deve entrar quando houver uma função própria e conteúdo suficiente para justificar o menu.

## 9. Implementação técnica

| Responsabilidade | Arquivos principais |
| --- | --- |
| Estado e integração da tentativa | `scripts/main.gd`, `scenes/main.tscn` |
| Jogador, vida e dano | `scripts/entities/player.gd`, `scenes/entities/player.tscn` |
| Inimigos e estados | `scripts/entities/enemy.gd`, `scenes/entities/enemy.tscn` |
| Arena e diretor | `scripts/world/arena.gd`, `scripts/world/director.gd` |
| Armas, coleta de alvos e ofertas | `scripts/combat/weapons.gd`, `scenes/combat/weapons.tscn` |
| Resources editáveis | `scripts/data`, `data/weapons`, `data/upgrades`, `data/enemies` |
| HUD e menus | `scripts/ui/game_ui.gd`, `scenes/ui/game_ui.tscn` |
| Progresso e salvamento | `scripts/core/profile.gd` |
| Sons e limite de vozes | `scripts/core/sound.gd` |

Experiência, coleta, áreas de dano e resultado são coordenados em `main.gd`. Os atributos de armas, melhorias e inimigos ficam em Resources, sem duplicar os comportamentos.

O perfil tem versão 1 e guarda selos, construções, estatísticas e opções em `user://profile.json`. Arquivo ausente mantém valores iniciais. JSON inválido ou versão incompatível não são carregados; a leitura preserva o arquivo. A gravação usa arquivo temporário e cópia `.bak` do anterior. Não existe continuação de tentativa interrompida nem salvamento na nuvem.

Limites explícitos: 180 inimigos, 100 projéteis, 240 fragmentos de experiência, 32 áreas de dano e oito vozes. Ao atingir o limite de fragmentos, o valor de experiência é agregado. Os números de dano dependem da intensidade de efeitos. Uma grade espacial auxilia a separação dos inimigos; a seleção de alvos consulta a lista mantida pelo controlador. Virotes usam teste de segmento entre posições para reduzir atravessamento de alvos.

Não foi introduzido reaproveitamento de objetos sem medição. Taxa de quadros, uso de CPU, seleção de alvos e colisões sob carga precisam de evidência de execução. O código possuir limites não comprova desempenho em qualquer máquina.

## 10. Roteiro de produção

O roteiro detalhado está em `ROADMAP.md`. Ordem: fatia de combate, escolhas e armas, diretor e confronto final, fortaleza mínima, validação e acabamento. Cada etapa exige um resultado jogável antes de ampliar conteúdo.

Os testes devem separar verificações automáticas de regras, inspeção visual e avaliação de diversão. Controle físico, áudio ouvido, desempenho em outras máquinas e exportações para outros sistemas só podem ser declarados após teste específico.

## 11. Versão mínima jogável

Escopo do código atual: uma arena, uma Sentinela, três armas, cinco passivas, três inimigos comuns, uma elite, um chefe, experiência, três ofertas por nível, evolução de armas, vitória, derrota, pausa, reinício, duas construções e perfil local.

Critério de conclusão: executar uma tentativa, recolher experiência, escolher melhorias que alteram os ataques, receber dano legível, enfrentar a escalada, alcançar os dois resultados possíveis, reiniciar sem carregar estado temporário e recuperar somente os dados persistentes. O fechamento depende dos resultados de teste registrados pelo responsável pela integração.

Crédito do projeto: [Feito por Socialy](https://www.instagram.com/socialy_webdesign/).
