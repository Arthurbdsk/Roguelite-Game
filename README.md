# Brasafria

Protótipo jogável 0.4.1 em Godot 4.7.2 e GDScript. Uma sentinela enfrenta hordas no Pátio dos Esquecidos, investe ouro em habilidades permanentes e enfrenta o Carrasco e o Devorador de Brasas.

## Jogar

Feche a versão anterior e abra `build/Online-Atualizado/Brasafria-Online-0.4.1.exe` ou `Jogar.cmd`. O executável é independente e contém os recursos. Não exige instalar a Godot. Versões e cópias anteriores do perfil estão preservadas em `build/backups/`. As versões compartilham um perfil; não mantenha duas instâncias normais abertas no mesmo computador. O teste cooperativo local usa quatro perfis separados.

WASD ou setas movem o personagem. Os ataques são automáticos e escolhem o inimigo mais próximo. Esc pausa no solo; no cooperativo abre um menu individual enquanto a partida continua. Tab abre melhorias individuais online. Segure E, parado junto a um aliado caído, para revivê-lo em cinco segundos. 1, 2 e 3 selecionam melhorias. F11 alterna tela cheia. Analógico esquerdo, direcional e navegação de menus estão mapeados para controle, ainda sem teste com hardware físico.

São três armas com cinco níveis, cinco passivas, cinco tipos de inimigos e dois chefes. A árvore de 16 nós é acessível no título e na fortaleza. Compras usam ouro, possuem pré-requisitos e salvam imediatamente. Os bônus são aplicados uma vez na nova partida. A vaga padrão de três passivas pode virar quatro pela especialização Pacto das três. A fortaleza mantém os dois apoios antigos, comprados com selos.

Não há prazo fixo de partida. A preparação inicial dura 2,5 segundos; entre hordas, cinco segundos. Espadachins entram na horda 3 e arqueiros na 5. O Carrasco chega aos cinco minutos com 936 de vida, golpe de execução, investida e segunda fase. A última horda espera sua derrota se necessário. O Devorador de Brasas surge por um portal no centro na horda 10, com 1.872 de vida e três fases. Nessa luta, as hordas param e o demônio controla reforços limitados. O altar original permanece disponível após dois minutos.

Todo inimigo deixa ouro. Moedas permanecem por 60 segundos de partida, são atraídas por proximidade e só contam quando chegam ao corpo. A pausa interrompe seu tempo de vida. Ouro dourado e experiência azulada possuem leitura distinta.

Os chefes também concedem um bônus de conclusão único: 30 de ouro pelo Carrasco e 120 pelo demônio. Esses bônus são separados das moedas no chão. Na morte do demônio, ataques, áreas e invocações são retirados, sua animação de morte termina e a vitória salva o saldo uma vez.

## Cooperativo

O menu inclui criação e entrada em salas por código, prontidão e partidas para até quatro pessoas. O host simula o mundo; experiência e ouro são integrais para cada participante, com builds privadas e salvamento individual. Reanimação, espectadores, dificuldade congelada no início e desconexões estão integrados.

A versão online distribuída usa um endereço WSS temporário já embutido no executável. O servidor e o túnel precisam continuar rodando no computador de Arthur, que não pode entrar em suspensão. Para jogar e revisar no mesmo computador, abra `Testar_Coop_Local.cmd`: ele executa o relay local e abre quatro janelas do executável, com nomes e perfis separados. Crie uma sala na primeira e use o código nas outras. Precisa do Node.js e das dependências já instaladas em `relay/`. Isso não valida conexão entre redes diferentes. Veja `docs/MULTIPLAYER.md`.

## Testar os chefes

Pressione F9 no título ou na fortaleza. Também pode abrir `Testar_Carrasco.cmd` ou `Testar_Demonio.cmd`. O Carrasco usa uma build de armas nível 4; o demônio, três armas evoluídas nível 5. Ambas incluem Passo 2, Selo 2 e Ímã 2, sem habilidades permanentes. Nesse modo, ouro e resultados não são gravados. Reiniciar repete o mesmo chefe; voltar ao título e jogar inicia uma partida normal.

## Editar

Importe `project.godot` na Godot e pressione F6 na cena principal ou F5 para executar o projeto. Cenas, Resources `.tres`, scripts e PNGs acompanham o projeto. `tools/generate_assets.py` recria a arte original, `tools/generate_skeletons.py` gera esqueletos e ouro, e `tools/generate_bosses.py` gera os chefes. A fonte possui licença OFL; as licenças da Godot estão incluídas.

