# PC 0.25.0 e atualização Android autorizada

Entrega local concluída, com limitações de desempenho e validação física abaixo. Este pedido autoriza uma atualização Android, que volta a ficar congelada depois dela. Nenhuma publicação em loja foi solicitada ou realizada.

## Arte

O pacote local Tiny RPG contém Soldado e Orc. Foram consultados a página de origem de Zerie, resultados de busca no Pinterest e as páginas de Carrascos de Elthen e TokeGameArt. Nenhuma prévia ou pacote pago foi copiado. Esses materiais não forneciam gratuitamente os dois personagens com todos os estados pedidos.

- Origem da coleção: https://zerie.itch.io/tiny-rpg-character-asset-pack
- Carrasco consultado, não incorporado: https://elthen.itch.io/2d-pixel-art-medieval-executioner
- Alternativa consultada, não incorporada: https://tokegameart.artstation.com/store/a7Xor/tiny-executioners

Shadow e Carrasco são artes originais criadas com a ferramenta imagegen integrada, sem usar imagens do pacote licenciado como entrada. Fontes em `assets/v25/sources`; atlases consumidos em `assets/v25/shadow.png` e `assets/v25/executioner.png`. Não são personagens oficiais do pacote pago Tiny RPG.

Prompts de produção: Shadow, criatura de sombra com capuz irregular e olhos cianos, 4 colunas por 8 linhas, espera, movimento, preparação, ataque, desaparecimento, reaparição, dano e morte definitiva distinta. Carrasco, executor robusto encapuzado com machado pesado, 4 colunas por 9 linhas, espera, caminhada, preparação/execução, preparação/investida, dano, mudança de fase e morte. Em ambos: visão lateral em três quartos para a direita, pivô fixo, quadros distintos, alpha real, paleta limitada, contorno escuro e pixels nítidos, sem cenário, sombras no chão, textos ou marcas.

Empacotamento técnico com `tools/pack_original22.py`: Shadow com 21 px de altura visível inicial e célula 48, 32 quadros; Carrasco com 28 px e célula 64, 36 quadros. A escala visual geral 1,1 permanece. Colisores independem do tamanho da arma. A apresentação acompanha os eventos reais de combate, sem disparar dano por quadro de animação.

## Bestiário

23 espécies reais, incluindo variantes e chefes. `EnemyCatalog` consulta `enemy_spawn_stats()`, também usado na criação em combate. Base solo, Desafio zero, estágio inicial, sem bônus temporários. A interface arredonda os valores e separa redução percentual, ausência de defesa fixa e comportamento dos controles.

Encontro: criatura visível no enquadramento lógico de cada jogador, sem exigir dano. Cada instância conta uma aparição por observador. O golpe final usa o dono da arma, incluindo poças, e o host confirma totais cumulativos individuais. A transformação de um chefe não é morte. Limpeza, expiração e DEV não contam como abates.

Os campos opcionais do perfil versão 4 começam em zero em saves antigos. Estatísticas ficam em memória, com checkpoint a cada 30 segundos e nos menus/encerramento. Cada dispositivo mantém seu save; não há sincronização de progresso entre PC e Android.

## Ajuste adicional do multiplayer

Vida e velocidade usam a base do solo, mantendo as regras próprias de cada fase e os modificadores de Desafio/tempo. Dano preservado. A geração total do cooperativo recebe fator 0,8 uma única vez. Multiplicadores de quantidade com 2/3/4 participantes: 1,44 / 2,08 / 2,72. Com base de 90/min no estágio inicial, isso corresponde a 129,6 / 187,2 / 244,8 por minuto. Não altera o solo nem reduz invocações ou divisões específicas de ataques/eventos.

## Compatibilidade

Protocolo 2. O handshake compara uma identificação de conteúdo gerada de dados, mapas e trechos compartilhados da simulação. Versão de aplicativo e plataforma são separadas dessa identificação. O build falha se o manifesto estiver desatualizado. PC e Android só devem compartilhar sala quando a identificação de gameplay coincidir.

## Validação e pendências

Base de gameplay PC: `4276c18125e5a61f57022437569729a0afe577e0`. Android: `48775b4`, branch `codex/android-mobile`, worktree separado. Commits incorporados registrados em `data/mobile_build.json` no Android.

Builds compatíveis: PC 0.25.0 e Android 0.25.0-android.2, protocolo 2, conteúdo `0.25.0+24d20eff97f22428`.

- PC: `build/Hordas-0.25.0/Hordas-0.25.0.exe`; SHA-256 `e99bc71150f93164d67ce8ff9cc055dce148775ca97b735a927fb55f3c6b7fd5`.
- Android: `../Hordas Android/build/Hordas-Android-0.25.0-2.apk`; SHA-256 `882e9524fd991a910884c9d90cdc62aa96d87d8e516563c468d7d455f4d08ab0`.

40 suítes PC aprovadas, incluindo frequência, projéteis, Machado, escala, vida/fogo, designs, dados e interface do bestiário, perfis antigos e combate cooperativo. Evidências em `docs/pc25/validation.json`. Teste final do PCK público passou em diretório isolado, sem DEV, com 23 espécies e novos personagens. A tentativa inicial desse ensaio dentro da pasta do editor encontrou recursos DEV locais; a execução isolada confirmou o pacote público correto.

Android: oito suítes de prévia, APK nativo, bestiário aberto por toque e instalação sobre versão anterior. Certificado original preservado, pacote `com.socialy.hordas.android`, código 2. Instalação de código 1 para 2 preservou o perfil byte por byte, e a reinstalação do APK final confirmou a preservação. Não foi usado um save pessoal de aparelho físico.

Dois ensaios mistos finais passaram: três processos PC usando o PCK público mais Android nativo emulado com APK QA da mesma simulação, alternando host PC e host Android. Relay público `wss://hordas-relay.onrender.com`. Três mapas, seis armas por jogador, mortes com dono, bestiário, escolhas, reanimação por gesto mantido ADB, transformação de Demônio e recompensa persistida uma vez. Android cliente em segundo plano não interrompeu os demais. Conteúdo incompatível foi recusado pelo relay público; o cliente traduz a recusa para mensagem de compatibilidade PC/Android.

Ambiente: Windows, Ryzen 5 5600/RX 6600, AVD Hordas_API35 Android 15/API35 x86_64, 2 CPU/2 GB, Compatibility/OpenGL ES, tela horizontal 2340×1080. Uma máquina e uma conexão de internet. O usuário fará os testes em aparelho físico e em redes distintas. Travessia do relay público nessa configuração não comprova esses cenários.

Carga curta nativa Android: 200 inimigos, quatro donos simulados, seis armas e quatro passivas nível 8, nos três mapas. Foram medidos 5,42 / 5,85 / 6,00 FPS e p95 de 224 / 206 / 197 ms. A execução e as contagens passaram, mas o desempenho foi insuficiente. Esse ensaio usa 2 s de aquecimento, amostras de 5/5/10 s e desativa descobertas; não comprova estabilidade longa nem desempenho de celular. Não considerar desempenho mobile aprovado. Resultados brutos em `docs/pc25/crossplay/native-load-final.json`.

Limites: não há migração de host ou reconexão automática. Suspender o Android anfitrião encerra a sala. Os novos designs originais estão integrados para avaliação dentro do jogo; não são assets oficiais Tiny RPG. Android volta a ficar congelado após esta entrega. Não houve publicação em lojas ou novas releases públicas.
