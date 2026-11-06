# Cooperativo 0.14.0

## Estado da publicação

O cliente e o relay usam protocolo 2. Não existe endpoint público configurado: `network.cfg` tem URL vazia. Não há servidor Node persistente com endpoint, domínio e credencial de implantação configurados nesta sessão. Portanto, esta entrega prepara a implantação e corrige o transporte, mas não afirma que os amigos já conseguem criar salas pela internet.

Foi verificada também a alternativa Vercel. Ela suporta WebSockets, mas as conexões encerram ao atingir a duração máxima e novas conexões não têm afinidade garantida com uma instância. Um deploy direto das salas em memória não atende a esses requisitos; seria necessária coordenação externa e retomada de sessões. Essa migração não foi feita sem medição de benefício. [Documentação oficial](https://vercel.com/docs/functions/websockets).

Os testes com quatro processos locais, atraso e limitação de banda não substituem quatro máquinas nem redes distintas. Não usar Quick Tunnel ou um processo local como hospedagem permanente.

## Implantação permanente

### Render

O `render.yaml` na raiz prepara um serviço Node com uma única instância, health check e token de métricas gerado pelo provedor. Usa compute Starter pago, que só deve ser criado após conferir e autorizar o preço no painel. O arquivo sozinho não cria nem cobra um serviço.

Após entrar no Render, criar um Blueprint deste repositório, conferir a configuração e o custo antes de confirmar. Não é necessário comprar domínio: usar o endereço HTTPS/WSS `onrender.com` fornecido pelo serviço. Desativar deploy automático evita interromper salas a cada alteração no GitHub; um deploy manual ou reinício ainda encerra as salas em memória. Manter uma instância, sem autoscaling.

Quando o serviço estiver Live, validar `/health`, configurar a URL com `tools/configure_relay.py`, executar os testes externos e exportar os clientes com o endereço real. Não distribuir um hostname presumido antes de o Render fornecer o endereço.

O plano Free pode suspender após quinze minutos sem tráfego e tem outras restrições; não é apresentado como hospedagem permanente de produção. [Limitações oficiais](https://render.com/docs/free). [Configuração Blueprint](https://render.com/docs/blueprint-spec).

### Servidor próprio com Docker

Requisitos externos: servidor Linux com Docker Compose, domínio com DNS apontando para o servidor e portas 80/443 acessíveis no servidor. Nenhum jogador precisa configurar portas no roteador.

1. Copiar a pasta `relay` para o servidor.
2. Copiar `.env.example` para `.env`. Definir `RELAY_DOMAIN` e um `METRICS_TOKEN` privado e longo. Esse token nunca entra no jogo.
3. Executar `docker compose up -d --build` dentro de `relay`.
4. Verificar `https://SEU_DOMINIO/health`: deve retornar `ok: true`, `protocol: 2` e `supported: [1,2]`.
5. Executar `python tools/configure_relay.py wss://SEU_DOMINIO` no projeto. Esse comando valida HTTPS, certificado e protocolo antes de gravar `network.cfg`.
6. Exportar os dois executáveis novamente. A URL fica embutida no arquivo único. Como alternativa, distribuir o mesmo `network.cfg` ao lado de cada executável já gerado.
7. Executar `node relay/match-test.mjs --normal13 --packed=build/Hordas-0.14.0/Hordas-0.14.0.exe --relay-url=wss://SEU_DOMINIO` e a suíte `--survival` com o executável DEV.
8. Confirmar uma partida real entre redes distintas antes de anunciar a internet como validada.

A configuração segue a [documentação de HTTPS automático](https://caddyserver.com/docs/automatic-https) e de [reverse proxy](https://caddyserver.com/docs/caddyfile/directives/reverse_proxy) do Caddy.

Caddy fornece HTTPS/WSS e mantém certificados nos volumes do Compose. O relay não precisa de banco de perfis. Containers reiniciam automaticamente; logs têm rotação e o endpoint de métricas exige `Authorization: Bearer METRICS_TOKEN`. A configuração Compose não foi executada aqui: Docker e um servidor público não estão disponíveis.

O endpoint `/health` não deve ficar atrás de uma página de autenticação. O provedor precisa aceitar WebSockets duradouros, sem suspensão por inatividade do plano. Monitorar reinícios, uso de memória, tempo de fila, RTT e falhas de envio.

## Como jogar depois da implantação

1. Todos usam a mesma versão 0.14.0 e o mesmo tipo de sala. Um `network.cfg` antigo ao lado do executável tem prioridade: atualize-o para o relay permanente e não reutilize o endereço de um túnel encerrado. Sala DEV requer o modo DEV de todos.
2. Criador abre Online, informa nome e cria a sala.
3. Envia o código de seis caracteres para os três amigos.
4. Amigos entram com o código. O criador escolhe mapa e Desafio.
5. Todos marcam Pronto. O criador inicia; a contagem só começa depois do carregamento dos quatro mapas.

WASD/setas movem; os ataques são automáticos. E abre baús e reanima aliados, com prioridade para reanimação. Tab abre a escolha individual. Esc abre o menu sem pausar os outros. O host controla dano, inimigos, recursos e decisões. Sair ou perder o host encerra a sessão; migração de host e reconexão não foram adicionadas.

## Transporte e filas

WebSocket usa TCP confiável e ordenado. O projeto não está enviando snapshots UDP. Estados completos são gerados a 10 Hz, independentemente do desenho, codificados como Variant sem objetos e comprimidos com Zstandard. Limites: 4 MiB descomprimidos e 512 KiB por pacote. Vetores nativos preservam posição e frações.

Cada snapshot contém todo o estado necessário, identificação da partida e sequência. Isso permite substituir um snapshot ainda não enviado sem perder baseline. Ausências no estado completo removem réplicas, evitando fantasmas. Todos os jogadores recebem as entidades da arena inteira; não há descarte baseado apenas na câmera do host.

No relay, cada destinatário mantém uma única posição de snapshot pendente. Eventos críticos ficam em fila separada e têm prioridade. O limiar de envio é 64 KiB já no transporte; eventos críticos têm limite de 1 MiB, com encerramento explícito por fila travada por dez segundos. O código não tenta apagar bytes que já chegaram ao WebSocket/TCP.

O host deixa de produzir snapshots quando sua saída ultrapassa 256 KiB. Os próximos estados são completos. Heartbeats WebSocket continuam ativos; probes medem separadamente RTT até o relay e RTT através do host. Fila, bytes, codificação, decodificação e correções visuais são instrumentados. O painel F8 DEV ganhou a aba Desempenho.

O protocolo antigo é aceito pelo relay apenas em salas da própria versão/protocolo. Clientes de protocolos ou versões diferentes não entram juntos. O carregamento tem timeout de trinta segundos, com retorno à prontidão para tentar novamente.

## Testes reproduzíveis

```powershell
node --test relay/test.mjs relay/binary-test.mjs
node relay/match-test.mjs --normal13 --rtt=50 --jitter=5 --bandwidth-kbps=2048
node relay/match-test.mjs --normal13 --rtt=100 --jitter=10 --bandwidth-kbps=2048
node relay/match-test.mjs --survival --rtt=150 --jitter=15 --bandwidth-kbps=4096 --stall-every=200
node relay/match-test.mjs --normal13 --packed=build/Hordas-DEV-0.14.0/Hordas-DEV-0.14.0.exe --soak-seconds=1800 --render-one --rtt=100 --jitter=10 --bandwidth-kbps=4096 --stall-every=250
```

`--rtt=100` configura aproximadamente 50 ms por direção do trecho cliente/relay. O RTT final inclui serialização, escalonamento, envio pelo host e limites de banda. Um percurso cliente/relay/host/relay/cliente atravessa dois trechos. Não confundir o parâmetro com latência final garantida.

O proxy trabalha sobre um fluxo TCP preservando a ordem. Jitter, banda e bloqueios de 200 ms exercitam congestionamento e head-of-line blocking. Ele não injeta perda de pacotes IP e não representa snapshots UDP descartados. Não houve emulação de perda IP nem teste em quatro máquinas nesta sessão.

Os logs individuais e relatórios JSON ficam em `test_output`. Os perfis de teste usam slots separados. Não sobrescrever saves de jogadores para executar testes.