- `scripts/main.gd`: estados, experiência, coleta, evento e encerramento.
- `scripts/entities/`: jogador, inimigos e dados de inimigos.
- `scripts/combat/`: armas e escolhas.
- `scripts/combat/enemy_projectiles.gd`: flechas com trajetória fixa, colisão e descarte.
- `scripts/world/gold_loot.gd`: moedas, atração, expiração e coleta.
- `scripts/world/`: arena e diretor de hordas.
- `scripts/core/`: salvamento e áudio.
- `scripts/progression/`: compra de habilidades e aplicação por partida.
- `scripts/bosses/`: estados dos chefes, portal, poderes e limpeza.
- `data/skills/catalog.tres`: custos, níveis, efeitos e pré-requisitos dos 16 nós.
- `data/bosses/balance.tres`: vida, velocidades, dano, intervalos, entrada e limites dos chefes.
- `scripts/ui/`: interface nativa e menus.
- `data/`: valores editáveis de armas, melhorias e inimigos.
- `scenes/`: cenas nativas do jogo e dos sistemas.
- `tests/`: verificações integradas e captura de telas.

## Progresso e regras

O arquivo local fica em `%APPDATA%\Godot\app_userdata\Brasafria\profile.json`. Ouro, selos, construções e preferências permanecem. Armas, níveis, passivas, experiência e vida da tentativa são temporários. Morte, vitória, reinício, abandono e fechamento normal da janela liquidam a tentativa uma vez. Só ouro já coletado vai ao saldo. Moedas no chão não são creditadas. Encerrar o processo à força não permite salvar.

O perfil passou para versão 3. Perfis das versões 1 e 2 são migrados preservando ouro, selos, construções e opções. A parte da árvore começa vazia quando ausente. Um identificador persistido impede repetir o crédito da mesma tentativa. As compras da árvore têm limite de nível, proteção contra botão antigo e reversão de saldo se a gravação falhar.

Selos recebidos: `floor(segundos / 30) + floor(abates / 30) + selos coletados + 10 se vencer`. Arsenal e Biblioteca custam oito selos cada. Os apoios ampliam a preparação, sem bônus numéricos permanentes obrigatórios. Arquivos ausentes ou inválidos têm tratamento; a gravação preserva uma cópia anterior `.bak`.

## Validação e próximos passos

Veja `docs/ARVORE_E_CHEFES.md` para regras, balanceamento e validação da versão 0.3. `docs/HORDAS_E_OURO.md` e `docs/VALIDACAO.md` preservam os registros anteriores. O protótipo ainda exige avaliação humana da dificuldade e do prazer de jogar. O layout da árvore é provisório, preparado para receber as referências visuais futuras.

Defeitos atuais: cenário repetitivo; animações ainda sem conjuntos direcionais completos; efeitos sonoros simples; dificuldade sem avaliação humana suficiente. Os chefes possuem poses de preparação e morte. Equipamentos persistentes, outros personagens e regiões continuam fora desta versão.

## Exportar novamente

Execute `python tools/export_windows.py --smoke`. O resultado padrão é `build/Brasafria-0.4.1.exe`; a distribuição online atual foi exportada com `--output build/Online-Atualizado/Brasafria-Online-0.4.1.exe` e configuração embutida. O script utiliza a Godot 4.7.2 instalada em Downloads, aceita `--godot CAMINHO` e obtém o template Windows do repositório oficial se o cache estiver ausente. `python tools/verify_export.py` verifica a árvore e os chefes contra o pacote embutido usando o runtime da mesma versão. A exportação inclui manifesto de hash e licenças.

## Privacidade, termos e crédito

O solo funciona offline, sem conta, anúncios ou telemetria. O cooperativo envia nome escolhido, habilidades e mensagens da partida ao relay. O saldo continua salvo localmente. A política de privacidade e os termos estão nos menus e nos arquivos `docs/PRIVACIDADE.md` e `docs/TERMOS.md`. O link de crédito abre o Instagram no navegador.

Ícone próprio definido. Requisitos de navegação e indexação de sites, como sitemap, robots, llms, scroll e página 404, aplicam-se a uma eventual versão web; esta entrega é um aplicativo Windows nativo.

[Feito por Socialy](https://www.instagram.com/socialy_webdesign/)

Correção de rede 0.4.1: tolerância a mensagens acumuladas, preservação de envios pendentes, diagnóstico de quedas e túnel temporário por TCP. Consulte `docs/MULTIPLAYER.md`. O computador que executa o servidor não pode entrar em suspensão.
