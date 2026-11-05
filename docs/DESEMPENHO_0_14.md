# Desempenho e cooperativo 0.14.0

## Escopo confirmado

A base 0.13.0 possui geração contínua, estágios de 120 segundos, infinito após a True Form, corpos físicos, cerco de vinte arqueiros, família do Slime Rei com 225 pequenos e baús compartilhados. Foram preservados dificuldade, contagens, dano, intervalos, recompensas, salvamento v4 e autoridade do host.

## Gargalos e mudanças

O custo maior observado foi o trabalho GDScript de vizinhança/IA, seguido por armas e áreas. O tempo dos corpos físicos nativos foi medido separadamente. Não foram removidas colisões para acelerar o teste.

- A divisão do Rei distribui candidatos numa espiral local antes de procurar espaço livre. Ela mantém os quinze filhos por pai e a cadeia de 225, sem adicionar espera artificial.
- Uma passagem prepara pares próximos uma única vez. Separação e limitação de aproximação reutilizam o resultado. Contatos ficam em PackedVector3Array, evitando um Array alocado por contato. Os círculos continuam em CharacterBody2D com movimento e colisão reais; paredes e outros corpos seguem físicos.
- Consultas de espada, projéteis com varredura, retorno, Raio, Lança Relógio, bombas, gelo e lâminas usam as células necessárias, incluindo margem para corpos grandes. Foram retirados percursos globais desses ataques finitos. Poças mantêm a grade já existente e cooldown individual por dono, arma e alvo, agora com chave numérica.
- Obstáculos ganharam uma grade de 96 pixels, reutilizada por testes de chão e segmentos de navegação. O teste compara o resultado com busca completa em posições aleatórias. Paredes de gelo invalidam o índice e os campos ao aparecer e desaparecer.
- A navegação preserva campos compartilhados por tamanho e alvo e caminhos reutilizados. Há orçamento de 48 decisões por passo; decisões excedentes usam a direção anterior até serem planejadas. Movimento, dano e preparação dos ataques continuam a cada passo físico. Adiamentos são visíveis no DEV.
- Sombras, barras e estados dos inimigos não recriam comandos de desenho quando nada mudou. Sprites continuam animando. Poças são desenhadas agrupadas por textura. Efeitos fora da câmera local são omitidos apenas no desenho, mantendo a simulação de todos os jogadores.
- O HUD online passou a atualizar a 10 Hz. Um objeto de consulta física é reutilizado para as varreduras sequenciais das flechas.
- Réplicas de moedas e cristais reutilizam seus dicionários por identidade, em vez de recriá-los a cada snapshot. A escolha de +10 de ouro com build maximizada no cooperativo foi corrigida para creditar o saldo compartilhado pelo contexto correto.
- A rede usa snapshots completos binários comprimidos, substituição apenas do estado ainda não enviado e fila separada de eventos críticos. A implementação e a implantação estão em [ONLINE_0_14.md](ONLINE_0_14.md).

Moedas, cristais, projéteis, poças e efeitos já são gerenciados centralmente como dados, sem um Node e callback por objeto. Não foi adicionada uma reserva ilimitada nem pooling de todos os inimigos por suposição. O profiler não justificou uma migração geral para Server APIs, threads ou GDExtension. O SceneTree não foi acessado por threads.

Os IDs de entidades são seriais monotônicos, sem reutilização de identidades. Snapshots carregam partida e sequência. Não existe slot reciclado recebendo mensagem antiga. O estado completo também remove entidades ausentes após substituição de snapshots.

## Método reproduzível

Windows, Ryzen 5 5600, Radeon RX 6600, Godot 4.7.2, template release oficial, Compatibility/OpenGL. Janela 1280×720 e viewport 640×360, VSync desligado, limite de 120 frames/s. Áudio desativado nos dois ensaios e sem aprimoramentos permanentes. Semente 140031; dois segundos de aquecimento e dez segundos amostrados por cenário. Mediana, p95 e p99 são calculados sobre tempos de frames reais da janela.

Um Hordas 0.12.0 que já estava aberto foi preservado nos dois ensaios. As instâncias dos testes de quatro processos foram encerradas antes da comparação. Essa aplicação em segundo plano é uma limitação de controle do ambiente; os números não devem ser tratados como benchmark isolado do hardware.

