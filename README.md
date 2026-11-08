# Hordas Android

Entrega atual 0.25.1-android.3, compatível com PC 0.25.1, protocolo 2, conteúdo 0.25.1+f69263393c14aee1. Arquivo local: build/Hordas-Android-0.25.1-3.apk. Instale por cima da versão anterior, sem desinstalar, para preservar o progresso.

Coop com quatro jogadores: 1,7 vezes o dano e 2 vezes a geração, vida/velocidade do solo. Android solo com 40% menos geração contínua e inimigos 20% menores visualmente. PC solo preservado. [Entrega, testes e limites](docs/ANDROID_0_25_3.md).

Android volta a ficar congelado. [Política de manutenção](docs/ANDROID_POLICY.md). Não houve publicação em loja ou GitHub Releases. Exportação manual somente por pedido autorizado, via python tools/android/export_android.py --android-request. Chaves fora do repositório; o APK QA separado não é a entrega pública.

## Histórico da base de PC

Android é mantido **somente sob pedido explícito de celular, Android ou versão mobile**, separado em `codex/android-mobile`. Pedidos genéricos continuam exclusivos do PC. [Política de congelamento e base identificada](docs/ANDROID_POLICY.md).

Versão PC 0.23.0: correções de descarte e identificação de flechas remotas, Machado com três acertos e descarte fora da câmera lógica, Varinha Mágica com +1 s, fogo aliado com dano dobrado, personagens 10% maiores e inimigos com +30 de vida-base. [Testes e pendências](docs/CORRECOES_PC_0_23.md).

Versão PC 0.22.0: arte original animada para Morcego, Necromante, esqueletos, variantes com armadura, Orc de elite, Orc montado e família de slimes. Água Benta com frasco, impacto e poça novos. Mecânicas e IDs preservados. [Comparações, arquivos editáveis, testes e limitações](docs/ARTE_PC_0_22.md).

Executável histórico da base: `build/Hordas-0.23.0/Hordas-0.23.0.exe`. DEV: `build/Hordas-DEV-0.23.0/Hordas-DEV-0.23.0.exe`, F8. Todos os participantes precisam usar PC 0.23.0. Essa restrição descreve a entrega histórica 0.23.0; a atualização autorizada atual consta no início deste arquivo.

Versão 0.20.0: Soldado e Orc animados da coleção Tiny RPG, com os atributos e IDs anteriores preservados. Escopo limitado aos dois personagens gratuitos, conforme escolhido. [Comparação, animações, licença e testes](docs/TINY_RPG_0_20.md).

Projeto editável em Godot 4.7.2. Inclui código, cenas, mapas, dados de balanceamento, sprites e testes. Não precisa instalar Python ou Node.js para jogar no modo solo pelo editor. Para usar/exportar a fonte decorativa licenciada do cronômetro a partir do código, copie seu arquivo autorizado para `assets/fonts/AurusenthialGothic.ttf`; o TTF avulso fica fora do GitHub, enquanto os executáveis incluem a fonte autorizada.

