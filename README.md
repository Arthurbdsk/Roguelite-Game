# Hordas

Projeto editável em Godot 4.7.2. Inclui código, cenas, mapas, dados de balanceamento, sprites e testes. Não precisa instalar Python ou Node.js para jogar no modo solo pelo editor.

Para jogar no Windows sem instalar o Godot, baixe [Hordas 0.8.0](https://github.com/Arthurbdsk/Roguelite-Game/releases/tag/v0.8.0). O arquivo `.exe` contém todos os recursos. Essa versão inclui a remodelação atual; a nova explosão da bomba e a medição final de desempenho ainda estão pendentes.

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

O código atual inclui a expansão 0.7 e a remodelação visual em andamento: navegação ao redor dos obstáculos, novo herói, Necromante, Médico da Peste, Besta, duas formas do chefe, bomba azul, bumerangue de madeira e Água Benta animada. A nova explosão da bomba e a validação conjunta final dessa remodelação ainda estão pendentes. Os relatórios anteriores não certificam automaticamente essas alterações mais recentes.

## Versão 0.7.0 anterior

Jogo em Godot 4.7.2. Abra `build/Hordas-0.7.0/Hordas-0.7.0.exe` ou `Jogar.cmd`. O executável contém os recursos e pode ser enviado sozinho aos amigos. Todos precisam usar a mesma versão.

WASD ou setas movem. Ataques automáticos. Esc pausa no solo e abre um menu individual online. Tab abre melhorias online. Teclas 1, 2 e 3 escolhem melhorias. Segure E junto a um aliado caído para reviver. F11 alterna tela cheia. F9 abre os testes de chefes, sem conceder progresso permanente.

A versão inclui doze armas, oito passivas, Devorador, Slime grande, Slime pequeno e um demônio com duas fases. Lodo e Água Benta causam dano periódico por dono, sem empilhar dano de poças sobrepostas da mesma arma. A tela de melhorias usa uma lista vertical e mostra os itens e atributos atuais. Coroa concede 7% de experiência individual, preservando frações. Raio escolhe alvos distintos no alcance; Lança Relógio gira em doze direções e controla inimigos.

O salvamento permanece em `%APPDATA%\Godot\app_userdata\Brasafria\profile.json`. O nome interno e os identificadores das habilidades foram preservados para manter o progresso anterior. As versões antigas continuam em `build/`.

O cooperativo usa um túnel WSS temporário embutido no executável. O computador que mantém o relay e o túnel deve continuar ligado e conectado. Ainda falta uma hospedagem permanente. A versão 0.7.0 recusa entrada em salas de outras versões, com uma mensagem clara.

Importe `project.godot` para editar. Os valores estão nos Resources em `data/`. `tools/generate_new_enemies.py` recria os sprites originais de seis quadros, adaptados das referências. Os arquivos PNG completos de referência não são usados como personagens.

Veja `docs/ATUALIZACAO_0_7.md` para implementação, balanceamento e validação. Os demais relatórios preservam os registros de versões anteriores.

Expansão 0.7.0: seis espaços de armas, quatro passivas e oito níveis por item. Três mapas selecionáveis: Pátio, Biblioteca e Campos. Tabelas e medições no relatório da versão.
