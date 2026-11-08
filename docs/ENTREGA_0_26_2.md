# Entrega 0.26.2

PC 0.26.2 e Android 0.26.2-android.10 usam protocolo 2 e identidade `0.26.2+6c3b0b65ed77fe5a`. Números de versão parecidos não autorizam uma sala: o handshake exige protocolo e conteúdo compatíveis. A edição Android foi autorizada nesta entrega, em worktree separado, e volta a ficar congelada.

## Atualizações no jogo

Acesso pelo menu principal, base e menu online. Mostra versão instalada/disponível, compatibilidade, notas, bytes do download e progresso. Verifica discretamente no menu, sem baixar automaticamente. Permite cancelar e tentar novamente. Uma falha de rede não impede solo. Um requisito novo de online leva à aba; não encerra uma partida ativa.

O canal público e os arquivos usam GitHub público, sem token ou login do jogador. O manifesto é autenticado com RSA 3072/SHA-256 antes de usar seus registros. Cada pacote confere tamanho, SHA-256 e formato; o helper Windows verifica novamente assinatura, validade, integridade e arquitetura. Um hash isolado não é a raiz de confiança. Chaves privadas ficam fora dos repositórios.

O Windows usa um helper separado, espera o processo fechar, mantém `Hordas.previous.exe`, instala na conta do usuário e confirma a inicialização da versão esperada. Se ela não confirmar, restaura e abre a cópia anterior. Instalação inicial pelo botão **Instalar nesta conta**, seguida de **Reiniciar e atualizar**. Local: `%LOCALAPPDATA%/Hordas/Game/Hordas.exe`. Atalho no menu Iniciar, sem sobrescrever um atalho existente. Não há extração ZIP nem exclusão de arquivos arbitrários. O perfil continua separado da instalação.

O Android baixa o APK e compara seu identificador, versão e certificado com o aplicativo instalado. Abre o instalador oficial usando FileProvider. Se necessário, abre a permissão para instalar desta origem e pede para repetir o botão. O jogador confirma a instalação no Android. Package `com.socialy.hordas.android`, versionCode 10, certificado SHA-256 `a2d917b419ab3da9572b72f1e0c825b56b800ef6ef011ed4108591b396449c05`, preservado. Não houve publicação em loja.

Falta de espaço, cancelamento, arquivo incompleto/corrompido, assinatura inválida, servidor indisponível e instalação negada têm tratamento. Ao reabrir, o jogo descarta o download parcial. A validação pesada aguarda o menu quando o download termina durante uma partida. A instalação exige partida encerrada e salvamento bem-sucedido.

## Vida inicial

A causa da resistência excessiva era o acréscimo fixo de 30 sobre inimigos fracos, combinado com os multiplicadores de vida e o crescimento temporal. A correção calibra a base solo dessas espécies em relação ao dano real da flecha, sem aumentar o dano das armas. Arco nível 1, sem bônus permanente e sem crítico: dano bruto **19,656**. Os testes passam pelo recebimento real de dano e pela defesa da criatura.

| Espécie | Vida solo inicial | Acertos normais | Acertos aos 4:59 |
| --- | ---: | ---: | ---: |
| Ghoul | 36 | 2 | 2 |
| Cão | 32 | 2 | 2 |
| Esqueleto com espada | 36 | 2 | 2 |
| Esqueleto arqueiro | 32 | 2 | 2 |
| Slime pequeno | 24 | 2 | 2 |
| Guarda | 44 | 3 | 3 |
| Orc com armadura | 50 | 3 | 3 |
| Esqueleto com armadura | 50 | 3 | 3 |
| Slime grande | 48 | 3 | 3 |

Para essas nove espécies, o bônus temporal é 1,5 por estágio nos dois primeiros estágios, depois 8 por estágio adicional. No marco de quatro minutos, a diferença é +3 de vida. Não se reaplica o antigo +30 nem um bônus de evento sobre essa base calibrada. Especiais, elites, chefes e variantes de evento mantêm suas próprias regras. O ajuste não promete dois acertos no cooperativo com modificadores ativos.

