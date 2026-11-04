# Cooperativo 0.4.0

Implementação integrada à partida e ao executável. Em 03/11/2026 foi iniciado um serviço temporário via Cloudflare Quick Tunnel. A configuração atual está em `build/network.cfg` e a cópia para amigos em `build/Configuracao-Online.zip`. O endereço depende dos processos locais e muda ao reiniciar o túnel. Não há hospedagem permanente.

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

O túnel temporário foi testado com quatro processos pelo endereço WSS público, incluindo combate, carga, coleta e persistência. Todos os processos ainda estavam no mesmo computador. Falta testar com os amigos em redes físicas diferentes e providenciar hospedagem permanente. Não anunciar validação entre quatro redes independentes. Não há migração de host, reconexão ou retomada de tentativa após encerrar o processo à força.

Teste externo: em `relay/`, `node match-test.mjs --packed=../build/Brasafria-0.4.0.exe --relay-url=wss://ENDERECO` permite exercitar o pacote pelo serviço público. O teste de 03/11 passou com 83 verificações distribuídas em quatro processos, sem erros do motor.


## Correção 0.4.1

O limite anterior fechava a conexão ao receber mais de 100 mensagens em uma janela curta. O teste de regressão reproduziu fechamento 1008 com 180 mensagens acumuladas. O controle agora limita o tráfego sustentado com créditos para rajadas e também limita bytes; o mesmo lote passa e um flood permanece bloqueado.

O cliente verifica falhas de envio, mantém eventos confiáveis pendentes e só avança a base de deltas quando o envio é aceito. Também suspende a construção de novas posições enquanto o buffer de saída está congestionado. O teste `network_backpressure.gd` confere dez casos de falha e retomada, incluindo remoção de inimigos e moedas.

O cliente registra código, motivo, idade da conexão, falhas de envio e maior intervalo de polling em `user://network_<PID>.log`, sem gravar mensagens de partida. O relay registra motivo do fechamento e limites em `test_output/relay-runtime.jsonl` quando essa pasta existe; em container usa a saída padrão. A tela de erro mostra o código do fechamento.

O teste prolongado por QUIC perdeu todas as conexões quando o Windows entrou em suspensão, com erro de buffer de rede registrado pelo túnel. O túnel antigo expirou após o período offline. O novo túnel temporário usa HTTP/2 sobre TCP e IPv4. Isso não permite jogar enquanto o PC estiver suspenso. A causa exata da primeira queda relatada pelo usuário não pôde ser recuperada: aquela versão não registrava o fechamento.

`match-test.mjs --soak-seconds=310 --relay-url=wss://ENDERECO --packed=CAMINHO` mantém quatro processos por mais de cinco minutos; depois de um minuto adiciona 180 inimigos duráveis, 2.000 moedas, 240 itens de experiência e disparos até o limite de 320. Exercita expiração, novas moedas e coleta em massa. Os logs do motor são separados por processo para não sobrescrever o log da partida normal.

No teste inicial de HTTP/2, as quatro conexões permaneceram ativas por aproximadamente 339 segundos. O próprio harness encerrou os clientes por timeout antes do host: a espera por timers da simulação demorava mais sob carga. O harness foi corrigido para medir a duração com relógio monotônico e dar margem ao encerramento. Esse primeiro resultado não é registrado como suíte aprovada.

Os eventos confiáveis pendentes são enviados em lotes de até aproximadamente 60 KiB; os dez casos de backpressure verificam preservação de ordem e ausência de perda ou duplicação em uma fila de 500 eventos.

Validação final de HTTP/2: quatro processos com o pacote 0.4.1 permaneceram conectados por 310.099 ms de relógio monotônico, sem queda, incluindo 180 inimigos. Todos terminaram com `COOP_MATCH_PEER_PASS`. A distribuição está em `build/Online-Atualizado/Brasafria-Online-0.4.1.exe`, com o endereço atualizado embutido. Não foi uma medição de FPS renderizado nem um teste com quatro redes físicas independentes.