A base foi reconstruída do commit `ce9e026`, com a mesma instrumentação e roteiro, sem as otimizações. `tools/baseline14.patch` contém apenas essa instrumentação. A comparação renderizada usa quatro atores e sistemas reais locais com transporte simulado; serialização e sockets são medidos em suítes separadas de quatro processos.

Os cenários densos usam vida elevada apenas como fixture para manter a mesma população viva durante a amostra. Não é um novo atributo de gameplay. A família do Rei é produzida pelos sistemas reais antes da janela de amostragem; os percentis representam combate com os descendentes, não o custo instantâneo da divisão. Chefes e necromantes usam preparação e invocações reais. Infinito começa em 30:00 e mantém o diretor ativo até o limite real, sem descarte de dívida.

Memória residente é coletada pela API Windows GetProcessMemoryInfo a 20 Hz. O contador de memória estática do Godot release retorna zero e não é usado como estimativa de memória do processo. CPU e GPU do viewport são medidos via RenderingServer. Instrumentação adiciona custo; não somar percentis independentes como se fossem um frame específico.

```powershell
python tools/build_baseline14.py
python tools/export_windows.py --smoke
python tools/export_windows.py --dev --smoke
python tools/benchmark14.py
```

Os resultados brutos, contagens, memória, tempos de física, planejamento, dano, coleta e desenho ficam em `docs/benchmarks`. Capturas e logs completos ficam em `test_output`. Não exportar sobre uma build em uso; o exportador bloqueia o caso e o runner de rede usa cópias imutáveis.

## Resultados

Tempos em milissegundos. Cada célula mostra mediana / p95 / p99. Menor é melhor.

| Cenário | Frame antes | Frame depois | Simulação antes | Simulação depois |
|---|---:|---:|---:|---:|
| Início | 7.54 / 10.24 / 10.66 | 7.82 / 9.92 / 10.23 | 1.07 / 1.82 / 2.10 | 0.86 / 1.35 / 1.64 |
| Quatro builds, 225 inimigos | 14.13 / 93.24 / 142.43 | 9.10 / 19.79 / 21.25 | 13.48 / 22.52 / 25.30 | 8.62 / 13.63 / 15.27 |
| Chefe e necromantes | 19.78 / 199.91 / 209.39 | 12.88 / 19.77 / 49.45 | 18.10 / 28.83 / 32.88 | 11.00 / 16.93 / 21.76 |
| 225 descendentes | 14.02 / 69.90 / 165.28 | 10.76 / 19.43 / 21.20 | 13.68 / 23.29 / 27.48 | 10.05 / 14.94 / 16.97 |
| Cerco de arqueiros | 7.33 / 11.07 / 12.40 | 9.41 / 10.49 / 10.94 | 0.98 / 3.15 / 3.77 | 1.15 / 1.86 / 2.16 |
| Infinito em 30:00 | 14.53 / 145.01 / 160.50 | 11.16 / 19.33 / 21.04 | 14.64 / 24.03 / 27.24 | 10.18 / 14.88 / 17.36 |

| Cenário | Inimigos antes/depois | Poças antes/depois | Projéteis antes/depois | Draw calls antes/depois | RSS MB antes/depois | Nós antes/depois |
|---|---:|---:|---:|---:|---:|---:|
| Início | 12/12 | 0/0 | 0/0 | 75/75 | 189.7/189.4 | 299/299 |
| Quatro builds, 225 inimigos | 225/225 | 120/120 | 0/0 | 920/922 | 204.7/198.3 | 957/957 |
| Chefe e necromantes | 240/240 | 120/120 | 93/95 | 996/1000 | 210.6/203.5 | 1021/1029 |
| 225 descendentes | 225/225 | 120/120 | 0/0 | 959/920 | 210.7/204.8 | 995/995 |
| Cerco de arqueiros | 20/20 | 120/120 | 16/16 | 338/217 | 209.0/203.8 | 399/399 |
| Infinito em 30:00 | 240/240 | 120/120 | 1/1 | 1072/1030 | 210.7/205.4 | 1078/1078 |

Custos separados na carga de quatro builds. Navegação é parte de IA; os valores não devem ser somados novamente.

