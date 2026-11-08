# Paridade PC e Android 0.25.2

Correção autorizada em 8 de novembro de 2026. A versão 0.25.1 aplicava redução visual de 20% a todos os inimigos e reduzia o spawn contínuo do solo Android a 60% do PC. As duas regras foram substituídas pelo pedido atual.

Agora só o Orc comum e o Soldado são desenhados 20% menores no Android. Esqueletos, morcegos, variantes, especiais e chefes voltaram ao tamanho visual do PC. O ajuste acompanha pés, nomes, barras e restos; crescimento e transformações mantêm suas proporções. Colisão e alcance permanecem compartilhados.

Gameplay igual ao PC: sem multiplicador de spawn por plataforma, 90 inimigos/minuto no estágio inicial e mesmos modificadores de estágio/Desafio, armas, dano, vida e resistência. Coop preservado: 2/3/4 jogadores com dano 1,2333/1,4667/1,7 e quantidade 1,3333/1,6667/2. Progressos locais e escolhas de Desafio continuam individuais; não houve reset ou sincronização de saves.

Auditoria nativa contra o PCK público PC: 3.948 valores comparados, 256 casos de armas nos oito níveis com e sem passivas, 184 casos de inimigos com diferentes quantidades de jogadores e estágios, oito cenários de geração. Comparados dano configurado e aplicado, cooldown, quantidade, alcance, vida, resistência, velocidade e colisão. Seis números diferiram apenas na serialização decimal, diferença máxima 1,03e-12, sem diferença de gameplay observada. Resultado em docs/pc252/comparison.json.

As 23 espécies e o jogador foram inspecionados em execução no Android. Apenas hero/ghoul têm multiplicador visual 0,8; os demais 1. Captura nativa em build/update252/native.png. Testes do PC passaram para escala, morte, geração e cooperativo; oito suítes Android de prévia também passaram.

Pacote com.socialy.hordas.android e certificado original preservados. APK código 4 instalado sobre código 3, perfil byte por byte igual após instalação. Instalar por cima sem desinstalar.

APK público build/Hordas-Android-0.25.2-4.apk, SHA-256 1f3196b3d18947610f0b249ba768b2d52adfbb0f7761176b34a3d4ef81c984c4. Base PC 6b319f308b19ecbd17c9917ac44741bb3622f614. Atualização em codex/android-mobile, worktree separado, commits registrados em data/mobile_build.json. Compatível com PC 0.25.2, protocolo 2, conteúdo 0.25.2+6ba5d9724f77d754. Não misturar com builds anteriores.

Ambiente: emulador Android 15/API35 x86_64, Windows Ryzen 5600/RX6600. Não comprova desempenho em aparelho real nem redes distintas, a cargo do usuário. Não houve nova medição de desempenho sob carga. Android volta a ficar congelado após esta entrega. Nenhuma publicação em loja.

Executável PC: build/Hordas-0.25.2/Hordas-0.25.2.exe, SHA-256 947d055a9d0d6a4814bdd010115cf847eefc0b68ffd4183d6dc9ea0dc8a3aae4. Inicialização headless e teste do PCK público em diretório isolado aprovados; sem DEV ou executor de auditoria incorporados ao pacote público.

Os dois ensaios finais pelo relay público passaram: três processos PC usando o PCK público e Android nativo emulado usando APK QA de mesma simulação, alternando host PC e Android. Testados três mapas, reanimação por toque, armas, fases, bestiário e recompensas individuais. Uma máquina e uma conexão de internet; isso não comprova redes diferentes ou aparelho físico.

Implementação Android registrada no commit 76b7cfa, após a base PC 6b319f3. A manutenção Android permanece congelada após esta entrega, conforme AGENTS.md.
