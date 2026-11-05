# Modo de desenvolvimento dos chefes 0.11.0

## Acesso

Use `Hordas-DEV-0.11.0.exe`, ou execute o projeto no Godot. No menu inicial, pressione F8. Durante o teste, F8 abre e fecha o painel; fechar o painel não encerra o modo. O indicador MODO DEV permanece visível. O botão Encerrar teste limpa a arena e retorna ao menu, restaurando o perfil original e a velocidade do tempo.

A entrada é feita pelo menu inicial ou pela base. F8 não transforma uma partida normal em teste no meio da run, para não descartar recursos dessa partida. Encerre a run normalmente antes de entrar no laboratório.

A versão pública `Hordas-0.11.0.exe` não contém `scripts/dev/` nem `data/dev/`. Não mostra o laboratório no menu, não responde a F8 e ignora os antigos argumentos de encontro. Não existe um argumento que habilite o painel no pacote público. A build DEV tem a feature de exportação `dev_tools`, além dos recursos próprios do painel. F9 foi removido.

## Aba Encontro

Escolha Carrasco, Demônio fase 1, Demônio fase 2, Guardião, Abominação ou True Form. São as mesmas classes e controladores usados na partida normal. As fases iniciais mantêm a transformação natural. A entrada direta na segunda fase executa a transformação real para calcular vida e limpar efeitos, sem aplicar a escala novamente.

Escolha Pátio, Biblioteca ou Campos, a escala de um a quatro jogadores e a presença de hordas comuns. Iniciar encontro aplica as escolhas; Reiniciar mantém a configuração aplicada. Mapa, escala e hordas entram em vigor no início ou reinício. O relógio começa em 5, 10, 15 ou 20 minutos e o cronograma automático fica suspenso. O Carrasco automático também fica suspenso, mesmo com hordas ligadas.

As hordas usam as composições e os limites reais. Elas podem continuar enquanto o chefe está vivo. Hordas desativadas não desativam invocações próprias do chefe.

Tempo: 0,5x, 1x e 2x, com alteração imediata e sincronizada pelo host. Ao encerrar o modo, a velocidade anterior é restaurada.

## Aba Jogador

Cada jogador pode configurar nível 1 a 999, seis espaços de armas, quatro de passivas e nível 1 a 8 por item. Vazio remove o item do espaço. Itens repetidos são rejeitados. Aplicar build recalcula a partir da base, sem acumular bônus de aplicações anteriores, e cura o jogador.

Aprimoramentos do perfil usa os níveis já adquiridos pelo dono do personagem, a partir de uma cópia temporária. Desmarcar remove esses efeitos do teste. Isso não ocupa espaços da run.

Invulnerável bloqueia dano de contato, projéteis e veneno. Ataques automáticos interrompe a criação de novos ataques; projéteis e poças já existentes terminam normalmente. Curar completamente restaura a vida e permite levantar um personagem caído no teste. Esses controles são individuais nas salas DEV.

A aba mostra os atributos finais da build aplicada: vida, defesa, movimento, dano, intervalo, coleta, experiência e os valores de cada arma. Depois de editar os espaços, pressione Aplicar build para atualizar os atributos. Carregar preset já aplica a preparação para visualizar os valores.

### Presets editáveis

Arquivo: `data/dev/presets.json`. Os níveis abaixo são pontos de partida para testes, não uma afirmação de build média ou equilíbrio humano.

| Preset | Nível | Armas e níveis | Passivas e níveis |
|---|---:|---|---|
| 5 min | 18 | Espada 4, Arco 3, Orbes 2 | Botas 2, Armadura 2 |
| 10 min | 59 | Espada 8, Arco 8, Orbes 6, Raio 6, Lança Relógio 5, Água Benta 5 | Coração 4, Armadura 4, Botas 4, Coroa 4 |
| 15 min | 80 | Espada, Arco, Orbes, Raio, Lança Relógio e Água Benta, todos 8 | Coração, Armadura, Botas e Coroa, todos 8 |
| 20 min | 96 | Mesmas seis armas do preset de 15 min, todas 8 | Mesmas quatro passivas do preset de 15 min, todas 8 |

Sem aprimoramentos permanentes:

| Preset | Vida máxima | Defesa fixa | Movimento, px/s | Experiência |
|---|---:|---:|---:|---:|
| 5 min | 100 | 2 | 112 | +0% |
| 10 min | 140 | 4 | 128 | +28% |
| 15 e 20 min | 180 | 8 | 160 | +56% |

Os valores completos das armas são calculados com os dados atuais e exibidos na aba. Alterar tabelas de armas atualiza automaticamente a exibição, sem manter outra versão de dano no laboratório.

## Aba Chefe

Mostra vida atual/máxima, fase, estado, ataque preparado, temporizador, invocações vivas, movimento, dano real por tipo de poder, congelamento e repetição.

- Executar ataque: agenda uma execução específica, usando a preparação e a recuperação normais.
- Repetir somente este: mantém o ataque escolhido, respeitando limites de efeitos e invocações. Pode aguardar uma conjuração anterior liberar o orçamento.
- Sequência normal: remove o pedido forçado e retorna à sequência do chefe.
- Congelar chefe: suspende movimento, ataques e temporizadores do chefe; os efeitos já criados continuam funcionando.
- Definir vida: ajusta de 1% a 100%. Para transição ou morte, use Próxima fase ou cause dano na arena.
- Próxima fase: usa o dano e a transição reais no Demônio e na Abominação. No Carrasco, reduz a vida para ativar sua fase enfurecida. Guardião e formas finais não ganham uma fase adicional.