| Componente | Antes, ms | Depois, ms |
|---|---:|---:|
| IA, movimento e pares | 9.17 / 13.20 / 14.59 | 5.24 / 6.90 / 8.91 |
| Corpos físicos, incluídos na linha anterior | 0.98 / 1.51 / 1.70 | 0.90 / 1.58 / 1.73 |
| Planejamento, incluído em IA | 0.45 / 2.11 / 2.53 | 0.26 / 0.48 / 0.56 |
| Armas e dano | 3.04 / 4.19 / 5.11 | 2.62 / 4.09 / 5.40 |
| Ouro e índice de comida | 0.02 / 0.04 / 0.05 | 0.03 / 0.04 / 0.06 |
| Coleta de XP | 0.01 / 0.01 / 0.02 | 0.01 / 0.01 / 0.02 |
| Ataques e efeitos inimigos | 0.03 / 0.04 / 0.05 | 0.03 / 0.04 / 0.05 |
| Desenho CPU do viewport | 1.08 / 1.74 / 2.08 | 1.08 / 2.00 / 2.28 |
| Desenho GPU do viewport | 0.63 / 1.42 / 1.99 | 0.50 / 1.49 / 2.43 |

A meta de 60 FPS constantes não foi atingida em toda a distribuição de frames: 16,67 ms é o orçamento por frame, e os p95 dos cenários densos ainda o excedem. Houve redução forte dos picos, sem reduzir a população. Draw calls não melhoraram em todos os casos; o gargalo principal medido foi CPU.

Carga extrema adicional, em exportações release com janela e roteiro próprio: 420 corpos físicos, 320 flechas repostas pelo fixture e 120 poças mantidas por duração artificial de teste. Isso não altera os dados do jogo distribuído.

| Carga extrema | Antes | Depois |
|---|---:|---:|
| Frame ms | 288.55 / 324.89 / 354.11 | 193.43 / 208.73 / 215.19 |
| Simulação ms | 28.19 / 48.49 / 52.58 | 19.13 / 28.33 / 31.90 |
| RSS MB | 217.9 | 218.0 |
| Inimigos / flechas / poças, picos | 420/320/120 | 420/320/132 |

O fixture extremo repõe pelo menos 120 poças; as armas continuam criando as suas. Por isso o pico posterior chegou a 132. As populações de 420 inimigos e 320 flechas foram preservadas. Esse teste inclui diferenças de evolução temporal e não representa uma comparação com quantidade idêntica de todas as poças em cada instante. A forte diferença entre frame e passo de simulação também expõe o acúmulo de trabalho físico durante os frames lentos.

Pico de criação, medição única de CPU headless com quatro atores e os PCKs release: quinze azuis 30.95 → 5.58 ms; 225 pequenos 332.69 → 81.09 ms. Não é medição de FPS. A nova distribuição espacial procura posições ao redor da morte antes da busca local, mantendo todos os filhos. Ainda existe hitch no nascimento simultâneo; os percentis de combate acima excluem essa preparação.

Rede, mesmo roteiro local de quatro processos, 180 inimigos, 2.000 moedas e 240 cristais. Bytes de aplicação; não incluem cabeçalhos TCP, WebSocket ou TLS. Taxas médias sobre a duração de cada conexão, não pico de banda.

| Medida | Antes | Depois |
|---|---:|---:|
| Upload do host, KB/s | 61.03 | 12.95 |
| Recebimento médio por cliente, KB/s | 61.91 | 13.79 |
| Upload total do relay para os três clientes, KB/s | 185.72 | 41.38 |
| Maior mensagem do host, bytes | 347206.00 | 11391.00 |

O estado foi reduzido por codificação e compressão, não por deixar de enviar inimigos ou recompensas. Os ensaios de atraso/banda e a sessão longa são separados dessa comparação de tráfego.

## Testes e limites

Foram executados testes de bordas de células, corpos de tamanhos diferentes, 120 corpos em movimento, corredores, obstáculos, gelo dinâmico, arma/poça, XP e ouro fracionários, preços históricos e reembolso, limites da build, campanha e fases, infinito e baús. As suítes dos pacotes verificam que F8 e os recursos DEV estão ausentes no público e presentes somente no DEV.

Os testes de rede separam quatro processos locais, emulação TCP e internet real. Foram exercitados parâmetros de RTT 50/100/150 ms, jitter, banda limitada e stalls de 200 ms. O stall simula bloqueio do fluxo; não é uma alegação de perda IP real.

### Sessão de trinta minutos