Coop preservado: vida e velocidade 1x. Dano para 1/2/3/4 jogadores: 1/1,2333/1,4667/1,7x; quantidade: 1/1,3333/1,6667/2x. A base solo é resolvida antes dos modificadores da partida. PC e Android têm a mesma geração base de 90 inimigos/minuto, os mesmos atributos e regras.

## Proporções Android

Removida a compensação visual por criatura e a redução mobile de geração. Herói e todas as espécies usam multiplicador de plataforma 1. A escala comum do PC e as diferenças naturais entre espécies permanecem. A câmera lógica é 640x360; o stretch inteiro, o cálculo da área segura e o enquadramento tratam as telas, sem deformar sprites nem mudar corpo, colisão, alcance ou velocidade para compensar o celular.

## Validação e limites

Evidências resumidas em `docs/evidence026/`. Os testes usam perfis sintéticos isolados; não publicam saves pessoais.

- PC: 54 casos de acertos reais nas nove espécies nos segundos 0, 60, 120, 180, 240 e 299; todos passaram. São cenários controlados desses momentos, não uma declaração de playthrough humano contínuo de cinco minutos.
- Android final: os mesmos 54 casos passaram nativamente no emulador, identidade final conferida, multiplicadores visuais do herói e 23 espécies iguais ao PC.
- PC: suites de proporções, manifesto/assinatura, integridade/cancelamento, vida/fogo, coop e rede passaram. `health_fire24` executou 221 verificações. O PCK final foi aberto fora do diretório-fonte e passou por bestiário, identidade, arte, ausência de DEV e regras cooperativas.
- Windows: versões QA isoladas 0.26.1 e 0.26.2 detectaram e baixaram pelo próprio jogo usando HTTPS público temporário, autenticaram, instalaram, reabriram e preservaram exatamente o save sintético de 321 de ouro. Na primeira execução, o wrapper de console do motor precisou ser encerrado após o helper concluir; isso foi corrigido no controlador de teste, e a repetição completa terminou com sucesso e saída zero usando transporte HTTP/2 no túnel. Uma repetição recebeu 90.177.536 dos 114.865.944 bytes devido à queda do túnel de teste e rejeitou o arquivo, preservando a instalação.
- Windows: falha de confirmação da versão nova provocada com um executável válido; o helper restaurou o hash anterior, reabriu a versão antiga e preservou o save. Saída 1 é esperada nesse cenário. Corrupção de byte, truncamento e cancelamento também foram rejeitados.
- Android: fluxo real QA versionCode 5 para 6, download pelo jogo via HTTPS local, autorização de origem, tela oficial de atualização e confirmação de aplicativo instalado. Save sintético idêntico antes/depois. A validação posterior encontrou um erro na checagem nativa adicionada após esse teste: acesso direto aos campos Java retornava nulo no Godot 4.7. Foi substituído por reflexão, evitando também a colisão entre Field.get e Object.get. A revisão 10 confirma identificador, versão, código e conjunto real de certificados; o teste nativo aceita o certificado do jogo e rejeita o de outro aplicativo instalado. As revisões experimentais 7/8 exigem instalar manualmente o APK final uma vez, sem desinstalar nem perder o perfil. A revisão 9 corrigida serve de origem para o teste público de atualização para 10.
- Crossplay final: três processos PC e um APK QA nativo, relay público WSS, três mapas, encontros/abates individuais, chefes/fases, escolhas, reanimação por toque e recompensas. Os dois hosts passaram na revisão Android 7, inclusive troca de aplicativo no cliente Android sem pausar os demais. A revisão final 10 mantém essa identidade de gameplay e também passa pela repetição dos dois hosts.

Ambiente Android: emulador Android 15/API 35 x86_64, Hordas_API35, Windows com Ryzen 5 5600 e Radeon RX 6600. Não havia telefone físico conectado. Proporções nativas conferidas em 2340x1080, 1920x1080 e 1280x800, com escala uniforme. O download completo do PC final pelo endereço permanente do GitHub foi autenticado pelo jogo: 114.869.304 bytes.