Para preparar o Soldado e o Orc comum, baixe o pacote gratuito oficial de [Zerie](https://zerie.itch.io/tiny-rpg-character-asset-pack), instale Pillow e execute `python tools/tiny_rpg20.py --kind soldier` e `python tools/tiny_rpg20.py --kind orc`. Use `--source "pasta do pacote"` quando estiver fora de Downloads. Os atlas Tiny RPG avulsos ficam fora do GitHub devido à proibição de republicar os assets separadamente; estão incorporados nos executáveis. Os demais personagens novos são arte original do projeto, editável em `assets/v22/`, com fontes e prompts documentados em `docs/art22/`.

Para jogar no Windows sem instalar o Godot, baixe [Hordas PC 0.23.0](https://github.com/Arthurbdsk/Roguelite-Game/releases/tag/v0.23.0). O arquivo `.exe` contém todos os recursos e o endereço público do relay. Todos os participantes precisam usar a mesma versão. A hospedagem gratuita no Render pode demorar cerca de um minuto para iniciar após ficar inativa; aguarde a conexão no menu Online.

## Atualização 0.15.0

Tema azul-acinzentado com bordas douradas, coleção de 25 itens reais e descobertas individuais. Cinco consumíveis de coleta imediata: Limpeza, Comida, Bolsa de Ouro, Ímã de Experiência e Relógio. Não ocupam a build. [Parâmetros, frequência medida, execução e limitações](docs/ATUALIZACAO_0_15.md). DEV: F8, aba Consumíveis; estatísticas na aba Desempenho. Salvamentos e regras de combate anteriores preservados.

## Atualização 0.14.1

Relay publicado em `wss://hordas-relay.onrender.com`. Criador abre Online, cria sala e compartilha o código com até três amigos. Todos entram, marcam Pronto e o criador inicia. Um `network.cfg` antigo ao lado do executável pode substituir o endereço embutido; remova a configuração antiga se ela apontar para um túnel desativado. O cliente aguarda a inicialização do serviço gratuito, sem manter o servidor acordado artificialmente. [Testes externos e limites](docs/ONLINE_0_14.md).

## Atualização 0.14.0

Otimização de consultas espaciais e navegação, lotes de poças, snapshots binários comprimidos, filas separadas e implantação permanente preparada. [Desempenho e testes](docs/DESEMPENHO_0_14.md). [Cooperativo e implantação](docs/ONLINE_0_14.md).

## Painel DEV PC

Use `Hordas-DEV-0.22.0.exe` e pressione F8 no menu. O painel testa os seis encontros reais, configura builds e controla ataques, fases, tempo, consumíveis e reinícios. O perfil é temporário e o save original permanece intacto. O executável público `Hordas-0.22.0.exe` exclui o painel e seus presets.

Guia e testes: [docs/MODO_DEV_0_11.md](docs/MODO_DEV_0_11.md). `Testar_Chefes_DEV.cmd` abre a build DEV exportada. O projeto aberto no Godot também habilita o F8. Para salas de desenvolvimento, todos precisam usar a mesma build DEV e abrir Sala DEV pelo painel.

## Campanha 0.10.0

A partida continua após o Demônio dos dez minutos. Guardião aos quinze minutos; Abominação e True Form aos vinte. Inclui espera corrigida do herói, gelo com avisos próximos aos jogadores, paredes sólidas no novo chefe, explosão animada da bomba e novos sprites. Na versão atual, F8 na build DEV substitui o laboratório F9. Os arquivos `Testar_*.cmd` dos chefes apontam para o executável DEV.

A imagem da fonte Kingdom foi recebida, mas o arquivo TTF/OTF não foi fornecido. A fonte anterior continua ativa; o tema central está preparado para `assets/fonts/Kingdom.ttf`, com apoio para acentos.

Valores, testes e limitações de desempenho estão em [docs/ATUALIZACAO_0_10.md](docs/ATUALIZACAO_0_10.md).

## Aprimoramentos permanentes 0.9.0

A árvore foi substituída pela grade com 16 aprimoramentos, compra com ouro, reembolso confirmado, migração do save, Desafio configurável e Reviver individual. Baixe [Hordas 0.9.0 para Windows](https://github.com/Arthurbdsk/Roguelite-Game/releases/tag/v0.9.0). Preços, efeitos, regras de migração e testes estão em [docs/APRIMORAMENTOS_0_9.md](docs/APRIMORAMENTOS_0_9.md). Online, use R enquanto caído para consumir seu retorno; a reanimação por aliado não consome esse uso.

## Abrir em outra máquina

1. Baixe este repositório em **Code > Download ZIP** e extraia, ou use `git clone https://github.com/Arthurbdsk/Roguelite-Game.git`.
2. Instale o Godot 4.7.2, edição padrão, sem .NET.
3. No Godot, clique em **Importar**, selecione `project.godot` e aguarde a importação dos recursos.
4. Aperte **F5** para iniciar o jogo.

No Windows, `Jogar.cmd` também procura o executável já exportado ou o Godot instalado. O projeto não inclui o cache `.godot`, executáveis de compilação nem o progresso pessoal. Esses arquivos são gerados localmente.

## Multiplayer

O modo online exige um relay acessível. As configurações locais não são enviadas ao GitHub: copie `network.cfg.example` para `network.cfg` e informe a URL WSS do relay. O servidor e as instruções estão em [relay/](relay/) e [docs/ONLINE_0_14.md](docs/ONLINE_0_14.md). Para testar na mesma máquina, use `Testar_Coop_Local.cmd` com Node.js instalado e as dependências de `relay/package.json`.

Todos os jogadores precisam usar a mesma versão do projeto. Um endereço temporário de túnel pode parar de funcionar quando o computador que o hospeda for desligado.

## Estado do projeto

O código atual preserva os três mapas, doze armas, oito passivas, dezesseis aprimoramentos permanentes, ouro e cooperação por código. A campanha foi estendida com os encontros da versão 0.10. Os relatórios históricos descrevem as versões em que foram escritos; consulte o relatório 0.14 para os testes atuais.

## Versão 0.7.0 anterior

Jogo em Godot 4.7.2. Abra `build/Hordas-0.7.0/Hordas-0.7.0.exe` ou `Jogar.cmd`. O executável contém os recursos e pode ser enviado sozinho aos amigos. Todos precisam usar a mesma versão.

WASD ou setas movem. Ataques automáticos. Esc pausa no solo e abre um menu individual online. Tab abre melhorias online. Teclas 1, 2 e 3 escolhem melhorias. Segure E junto a um aliado caído para reviver. F11 alterna tela cheia. F9 abre os testes de chefes, sem conceder progresso permanente.

A versão inclui doze armas, oito passivas, Devorador, Slime grande, Slime pequeno e um demônio com duas fases. Lodo e Água Benta causam dano periódico por dono, sem empilhar dano de poças sobrepostas da mesma arma. A tela de melhorias usa uma lista vertical e mostra os itens e atributos atuais. Coroa concede 7% de experiência individual, preservando frações. Raio escolhe alvos distintos no alcance; Lança Relógio gira em doze direções e controla inimigos.

O salvamento permanece em `%APPDATA%\Godot\app_userdata\Brasafria\profile.json`. O nome interno e os identificadores das habilidades foram preservados para manter o progresso anterior. As versões antigas continuam em `build/`.

O cooperativo usa um túnel WSS temporário embutido no executável. O computador que mantém o relay e o túnel deve continuar ligado e conectado. Ainda falta uma hospedagem permanente. A versão 0.7.0 recusa entrada em salas de outras versões, com uma mensagem clara.

Importe `project.godot` para editar. Os valores estão nos Resources em `data/`. `tools/generate_new_enemies.py` recria os sprites originais de seis quadros, adaptados das referências. Os arquivos PNG completos de referência não são usados como personagens.

Veja `docs/ATUALIZACAO_0_7.md` para implementação, balanceamento e validação. Os demais relatórios preservam os registros de versões anteriores.

Expansão 0.7.0: seis espaços de armas, quatro passivas e oito níveis por item. Três mapas selecionáveis: Pátio, Biblioteca e Campos. Tabelas e medições no relatório da versão.
