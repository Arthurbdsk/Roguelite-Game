# Roteiro de produção

Este roteiro descreve critérios, não declara que os testes passaram. O código atual contém os sistemas das etapas 1 a 4; a validação é conduzida na integração. Não ampliar o conteúdo antes de corrigir falhas de combate ou de estado.

## Etapa 1. Fatia de combate

Entrega jogável: arena pequena, Sentinela, lâmina, Esquecido, dano, invulnerabilidade, experiência e reinício. O modo `--slice` limita o diretor a Esquecidos, com no máximo 12 ativos, para inspeção básica.

Critérios: movimento consistente nos dois eixos; diagonal sem ganho de velocidade; obstáculo visível correspondente ao colisor; ataque alcança somente seu arco; dano respeita a invulnerabilidade; experiência gera escolha; derrota permite reiniciar sem inimigos ou recursos da tentativa anterior.

Saída esperada: registrar defeitos de resposta e leitura antes de aumentar a densidade. Direção artística permanece provisória.

## Etapa 2. Armas e escolhas

Entrega jogável: besta, brasas, cinco passivas, três ofertas e afinidades de evolução.

Critérios: cada arma muda alcance e posicionamento; virote atravessa alvos na ordem do trajeto; órbita aplica seu intervalo por inimigo; ofertas não repetem IDs na mesma seleção; terceira passiva bloqueia novas famílias; evolução exige a afinidade; experiência excedente permanece; consumíveis substituem ofertas esgotadas sem escolha inútil.

Saída esperada: comparar pelo menos uma tentativa de combate próximo com outra de controle à distância. Ajustar números se uma escolha tornar as demais dispensáveis. Não considerar equilíbrio provado apenas pela ausência de erros de script.

## Etapa 3. Expedição de dez minutos

Entrega jogável: três inimigos comuns, elite, altar e chefe final.

Critérios: surgimentos fora da câmera e em local seguro; feras após 90 s; altar após 120 s; pesados após 210 s; elite após 300 s; chefe após 540 s. Investidas e áreas fixam a direção ou posição antes do impacto. O altar exige seis segundos e só paga uma vez. Aos 600 s, chefe morto gera vitória; chefe vivo gera derrota. Morte do jogador também encerra a tentativa.

Saída esperada: executar o fluxo completo e testar os dois resultados. Simulação acelerada pode verificar regras, mas não substitui uma sessão para avaliar ritmo e legibilidade.

## Etapa 4. Fortaleza mínima e perfil

Entrega jogável: Arsenal, Biblioteca, escolha de um apoio, selos e salvamento local.

Critérios: oito selos compram uma construção uma única vez; moedas insuficientes bloqueiam a compra; apoio não desbloqueado é rejeitado; somente um apoio começa ativo; custos de cada apoio afetam o comportamento previsto; encerramento concede a fórmula uma única vez; abrir novamente restaura progresso e opções. Arquivo ausente ou inválido não derruba o jogo.

Saída esperada: validar com um perfil de teste separado. Não usar o progresso do jogador para testes destrutivos ou compras repetidas.

## Etapa 5. Validação da versão mínima

Entrega jogável: candidato local 0.1.0, pronto para avaliação do usuário.

Critérios: importar sem erros de sintaxe; testar pausa, troca de tela, foco de teclado, seleção e reinício; inspecionar HUD, avisos e personagem sob carga; medir a configuração testada; verificar limite de sons e ajuste de volume; conferir documentos legais e crédito. Exportação e compatibilidade exigem execução do artefato correspondente.

Registrar ao final: implementado, executado, resultado, problemas conhecidos e próxima entrega jogável. Controles de gamepad presentes no código devem ser distinguidos de teste com controle físico.

## Etapa 6. Acabamento e conteúdo futuro

Só iniciar depois da avaliação do combate. Prioridades possíveis: animação direcional, leitura do chefe, diversidade de rotas e ajuste das construções. Personagens extras, equipamento persistente, novos biomas, atiradores, raios encadeados, áreas persistentes e trilha musical entram em entregas posteriores com critérios próprios.

Decisões que dependem da direção do usuário: nome, paleta final, tema dos apoios, impacto das trocas e duração da pressão final. Nenhuma impede a avaliação do protótipo atual.