Quatro processos separados, um renderizado, passaram por 1.800,012 segundos de relógio real, sem aceleração do roteiro, sem erros do motor e sem desconexões inesperadas. O roteiro confirmou Demônio, Guardião, Abominação e entrada no infinito. Usa invulnerabilidade e comandos de teste para alcançar os encontros; não equivale a uma partida humana. Os testes curtos separados cobrem escolhas individuais, coleta, reanimação, derrota, baús e saída do host.

Condições: RTT configurado de 100 ms no trecho cliente/relay, jitter de 10 ms, banda de 4.096 kbps e bloqueio TCP de 200 ms a cada 250 blocos. O proxy transportou cerca de 1,08 GB e registrou 1.496 bloqueios. A fila pendente do relay atingiu idade máxima de 26 ms; a fila de saída observada no host permaneceu vazia. A fila do proxy chegou a 100.299 bytes. Esses são três pontos distintos de medição.

Tráfego de aplicação médio: aproximadamente 148,4 KB/s de upload do host; 146,6 KB/s recebidos por cliente; cerca de 440 KB/s de upload total do relay para os três clientes. A carga prolongada é mais pesada que o fixture curto da tabela de tráfego. Não tratar a economia do fixture como banda fixa para toda partida.

| Medida no cliente renderizado | Mediana | p95 | p99 |
|---|---:|---:|---:|
| RTT até o relay, ms | 134 | 232 | 366 |
| RTT pelo host, ms | 358 | 570 | 660 |
| Intervalo entre snapshots, ms | 133 | 235 | 334 |
| Aplicar snapshot, ms | 4,788 | 16,439 | 20,433 |
| Decodificar snapshot, ms | 2,673 | 6,255 | 8,462 |
| Serializar no host, ms | 3,550 | 9,034 | 10,230 |

A maior correção de posição medida nesse cliente foi 10,80 pixels; a última amostra tinha snapshot com 15 ms de idade. Percentis de processamento usam as últimas 600 amostras; RTT usa o histórico limitado do teste, não todos os frames. O RTT pelo host inclui dois trechos via relay, processamento e congestionamento, portanto excede o parâmetro de 100 ms.

Evidência: execução `1793907692011`, quatro registros `COOP_MATCH_PEER_PASS`, `SOAK_DURATION wall_ms=1800012`, campanha completa e `endless=true`. O candidato testado por trinta minutos antecede dois ajustes finais: distribuição espacial mais barata dos filhos e correção de deriva do relógio de envio. A versão exportada final passou novamente pelas suítes de colisão, codec, isolamento DEV, eventos e quatro processos com RTT 100 ms. A sessão longa não foi repetida após esses dois ajustes. Os benchmarks renderizados finais usam o hash do executável entregue, registrado nos JSONs.

Ainda dependem de validação externa: quatro máquinas, redes distintas, disponibilidade/certificado WSS do servidor público e perda real de pacotes IP. Sem servidor persistente e domínio configurados, a publicação do relay permanente permanece bloqueada. Não houve contratação automática nem túnel apresentado como servidor permanente.

## Referências aplicadas

- [Naio Games](https://naiogames.com/guides/godot-2d-horde-performance): medição, atualizações centralizadas, grade, redução de alocações e agrupamento por textura; os benchmarks do artigo não foram usados como previsão.
- [Factorio FFF-317](https://www.factorio.com/blog/post/fff-317): reaproveitamento do trabalho de busca e resultados compartilhados. A decisão deles de remover colisão entre unidades não foi adotada.
- [Godot: CPU](https://docs.godotengine.org/en/stable/tutorials/performance/cpu_optimization.html): concentrar mudanças nos custos medidos e separar a instrumentação.
- [Godot: Servers](https://docs.godotengine.org/en/stable/tutorials/performance/using_servers.html): APIs de baixo nível são uma opção quando o custo medido justifica a complexidade. Não foi feita reescrita preventiva.
- [Godot: navegação](https://docs.godotengine.org/en/stable/tutorials/navigation/navigation_optimizing_performance.html): evitar consultas redundantes e distribuir decisões.
- [Godot: multiplayer](https://docs.godotengine.org/en/stable/tutorials/networking/high_level_multiplayer.html): distinguir transporte confiável de autoridade e reconhecer o bloqueio causado pelo TCP.
- [Snapshot Compression](https://gafferongames.com/post/snapshot_compression/): um delta depende de baseline conhecido. A implementação escolhe estado completo comprimido para permitir substituição segura antes do envio, sem uma cadeia de baselines por cliente.