Os clientes do teste de relay saem da mesma conexão de internet; não demonstram redes independentes, 4G/5G, latência celular, aquecimento ou desempenho de um aparelho real. O usuário fará esses testes. Não declarar essas condições como aprovadas.

O canal usa validade de 90 dias e precisa de renovação assinada. Sem hospedagem disponível ou com manifesto vencido, solo continua disponível. O atualizador não elimina a necessidade de gerar, assinar, testar e publicar cada release. [Processo de publicação](PUBLICAR_ATUALIZACOES.md).

## Arte e histórico preservados

Esta entrega mantém Shadow, Carrasco e bestiário da série 0.25, sem substituir seus assets. Referências e fontes continuam nos documentos de arte anteriores. Mantém Tiny RPG de Zerie para Soldado/Orc conforme a licença integrada, e os demais desenhos originais documentados no projeto. Não houve nova pesquisa de assets nesta etapa de atualizações e paridade.

## Arquivos finais

| Plataforma | Arquivo | Bytes | SHA-256 |
| --- | --- | ---: | --- |
| PC | Hordas-0.26.2.exe | 114869304 | `820ab40246435ec1a30e85237a7cbd4c78ade1423ed78f0085b659d1b8ce8ac3` |
| Android | Hordas-Android-0.26.2-10.apk | 83838728 | `5502b9c9fa0fe7095cc02877f4b07f171e871b0da349878ff2014ccd85538b78` |

Origem runtime PC `01f01f009d398cd4c06208ba75533a14e52f2ca7`. Origem Android `7362678f3859ef34c9de93130a6416dce3b2f389`, base PC 0.26.2 no mesmo commit. Os commits incorporados ficam em `data/mobile_build.json` na branch Android. Publicação de documentação posterior não altera os bytes ou essas origens.

Canal público promovido pelo [Actions PC/Android](https://github.com/Arthurbdsk/Roguelite-Game/actions/runs/42501505355) e pela [revisão Android 10](https://github.com/Arthurbdsk/Roguelite-Game/actions/runs/42504056814), ambos com sucesso. Arquivos permanentes: [PC](https://github.com/Arthurbdsk/Roguelite-Game/releases/download/update-pc-0.26.2/Hordas-0.26.2.exe), [Android](https://github.com/Arthurbdsk/Roguelite-Game/releases/download/update-android-0.26.2-android.10/Hordas-Android-0.26.2-10.apk).

Referência técnica do erro e da solução: [limitação de campos de instância do JavaObject no Godot](https://github.com/godotengine/godot-proposals/issues/15453), [JavaClassWrapper](https://docs.godotengine.org/en/stable/classes/class_javaclasswrapper.html) e [PackageInfo](https://developer.android.com/reference/android/content/pm/PackageInfo). A leitura por reflexão foi validada no APK, incluindo rejeição de um certificado diferente. Downloads Android têm até 15 minutos, mantendo verificações de manifesto em 30 segundos, para não usar o prazo curto de consulta no arquivo completo.

Validação pública Android final: versão 9 corrigida detectou e baixou os 83.838.728 bytes da versão 10 pelo próprio jogo, no endereço permanente do GitHub. A checagem nativa conferiu pacote, versão e certificado; o sistema solicitou a autorização de origem e confirmou a atualização. O PackageInstaller terminou com App installed e o package manager confirmou versionCode 10. O save permaneceu byte a byte idêntico e manteve as duas partidas registradas. Teste em emulador, sem representar aparelho físico ou redes independentes. Evidência: docs/evidence026/android-public-install.json. As revisões experimentais 7/8 foram rotuladas como substituídas e prerelease, com orientação para instalar o APK final sem desinstalar.

Reabertura final confirmada no menu Android 0.26.2-android.10. O hash do base.apk efetivamente instalado corresponde exatamente ao APK público final. Servidores e túneis temporários de transferência foram encerrados; o canal e os downloads permanecem nos endereços permanentes do GitHub.
