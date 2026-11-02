# Interface de Brasafria

`GameUI` é uma `CanvasLayer` com controles nativos editáveis. A interface trabalha em 640 × 360 e usa bordas retas. `setup(game)` cria o tema e o HUD. `render(tela, dados)` troca os menus. `update_hud(dados)` atualiza somente os indicadores da partida.

Telas: `title`, `hub`, `running`, `upgrading`, `paused`, `settings` e `result`. O menu de opções é interno à UI e mantém `return_screen`; não altera o estado da simulação. O controlador principal deve tratar Esc consultando `ui.screen` caso queira fechar as opções diretamente.

A UI chama os métodos públicos do controlador fornecidos no contrato do projeto. Compras de construções continuam sendo validadas pelo controlador. A seleção do apoio fica na UI até `start_run(apoio)`.

Todos os botões usam foco nativo para teclado e controle. Melhorias também recebem os atalhos 1, 2 e 3 do controlador. Links de privacidade e termos abrem documentos internos. Somente o crédito Socialy abre um navegador.

As imagens são carregadas sob demanda com `ResourceLoader.exists`. Sem os arquivos visuais, a navegação permanece utilizável. Os ícones das armas são atualizados apenas quando muda o equipamento.
