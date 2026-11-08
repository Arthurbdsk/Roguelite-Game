# Ajuste de dificuldade 0.25.1

Pedido autorizado em 8 de novembro de 2026, incluindo Android. Dano total dos inimigos: 1 / 1,2333 / 1,4667 / 1,7 vezes para 1/2/3/4 jogadores. Quantidade: 1 / 1,3333 / 1,6667 / 2 vezes. Vida e velocidade continuam iguais ao solo. Modificadores normais de Desafio, estágio e fases continuam existentes.

Android solo: geração contínua multiplicada por 0,6, de 90 para 54 inimigos/minuto na base inicial. A progressão por estágio mantém o mesmo fator. Não altera quantidades próprias de invocações, divisões e chefes. A redução solo não se aplica a salas online, mesmo quando sobra um participante. PC solo mantém 90/minuto.

Inimigos desenhados no Android 20% menores, incluindo variantes e fases, sem alterar personagens do PC ou o herói. Um nó visual separado mantém a redução após crescimento do Devorador e sincronização multiplayer. Pés, barras e restos acompanham o tamanho. Colisão e alcance continuam iguais entre plataformas para preservar crossplay.

Validação PC: sete suítes aprovadas, incluindo medição de um minuto simulado de geração, todos os tipos de inimigos, Devorador, fases, regras de 2/3/4 jogadores, Desafio, morte e chefes. Android: oito suítes de prévia aprovadas e teste nativo confirmando 23 espécies com visual 0,8, fases/crescimento, 54 spawns por minuto simulado sem espera inicial e regras online iguais ao PC. Atualização de código 2 para 3 preservou certificado original, pacote e bytes do perfil. Evidências em docs/pc251.

Dois ensaios mistos passaram pelo relay público, com quatro participantes, alternando host PC e Android emulado: três mapas, seis armas por dono, reanimação por gesto ADB, fases, estatísticas e recompensas individuais. PCK público PC e APK QA nativo de mesma simulação. Uma máquina e uma conexão de internet, sem teste em aparelho físico ou redes distintas, que ficam com o usuário. Não foi reavaliado desempenho sob carga; a medição insuficiente do emulador na versão anterior não está resolvida ou aprovada por esses testes.

Entrega PC: build/Hordas-0.25.1/Hordas-0.25.1.exe, SHA-256 c709d5f49208407269800ba0ce100787160be5f753c56986c5cc76522951e318. Inicialização headless do executável público e teste do PCK isolado aprovados.

Entrega Android: ../Hordas Android/build/Hordas-Android-0.25.1-3.apk, SHA-256 9851f16b8ebcebd771e6417b8f55fb6584ab9ef0f9a12f8272a5fd1acec947fd. Base PC 3b73d3f, commit Android c9f5bcf, branch codex/android-mobile. Mesma assinatura anterior. Instalar por cima, sem desinstalar.

Compatibilidade: protocolo 2, conteúdo 0.25.1+f69263393c14aee1. Usar ambos os builds novos; não misturar com 0.25.0. Android volta a ficar congelado após esta entrega. Nenhuma publicação em lojas ou nova release pública.
