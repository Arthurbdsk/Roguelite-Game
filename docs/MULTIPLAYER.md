# Cooperativo online: implementação em andamento

O cooperativo jogável ainda não está concluído. O executável 0.3.0 permanece solo. Nenhum botão de sala sem partida sincronizada foi adicionado ao menu publicado.

## Implementado nesta etapa

- Relay WebSocket Node.js separado, salas reais com código aleatório de seis caracteres e até quatro participantes.
- Validação de nomes de um a oito grafemas, normalização de acentos e remoção de espaços externos.
- Prontidão e início exclusivo pelo criador; sala iniciada rejeita novas entradas.
- Entrada inválida, sala cheia e falha de conexão têm respostas explícitas.
- Relay carimba a identidade de origem; apenas o host pode distribuir eventos e deltas de estado. Clientes enviam ações ao host.
- Saída de cliente notifica os restantes; saída do host encerra a sala. Não há migração de host ou reconexão.
- Cliente Godot `RoomConnection`, com polling, timeout, configuração de URL pública e TLS normal da Godot. Não usa IP de jogador nem exige portas no roteador.
- Regras configuráveis para os multiplicadores aditivos pedidos. A quantidade é arredondada no total, com distribuição por maiores restos; um chefe continua sendo um exemplar. Não altera frequência.
- Autoridade de entrada rejeita sequências repetidas, valores inválidos, movimento excessivo e ações antigas.
- Modelo de autoridade de reanimação: cinco segundos, alvo mais próximo travado, um socorrista por corpo, cancelamento e reinício do progresso, retorno com 40% de vida e dois segundos de proteção.

Esses módulos ainda não estão ligados aos personagens e à simulação da partida. O modelo de reanimação é testado com estados do host; não é uma reanimação já disponível no jogo.

## Testado

`npm test` em `relay/`: conexões WebSocket reais verificam nomes, criação, código, quatro vagas, prontidão, início, mensagens de erro, rejeição de eventos falsos de cliente, encaminhamento de ações e desconexões.

`node godot-test.mjs` em `relay/`: quatro processos reais Godot conectam ao relay local. Um cria o código, três entram, todos ficam prontos, o host inicia, envia um evento e recebe três ações de confirmação. Marcador `FOUR_GODOT_INSTANCES_PASS`. Não testa uma partida com quatro personagens.

`tests/network_foundation.gd`: testa a tabela de um a quatro jogadores, arredondamento de composições, exemplar único de chefe, reanimação completa, todas as interrupções, exclusividade, alvo travado, vida exata, proteção, todos caídos, ações repetidas e timeout.

Nenhum teste entre redes físicas diferentes foi realizado. Não houve teste de latência de combate ou desempenho de replicação de hordas.

## Hospedagem necessária

Não foi configurado serviço público. O usuário informou que ainda não possui hospedagem.

O relay precisa de um serviço persistente que execute o container `relay/Dockerfile`, aceite upgrade WebSocket e termine TLS em um endereço HTTPS/WSS. Configuração: variável `HOST=0.0.0.0`, variável `PORT=8080` ou a porta atribuída pelo provedor; encaminhar essa porta pelo proxy HTTPS, permitir conexões WebSocket duradouras, expor `/health`, usar certificado válido para o domínio. Não é uma função HTTP que encerra após cada requisição.

Construção: `docker build -t brasafria-relay relay`. Execução local: `cd relay`, `npm ci`, `npm start`. A configuração local padrão escuta somente em `127.0.0.1:8080`.

Depois de publicar, copiar `network.cfg.example` para `network.cfg` e preencher a URL pública `wss://...`. A URL não é uma credencial privada. O executável futuro deve incluir essa configuração. Não colocar chaves de provedor no jogo.

Túneis temporários podem servir a testes, mas não substituem um endereço permanente: dependem de um processo em execução e a URL pode mudar.

## Trabalho restante antes de liberar o cooperativo

1. Contexto individual de personagem, armas, escolhas e habilidades dentro da simulação compartilhada do host.
2. Integração do lobby no menu, nomes e marcadores no mundo.
3. Aplicação dos multiplicadores congelados no início; validação dos chefes com quatro jogadores. Carrasco a 64 × 1,6 chega a 102,4, acima da velocidade básica 96. Demônio a 70 × 1,6 chega a 112. Os percentuais não foram reduzidos para esconder essa questão.
4. Replicação incremental, interpolação e separação entre eventos confiáveis e posições frequentes.
5. Estado caído, interação E, bloqueio de ataques e espectador ligados aos personagens reais.
6. Coleta autoritativa compartilhada, escolhas individuais sem pausa global e liquidação individual idempotente nos perfis locais.
7. HUD de equipe, direção de corpos fora da tela e saída de sessão integrada.
8. Testes de partida com múltiplas instâncias e redes diferentes, carga, desconexões e regressão completa do solo.

Não foi gerado um executável 0.4 nem anunciado multiplayer pronto.
