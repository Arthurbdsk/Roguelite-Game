# Hordas

Projeto editável em Godot 4.7.2. Inclui código, cenas, mapas, dados de balanceamento, sprites e testes. Não precisa instalar Python ou Node.js para jogar no modo solo pelo editor.

Para jogar no Windows sem instalar o Godot, baixe [Hordas 0.12.0](https://github.com/Arthurbdsk/Roguelite-Game/releases/tag/v0.12.0). O arquivo `.exe` contém todos os recursos. Todos os participantes precisam usar a mesma versão. O serviço público de salas está indisponível nesta publicação; o solo funciona e o cooperativo exige um relay configurado.

## Atualização 0.12.0

Balanceamento, Campos remodelados e oito padrões do chefe final. [Valores e validação](docs/BALANCEAMENTO_0_12.md).

## Painel DEV 0.12.0

Use `Hordas-DEV-0.12.0.exe` e pressione F8 no menu. O painel testa os seis encontros reais, configura builds e controla ataques, fases, tempo e reinícios. O perfil é temporário e o save original permanece intacto. O executável público `Hordas-0.12.0.exe` exclui o painel e seus presets.

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

O modo online exige um relay acessível. As configurações locais não são enviadas ao GitHub: copie `network.cfg.example` para `network.cfg` e informe a URL WSS do relay. O servidor e as instruções estão em [relay/](relay/) e [docs/MULTIPLAYER.md](docs/MULTIPLAYER.md). Para testar na mesma máquina, use `Testar_Coop_Local.cmd` com Node.js instalado e as dependências de `relay/package.json`.

Todos os jogadores precisam usar a mesma versão do projeto. Um endereço temporário de túnel pode parar de funcionar quando o computador que o hospeda for desligado.

## Estado do projeto

O código atual preserva os três mapas, doze armas, oito passivas, dezesseis aprimoramentos permanentes, ouro e cooperação por código. A campanha foi estendida com os encontros da versão 0.10. Os relatórios históricos descrevem as versões em que foram escritos; consulte o relatório 0.10 para os testes atuais.

## Versão 0.7.0 anterior

Jogo em Godot 4.7.2. Abra `build/Hordas-0.7.0/Hordas-0.7.0.exe` ou `Jogar.cmd`. O executável contém os recursos e pode ser enviado sozinho aos amigos. Todos precisam usar a mesma versão.

WASD ou setas movem. Ataques automáticos. Esc pausa no solo e abre um menu individual online. Tab abre melhorias online. Teclas 1, 2 e 3 escolhem melhorias. Segure E junto a um aliado caído para reviver. F11 alterna tela cheia. F9 abre os testes de chefes, sem conceder progresso permanente.

A versão inclui doze armas, oito passivas, Devorador, Slime grande, Slime pequeno e um demônio com duas fases. Lodo e Água Benta causam dano periódico por dono, sem empilhar dano de poças sobrepostas da mesma arma. A tela de melhorias usa uma lista vertical e mostra os itens e atributos atuais. Coroa concede 7% de experiência individual, preservando frações. Raio escolhe alvos distintos no alcance; Lança Relógio gira em doze direções e controla inimigos.

O salvamento permanece em `%APPDATA%\Godot\app_userdata\Brasafria\profile.json`. O nome interno e os identificadores das habilidades foram preservados para manter o progresso anterior. As versões antigas continuam em `build/`.

O cooperativo usa um túnel WSS temporário embutido no executável. O computador que mantém o relay e o túnel deve continuar ligado e conectado. Ainda falta uma hospedagem permanente. A versão 0.7.0 recusa entrada em salas de outras versões, com uma mensagem clara.

Importe `project.godot` para editar. Os valores estão nos Resources em `data/`. `tools/generate_new_enemies.py` recria os sprites originais de seis quadros, adaptados das referências. Os arquivos PNG completos de referência não são usados como personagens.

Veja `docs/ATUALIZACAO_0_7.md` para implementação, balanceamento e validação. Os demais relatórios preservam os registros de versões anteriores.

Expansão 0.7.0: seis espaços de armas, quatro passivas e oito níveis por item. Três mapas selecionáveis: Pátio, Biblioteca e Campos. Tabelas e medições no relatório da versão.