O reinício remove inimigos, projéteis, poças, marcas, invocações, paredes sólidas e seus colisores. As mesmas configurações de build, mapa e escala são reaplicadas a partir da base.

## Salas DEV

No painel, use Sala DEV para abrir a entrada de salas sob o perfil temporário. Todos precisam usar a mesma build DEV, entrar pelo F8 e configurar a própria build. As salas usam um identificador de versão separado das salas comuns.

Marque todos como prontos e inicie a sala. Ela fica em preparação, sem cronograma automático. O host abre F8 e inicia o encontro quando recebeu as configurações de todos. Clientes só podem alterar a própria build, invulnerabilidade, ataques e cura. Comandos de encontro enviados por cliente são ignorados.

O host escolhe encontro, mapa, escala e hordas, força ataques, controla fases, congela e altera o tempo. Inícios, fases, reinícios, paredes e encerramento são sincronizados. Cada build é validada pelo host por IDs, espaços e níveis; os bônus permanentes são derivados dos níveis individuais aceitos pela sessão.

Simular uma escala não cria personagens nem substitui o teste de rede. Os multiplicadores existentes são: vida/dano `1 + 0,5 × (jogadores - 1)`, movimento `1 + 0,2 × (jogadores - 1)` e quantidade `1 + 0,8 × (jogadores - 1)`. A escala é aplicada uma vez. A transformação só multiplica a vida já calculada.

As conexões entre redes diferentes continuam exigindo um relay WSS ativo. Esta atualização não hospeda um serviço público novo. Para teste local, execute `Testar_Coop_DEV_Local.cmd`: ele abre um relay local e quatro janelas DEV com perfis separados, já na entrada de salas. Requer Node.js e `npm ci` na pasta `relay`. Feche as janelas para encerrar o relay. Os comandos automatizados abaixo validam a mesma configuração sem intervenção humana.

## Proteção do save

Ao entrar, o laboratório mantém a referência do perfil original e cria uma cópia profunda em memória. A classe do perfil temporário recusa gravação, carregamento e recompensa. O encerramento normal de teste também desvia do pagamento de progresso. Ouro, vitórias, desbloqueios, custos e retorno não são consumidos no perfil original. Configuração de build não é gravada no progresso normal.

Ao sair, a referência original, as preferências e o tempo anterior são restaurados. Entrar e sair não migra o formato do save. O formato 4 e o diretório Brasafria foram preservados. As suítes usam perfis isolados; nenhuma delas escreve o perfil normal do jogador.

## Execução e testes

- Quatro suítes DEV: isolamento, encontros, ataques e painel. Os seis encontros foram iniciados nos três mapas, totalizando 18 combinações. Foram exercitados 30 ataques com a preparação e a recuperação reais.
- Transições naturais e entrada direta nas fases finais, escala sem duplicação, repetição/retorno à sequência normal, congelamento com efeitos ativos, hordas opcionais, cura, invulnerabilidade e ataques ligados/desligados.
- Reaplicação de build e reinício com atributos idênticos, arquivos de save comparados byte a byte e benefício de retorno intacto ao sair. Uma run normal após sair voltou a creditar ouro normalmente.
- Painel renderizado na arena, com três abas, dez espaços de itens, rolagem e rejeição de duplicatas. Capturas em `test_output/11-dev-panel-*.png`.
- Quatro processos Godot reais: builds individuais, atributos próprios, host exclusivo, rejeição de comando remoto indevido, controle individual de invulnerabilidade/cura, transformação, colisores, reinício, tempo sincronizado e restauração dos saves.
- Mesmas verificações usando o PCK DEV exportado. A feature `dev_tools` foi confirmada no pacote.
- PCK público: ausência dos arquivos DEV, F8 inerte e chamadas antigas bloqueadas. O runner muda o diretório de trabalho para a pasta do pacote para evitar recorrer aos arquivos do checkout.
- Regressões de animação, progressão de itens, aprimoramentos/persistência, Reviver, Desafio, protocolo e campanha cooperativa comum, incluindo o PCK público.
- Os dois executáveis passaram no smoke nativo de 120 frames. As verificações comportamentais dos pacotes usam o runtime de editor Godot 4.7.2 correspondente, com `--main-pack`; não são partidas humanas.

Comandos:

```powershell
python tools/validate_dev11.py
node relay/match-test.mjs --dev
python tools/export_windows.py --dev --smoke
python tools/validate_dev11.py --packed=build/Hordas-DEV-0.11.0/Hordas-DEV-0.11.0.exe dev_feature11 dev_sandbox11 dev_encounters11 dev_attacks11 dev_panel11
node relay/match-test.mjs --dev --packed=build/Hordas-DEV-0.11.0/Hordas-DEV-0.11.0.exe
python tools/export_windows.py --smoke
python tools/validate_dev11.py --packed=build/Hordas-0.11.0/Hordas-0.11.0.exe dev_public11
```

Limites: não houve teste com quatro pessoas em redes diferentes nem nova avaliação de equilíbrio ou FPS da campanha. O painel usa os efeitos, limites e dificuldades existentes; não corrige a queda de desempenho das cargas extremas registrada na versão 0.10.
