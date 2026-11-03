# Cooperativo 0.4.0

Implementação integrada à partida e ao executável. A publicação do serviço de salas continua pendente porque não há hospedagem nem URL WSS configurada.

## Comportamento

- Até quatro participantes, código aleatório de seis caracteres, nomes normalizados com um a oito grafemas, prontidão de todos e início exclusivo pelo anfitrião. Sem entrada durante a partida.
- Host controla movimento válido, inimigos, dano, chefes, coletas, escolhas e resgates. O relay carimba a origem e rejeita publicação de estado por clientes.
- Contextos individuais de personagem, habilidades, armas, nível, experiência e ofertas. Tab abre a seleção sem parar o mundo e sem proteger o personagem. Escolhas pendentes sobrevivem à queda.
- Dano letal deixa o jogador caído, sem alvo, ataques ou movimento. A câmera acompanha o aliado vivo mais próximo; o corpo permanece no mundo. HUD mostra nomes, vida, corpos fora da tela e resgate com nome e tempo restante.
- E parado por cinco segundos, alvo mais próximo travado, um socorrista por corpo. Soltar, tentar mover, deslocamento, dano mesmo se curado no mesmo frame, distância, queda ou desconexão zeram o progresso. Segurar E suspende novos ataques e dano orbital; projéteis já disparados continuam. Cair remove os efeitos ofensivos daquele personagem.
- Resgate devolve exatamente 40% da vida máxima, armas e melhorias, com dois segundos de proteção visual. Eventos repetidos são ignorados. Todos os conectados caídos encerram a tentativa.
- XP e ouro coletados pelo host chegam integralmente a todos, inclusive caídos. Coleta remove o item para todos. Ouro no chão não é creditado. Cada computador liquida seu próprio perfil uma vez, inclusive ao sair e ao perder o anfitrião, usando o último saldo confirmado.
- Saída de cliente mantém a partida. Saída/perda do host encerra a sala, mostra o motivo e retorna ao menu. Sem migração ou reconexão. O solo mantém o fluxo de morte, pausa e reinício.

## Balanceamento e rede

`data/network/coop.tres` centraliza os bônus por participante extra: vida +50%, dano +50%, velocidade +20%, quantidade +80%. Em quatro jogadores: 2,5 / 2,5 / 1,6 / 3,4. O tamanho inicial fica congelado mesmo após quedas e desconexões. Chefes permanecem exemplares únicos. Quantidades usam maiores restos e arredondamento do total; o intervalo de surgimento não é multiplicado. Nascimentos ficam fora da visão de todos os vivos e alternam âncoras e direções.

Carrasco: 102,4 de velocidade normal e 108,544 enfurecido com quatro pessoas. Demônio: 112. Ambos ultrapassam a velocidade inicial 96. Os percentuais pedidos foram preservados. Testes sem invulnerabilidade demonstram desvio lateral do golpe de execução e das duas investidas com velocidade inicial. Isso não estabelece equilíbrio ou diversão para humanos.

Entradas saem a 20 Hz. Deltas por campo saem a 10 Hz; entidades paradas não repetem todos os campos. Eventos confiáveis são agrupados por frame e o relay filtra os destinados a cada jogador, preservando ofertas privadas. Coletas simultâneas agrupam feedback para não estourar o limite de mensagens. Movimento local usa previsão e correção; demais entidades usam interpolação e projéteis têm avanço visual entre pacotes. O WebSocket usa transporte TCP confiável, inclusive para deltas; não há canal UDP. Perda e latência podem causar atrasos acumulados, ainda sem medição externa.

Limites existentes de inimigos e projéteis continuam ativos. Filas do socket, carga de mensagem, taxa, salas e conexões têm limites. O relay não mantém banco de dados. O host é confiável para o mundo; não há proteção contra um anfitrião alterado nem verificação remota das compras permanentes.

## Execução e publicação

Teste visual local: `Testar_Coop_Local.cmd` abre quatro cópias da versão 0.4, com perfis `coop_local_1` a `coop_local_4`, distintos do progresso normal. Fechar todas as janelas encerra o relay do teste. Não exige digitar IP.

Servidor: `cd relay`, `npm ci`, `npm start`. Escuta local em `127.0.0.1:8080`. Container: `docker build -t brasafria-relay relay`. A imagem inicia com `HOST=0.0.0.0` e `PORT=8080`; o provedor pode fornecer outra porta via ambiente.

A hospedagem precisa executar continuamente esse container ou Node.js, expor `/health`, suportar conexões WebSocket duradouras e oferecer HTTPS/WSS com certificado válido. Copie `network.cfg.example` para `build/network.cfg` e configure a URL pública. A configuração ao lado do executável tem preferência; também pode ser embutida em `res://network.cfg` ao exportar. Não exige chaves no cliente, IP de jogador nem portas no roteador. Não há conta de provedor ou domínio configurado para publicar nesta entrega.

## Validação executada

- Relay: sockets reais, códigos, nomes, limite, prontidão, início, isolamento de eventos privados em lote, falsificação rejeitada, saída de cliente e host.
- Fundação: 66 verificações das tabelas de um a quatro participantes, arredondamentos, validação/timeout de entradas, resgates e interrupções.
- `node match-test.mjs`: quatro processos Godot com a cena e simulação reais. Movimento remoto, composição escalada, chefe e preparação replicados, XP/ofertas, mundo sem pausa, queda na escolha, resgate do host por cliente, resgate com dano e reinício, 40% de vida, proteção, eventos repetidos, carga, coleta simultânea, saída de cliente, derrota e perfis individuais recarregados.
- Carga da partida em rede: 180 inimigos, 2.000 moedas, 240 itens de XP e 320 flechas. Testes headless no mesmo computador, sem medir FPS renderizado ou latência de internet.
- `node match-test.mjs --disconnect`: quatro processos, saída do host, mensagem de encerramento, retorno dos clientes ao menu e salvamento do saldo confirmado.
- `tests/coop_bosses.gd`: 73 verificações, velocidades reais de quatro participantes, três desvios sem invulnerabilidade e 32 surgimentos seguros com equipe dividida.
- Regressão: combate 224, hordas/ouro 639, árvore/chefes 2.100, integração solo completa 347; menus e textos sem transbordamento.
- Capturas renderizadas da entrada, lobby, combate, resgate e menus privados em `test_output/coop_*.png`.
- Executável nativo: smoke de 120 frames. Pacote embutido exercitado pelo runtime correspondente em testes de combate/chefes, ouro e quatro processos cooperativos. O harness externo usa o runtime de editor, não equivale a quatro sessões nativas controladas manualmente.

## Limitações restantes

Não publicado nem testado entre redes físicas diferentes. Falta uma hospedagem pública e, depois, validar WSS, latência real, perda de conexão e avaliação humana em quatro computadores. Não anunciar multiplayer de internet validado. Não há migração de host, reconexão ou retomada de tentativa após encerrar o processo à força.
