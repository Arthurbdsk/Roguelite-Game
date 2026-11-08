# PC 0.25.0 e atualização Android autorizada

Entrega em validação. Este pedido autoriza uma atualização Android, que volta a ficar congelada depois dela. Nenhuma publicação em loja foi solicitada ou realizada.

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

Resultados finais, hashes, commits Android, assinatura e limites de testes serão registrados após a exportação e os ensaios mistos. O usuário fará os testes em aparelho físico e em redes distintas; emulador e travessia do relay público pela mesma conexão não comprovam esses cenários.
