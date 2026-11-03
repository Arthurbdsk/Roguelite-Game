# Brasafria

Protótipo jogável 0.2.0 em Godot 4.7.2 e GDScript. Uma sentinela enfrenta dez hordas no Pátio dos Esquecidos. Elimine cada composição para avançar e derrote o Rei sem Brasa na última horda.

## Jogar

Abra `build/Brasafria-0.2.0.exe` ou `Jogar.cmd`. O executável é independente e contém os recursos. Não exige instalar a Godot. A versão anterior está preservada em `build/backups/`.

WASD ou setas movem o personagem. Os ataques são automáticos e escolhem o inimigo mais próximo. Esc pausa; 1, 2 e 3 selecionam melhorias. F11 alterna tela cheia. Analógico esquerdo, direcional e navegação de menus estão mapeados para controle, ainda sem teste com hardware físico.

São três armas com cinco níveis, cinco passivas com limite de três vagas, cinco tipos de inimigos, uma elite e um chefe. Os novos esqueletos usam espada com preparação e intervalo ou arco com disparo antecipado e flecha desviável. A fortaleza mantém seus dois desbloqueios permanentes e apoios com contrapartida. Subir de nível pausa a ação e oferece três escolhas distintas.

Não há mais prazo de dez minutos. A preparação inicial dura 2,5 segundos; entre hordas, cinco segundos após eliminar os restantes. Espadachins entram na horda 3, arqueiros na 5, a elite na 7 e o chefe na 10. A dificuldade muda por quantidade, composição e comportamento, sem aumentar atributos por tempo ou nível do jogador. Aos dois minutos, o altar original a sudeste continua disponível.

Todo inimigo deixa ouro. Moedas permanecem por 60 segundos de partida, são atraídas por proximidade e só contam quando chegam ao corpo. A pausa interrompe seu tempo de vida. Ouro dourado e experiência azulada possuem leitura distinta.

## Editar

Importe `project.godot` na Godot e pressione F6 na cena principal ou F5 para executar o projeto. Cenas, Resources `.tres`, scripts e PNGs acompanham o projeto. `tools/generate_assets.py` recria a arte original; `tools/generate_skeletons.py` gera os novos esqueletos e o ouro. A fonte possui licença OFL; as licenças da Godot estão incluídas.

- `scripts/main.gd`: estados, experiência, coleta, evento e encerramento.
- `scripts/entities/`: jogador, inimigos e dados de inimigos.
- `scripts/combat/`: armas e escolhas.
- `scripts/combat/enemy_projectiles.gd`: flechas com trajetória fixa, colisão e descarte.
- `scripts/world/gold_loot.gd`: moedas, atração, expiração e coleta.
- `scripts/world/`: arena e diretor de hordas.
- `scripts/core/`: salvamento e áudio.
- `scripts/ui/`: interface nativa e menus.
- `data/`: valores editáveis de armas, melhorias e inimigos.
- `scenes/`: cenas nativas do jogo e dos sistemas.
- `tests/`: verificações integradas e captura de telas.

## Progresso e regras

O arquivo local fica em `%APPDATA%\Godot\app_userdata\Brasafria\profile.json`. Ouro, selos, construções e preferências permanecem. Armas, níveis, passivas, experiência e vida da tentativa são temporários. Morte, vitória, reinício, abandono e fechamento normal da janela liquidam a tentativa uma vez. Só ouro já coletado vai ao saldo. Moedas no chão não são creditadas. Encerrar o processo à força não permite salvar.

O perfil passou para versão 2. Perfis da versão 1 são migrados com ouro inicial zero, mantendo selos, construções e opções. Um identificador persistido impede repetir o crédito da mesma tentativa. Ouro ainda não possui loja, construção ou melhoria comprável.

Selos recebidos: `floor(segundos / 30) + floor(abates / 30) + selos coletados + 10 se vencer`. Arsenal e Biblioteca custam oito selos cada. Os apoios ampliam a preparação, sem bônus numéricos permanentes obrigatórios. Arquivos ausentes ou inválidos têm tratamento; a gravação preserva uma cópia anterior `.bak`.

## Validação e próximos passos

Veja `docs/HORDAS_E_OURO.md` para configuração e resultados da versão 0.2. `docs/DESIGN.md` apresenta as 11 seções originais, atualizadas. `docs/VALIDACAO.md` preserva a validação histórica da versão 0.1. O protótipo ainda exige avaliação humana da dificuldade e do prazer de jogar.

Defeitos atuais: cenário repetitivo; animações curtas sem conjuntos direcionais ou morte; efeitos sonoros simples; falta de ajustes de dificuldade após sessões reais. Equipamentos persistentes, outros personagens, regiões e famílias de armas estão fora desta primeira versão.

## Exportar novamente

Execute `python tools/export_windows.py --output build/Brasafria-0.2.0.exe --smoke`. O script utiliza a Godot 4.7.2 instalada em Downloads, aceita `--godot CAMINHO` e obtém o template Windows do repositório oficial se o cache estiver ausente. A exportação inclui recursos embutidos, manifesto de hash e licenças.

## Privacidade, termos e crédito

O jogo funciona offline, sem conta, anúncios ou telemetria. A política de privacidade e os termos estão nos menus e nos arquivos `docs/PRIVACIDADE.md` e `docs/TERMOS.md`. O link de crédito abre o Instagram no navegador.

Ícone próprio definido. Requisitos de navegação e indexação de sites, como sitemap, robots, llms, scroll e página 404, aplicam-se a uma eventual versão web; esta entrega é um aplicativo Windows nativo.

[Feito por Socialy](https://www.instagram.com/socialy_webdesign/)
