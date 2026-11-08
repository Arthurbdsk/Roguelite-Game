# Estado atual

PC 0.25.2 e Android 0.25.2-android.4, protocolo 2, conteúdo 0.25.2+6ba5d9724f77d754. Removido o spawn exclusivo do Android: ambas as plataformas usam os mesmos valores de gameplay. Apenas Orc comum e herói são 20% menores visualmente no Android; demais criaturas iguais ao PC. Coop continua em 1,7x dano e 2x quantidade com quatro jogadores, vida/velocidade do solo. [Auditoria e entrega](PARIDADE_0_25_2.md). Android volta a ficar congelado após esta atualização autorizada. Testes físicos e redes distintas ficam com o usuário.

O texto abaixo preserva o histórico dos envios anteriores, até a versão 0.9.0.

## Histórico do envio ao GitHub

O projeto enviado contém a implementação atual, com cenas, Resources e sprites editáveis. O arquivo de entrada é `project.godot`, para Godot 4.7.2 padrão.

A remodelação em andamento já inclui navegação com caminhos compartilhados e separação local, retirada da faixa de armas do HUD, herói com 32 quadros, Necromante, Médico da Peste e Besta com 16 quadros, duas formas do chefe com 32 quadros cada, bomba azul com pavio animado, bumerangue de madeira e superfície animada da Água Benta.

Executado antes deste envio: importação no Godot, capturas na arena de cada asset integrado, transformação e recompensa do chefe, animações do herói, testes de chefes com escala cooperativa e perseguição com 240 inimigos em cada um dos três mapas. Os testes de multidão registraram movimento de todos os agentes e zero violações de colisão no cenário testado.

O executável 0.8.0 inclui essa remodelação. Foi exportado com os recursos embutidos, iniciado com perfil isolado e verificado por quatro processos Godot usando o PCK do executável: movimentação, escolhas individuais, recursos, reanimação, escala e transformação do chefe, derrota e crédito de ouro. O teste do relay também passou.

Pendente: nova sequência da explosão da bomba e medição final de desempenho da remodelação com efeitos simultâneos. A explosão anterior foi preservada nesta entrega.

O saldo e a árvore permanente ficam no perfil local do jogador. O perfil pessoal, configurações de túnel, caches, dependências instaladas e executáveis não fazem parte do repositório.

A versão atual é 0.9.0, com a grade de 16 aprimoramentos permanentes, migração, compras, reembolso, Desafio e Reviver. Consulte `APRIMORAMENTOS_0_9.md` para preços, regras e validação.
