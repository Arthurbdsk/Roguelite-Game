# Brasafria

Protótipo jogável 0.1.0 em Godot 4.7.2 e GDScript. Uma sentinela enfrenta dez minutos de cerco no Pátio dos Esquecidos. Derrote o Rei sem Brasa antes do fim do tempo.

## Jogar

Abra `build/Brasafria.exe`. O executável é independente e contém os recursos. Não exige instalar a Godot.

WASD ou setas movem o personagem. Os ataques são automáticos e escolhem o inimigo mais próximo. Esc pausa; 1, 2 e 3 selecionam melhorias. F11 alterna tela cheia. Analógico esquerdo, direcional e navegação de menus estão mapeados para controle, ainda sem teste com hardware físico.

São três armas com cinco níveis, cinco passivas com limite de três vagas, três tipos de inimigos, uma elite e um chefe. A fortaleza possui dois desbloqueios permanentes e apoios com contrapartida. Subir de nível pausa a ação e oferece três escolhas distintas.

O chefe surge aos 9 minutos. É necessário derrotá-lo e resistir até 10:00. Aos 2 minutos, um altar a sudeste do centro concede vida, experiência e selos para quem permanece no círculo durante seis segundos.

## Editar

Importe `project.godot` na Godot e pressione F6 na cena principal ou F5 para executar o projeto. Cenas, Resources `.tres`, scripts e PNGs acompanham o projeto. `tools/generate_assets.py` recria a arte provisória. A fonte possui licença OFL; as licenças da Godot estão incluídas.

- `scripts/main.gd`: estados, experiência, coleta, evento e encerramento.
- `scripts/entities/`: jogador, inimigos e dados de inimigos.
- `scripts/combat/`: armas e escolhas.
- `scripts/world/`: arena e diretor de hordas.
- `scripts/core/`: salvamento e áudio.
- `scripts/ui/`: interface nativa e menus.
- `data/`: valores editáveis de armas, melhorias e inimigos.
- `scenes/`: cenas nativas do jogo e dos sistemas.
- `tests/`: verificações integradas e captura de telas.

## Progresso e regras

O arquivo local fica em `%APPDATA%\Godot\app_userdata\Brasafria\profile.json`. Selos, construções e preferências permanecem. Armas, níveis, passivas, experiência e vida da tentativa são temporários. Reiniciar descarta a tentativa atual; retornar à fortaleza liquida a tentativa como derrota. Fechar a janela durante o combate não concede recompensas.

Selos recebidos: `floor(segundos / 30) + floor(abates / 30) + selos coletados + 10 se vencer`. Arsenal e Biblioteca custam oito selos cada. Os apoios ampliam a preparação, sem bônus numéricos permanentes obrigatórios. Arquivos ausentes ou inválidos têm tratamento; a gravação preserva uma cópia anterior `.bak`.

## Validação e próximos passos

Veja `docs/VALIDACAO.md` para o que foi executado e suas limitações. `docs/DESIGN.md` apresenta as 11 seções do pedido; `docs/ROADMAP.md` contém etapas e critérios. O protótipo ainda exige avaliação humana da dificuldade e do prazer de jogar.

Defeitos atuais: cenário repetitivo; animações curtas sem conjuntos direcionais ou morte; efeitos sonoros simples; falta de ajustes de dificuldade após sessões reais. Equipamentos persistentes, outros personagens, regiões e famílias de armas estão fora desta primeira versão.

## Exportar novamente

Execute `python tools/export_windows.py --smoke`. O script utiliza a Godot 4.7.2 instalada em Downloads, aceita `--godot CAMINHO` e obtém o template Windows do repositório oficial se o cache estiver ausente. O resultado é `build/Brasafria.exe`, com manifesto de hash e licenças.

## Privacidade, termos e crédito

O jogo funciona offline, sem conta, anúncios ou telemetria. A política de privacidade e os termos estão nos menus e nos arquivos `docs/PRIVACIDADE.md` e `docs/TERMOS.md`. O link de crédito abre o Instagram no navegador.

Ícone próprio definido. Requisitos de navegação e indexação de sites, como sitemap, robots, llms, scroll e página 404, aplicam-se a uma eventual versão web; esta entrega é um aplicativo Windows nativo.

[Feito por Socialy](https://www.instagram.com/socialy_webdesign/)
