# Visuais das cinco armas, versão 0.17.0

Alho, Chicote, Varinha de Fogo, Runa Traçante e Varinha Mágica agora têm ícones próprios, sprites animados e apresentação na arena. Estão disponíveis nas partidas normais, seleção de melhorias, recompensas de baú, painel da build, coleção e laboratório DEV. A coleção passou de 25 para 30 entradas. As tabelas dos oito níveis permanecem as de [0.16](EXPANSAO_0_16.md): esta entrega não aumenta dano, colisão, alcance, velocidade ou frequência.

## Referências consultadas no Pinterest

As páginas e imagens foram abertas e conferidas visualmente. Os PNGs do jogo são desenhos novos e editáveis pelo gerador do projeto. Não foram baixadas ou incorporadas imagens com marca d'água, assets de Terraria, arquivos de portfólio ou pacotes comerciais.

| Elemento | Pinterest e origem identificada | Aplicação no jogo |
|---|---|---|
| Alho | [Pin](https://br.pinterest.com/pin/853432198129050725/), [Shutterstock 1385583191](https://www.shutterstock.com/image-vector/vector-pixel-art-garlic-isolated-cartoon-1385583191) | Bulbo creme, gomos separados, sombra bege e contorno escuro. Aura clara com centro transparente e borda em pixels. |
| Chicote | [Ícone de couro](https://br.pinterest.com/pin/517562182179157573/), [estudo Terraria Whips](https://br.pinterest.com/pin/1125266656900875863/) | Couro enrolado no ícone, faixa horizontal flexível na animação, extensão e recolhimento. O primeiro Pin não informa autor original; usado como estudo de forma, sem reutilização do arquivo. O segundo identifica um item de Terraria e também não foi reutilizado. |
| Varinhas de Fogo e Mágica | [RPG Pixel Art Icons: Wands, Wildan Rahmat](https://br.pinterest.com/pin/636485359860658190/), [portfólio ArtStation](https://www.artstation.com/artwork/vDJoB3) | Madeira, detalhes de bronze, cristais destacados e contornos legíveis. Fogo em creme/dourado/laranja; magia em azul/ciano. Ícones e projéteis desenhados para este jogo. |
| Runa Traçante | [32x32 runes pack vol. 2, Madao san](https://br.pinterest.com/pin/1060105199771107817/), [origem Patreon](https://www.patreon.com/posts/32x32-runes-pack-88490070) | Cristal facetado, contorno contrastante e inscrição interna. Versão própria em losango ciano com detalhes lilás, rastro de fragmentos coloridos. Nenhum arquivo do pacote foi usado. |

## Assets e edição

`assets/v17/` contém cinco ícones RGBA de 32×32 e oito spritesheets transparentes:

- Aura: seis quadros de 128×128.
- Chicote: oito quadros de 128×32.
- Fogo e magia: seis quadros de 32×24 por projétil e seis de 24×24 por impacto.
- Runa: seis quadros de 24×24 e seis de 12×12 para fragmentos do rastro.

Gerador: `python tools/generate_weapon_visuals17.py garlic`, substituindo o nome por `whip`, `fire_wand`, `runetracer` ou `magic_wand`. A renderização fica em `scripts/combat/new_weapon_visuals17.gd`. Filtro nearest preservado. A cauda de fogo e os rastros são estritamente visuais.

As texturas são compartilhadas e desenhadas no CanvasItem existente. Não são criados nós, timers ou tweens por partícula. Cada rastro mantém no máximo cinco posições locais. Impactos duram 0,3 s, têm limite visual de 48 por jogador e são descartados no reset. IDs crescentes de projétil evitam confundir rastros entre disparos. O host replica registros breves de impacto, com deduplicação no cliente; partículas e quadros não são enviados. Registros saem do envio após 0,35 s. Nenhuma mudança de protocolo: ambos os executáveis usam protocolo 2 e versão 0.17.0.

## Executado

1. Cada arma foi integrada separadamente e executada em janela nos níveis 1 e 8, com capturas de diferentes quadros dentro da arena. Depois de pronta, foi liberada fora do DEV.
2. Os cinco visuais foram executados novamente usando os recursos realmente embalados no executável público.
3. Coleção renderizada em 640×360, 480×360 e 800×450, verificando 30 entradas, contagem de descobertas e painel fixo sem sobreposição.
4. `expansion16`, `weapons16`, `consumables15`, `prices12` e `dev_public11` passaram contra o pacote público: Arco inicial, tabelas de dano, mecânicas das armas, consumíveis, compras/reembolso e ausência do painel DEV na versão pública. O teste de preços em pacote emitiu aviso de duas referências ObjectDB ao encerrar a fixture; os smokes dos executáveis não emitiram esse aviso.
5. `visual_integration17`: disponibilidade pública, bloqueio no nível máximo, alinhamento dos ícones, identidade de projétil, deduplicação/expiração de impacto e limpeza dos quatro jogadores.
6. Quatro processos reais passaram localmente e pelo relay público WSS do Render, com um cliente renderizado. Todos usavam seis armas no nível 8. O roteiro verifica replicação de projéteis, região fixa das runas e preservação dos saves isolados. No roteiro WSS curto: host tick mediano 4,502 ms, p95 8,418 ms; 210.140 bytes enviados pelo host durante o roteiro. Isso não é taxa sustentada em bytes/s.
7. Executáveis público e DEV exportados, cada um executado por 120 frames em smoke headless. O público foi verificado sem F8 ou recursos DEV.

O primeiro ensaio WSS foi encerrado pelo prazo de cinco segundos da ferramenta de teste antes de criar a sala. O endpoint respondeu saudável, protocolo 2. A ferramenta agora permite os mesmos 90 segundos de aquecimento da build, com margem de dez segundos; o ensaio seguinte passou. Isso não modifica timeouts de gameplay.

## Ensaio renderizado de carga

Windows local, AMD Radeon RX 6600, OpenGL Compatibility, viewport lógico 640×360, quatro jogadores simulados na mesma instância, seis armas nível 8 por jogador e quatro passivas nível 8. Duzentos inimigos resistentes como fixture, sem remover entidades para ganhar desempenho. Em cada mapa: 60 frames de aquecimento e 180 medidos. É uma amostra curta de leitura/custo, sem comparação formal de otimização com outra versão.

| Mapa | Frame mediano / p95 / p99 ms | Host tick mediano / p95 / p99 ms | Pico de projéteis novos | Draw calls no quadro final | Memória estática MiB |
|---|---|---|---:|---:|---:|
| Pátio | 16,695 / 17,078 / 17,753 | 9,880 / 13,258 / 13,975 | 49 | 574 | 58,1 |
| Biblioteca | 16,661 / 20,189 / 22,521 | 11,227 / 15,717 / 18,343 | 76 | 594 | 58,5 |
| Campos | 16,633 / 19,932 / 20,467 | 11,056 / 14,819 / 16,400 | 82 | 612 | 59,2 |

Os sprites das runas foram reduzidos para aproximar o corpo visível da colisão; seus rastros passaram a fragmentos menores para diminuir a poluição durante quatro builds simultâneas. Dano, quantidade, duração e colisão não mudaram.

## Limites da validação

Não houve sessão prolongada com quatro máquinas/redes distintas nem avaliação humana de diversão. A mediana próxima de 60 FPS não significa 60 FPS constantes: p95/p99 mostram quedas, sobretudo com as builds máximas. O relay continua no plano gratuito já autorizado e pode suspender sem tráfego.

A fonte Kingdom é uma pendência separada, já documentada na versão anterior: não foi obtido um arquivo licenciado nem realizada a troca nesta entrega. A fonte existente foi preservada.

## Jogar

Usar `Hordas-0.17.0.exe`. Para cooperativo, todos precisam da mesma versão: um cria a sala, envia o código, os demais entram e ficam prontos. O criador inicia. Não exige abrir portas. Para o laboratório, usar `Hordas-DEV-0.17.0.exe` e F8; as cinco armas estão disponíveis do nível 1 ao 8.
