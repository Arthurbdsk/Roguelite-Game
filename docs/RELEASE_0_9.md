# Hordas 0.9.0

Execute `Hordas-0.9.0.exe` no Windows. Os recursos estão embutidos. Todos os participantes do cooperativo precisam usar esta versão.

- A árvore foi substituída pela grade com 16 aprimoramentos e os ícones fornecidos.
- Compra com ouro, confirmação de reembolso exato, backup e migração de saves anteriores.
- Bônus individuais, frações de ouro salvas entre partidas, quarta opção pela Sorte e painel da build atualizado.
- Desafio de zero até o nível comprado, escolhido pelo criador e mostrado no lobby.
- Reviver uma vez por partida: escolha no solo; tecla R ou menu individual quando caído online. Retorno com 40% da vida e 2 s de proteção. Reanimação por aliado não consome o benefício.

Preços regulares: 10, 25, 50, 90 e 150 ouro. Sorte: 25, 60 e 120. Quantidade: 250. Reviver: 300.

Regras e validação detalhadas em `docs/APRIMORAMENTOS_0_9.md`. O teste renderizado com quatro contextos locais e 240 inimigos atingiu cerca de 32,6 FPS na máquina de desenvolvimento. Ainda é necessário avaliar a economia em partidas humanas e redes distintas. O online depende do relay temporário ativo.

O formato de save mudou para 4 e mantém backup anterior à migração. Não use executáveis antigos sobre o perfil já migrado. A nova explosão da bomba, da remodelação anterior, continua pendente.
