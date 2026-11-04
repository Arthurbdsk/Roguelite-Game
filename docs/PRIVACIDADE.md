# Política de privacidade

Brasafria 0.4.1 não exige cadastro e não possui anúncios ou análise de uso. O solo funciona offline. Progresso, ouro, selos, habilidades, estatísticas e preferências ficam no computador, em `%APPDATA%\Godot\app_userdata\Brasafria\profile.json`, com possíveis cópias `.tmp` e `.bak`. Testes locais podem usar perfis separados com nomes próprios.

Ao criar ou entrar em sala, o jogo conecta ao serviço configurado e transmite nome escolhido, código da sala, habilidades permanentes e mensagens de movimento, combate e progressão da tentativa. Os participantes recebem os nomes e o estado necessário ao jogo; ofertas individuais são encaminhadas somente ao jogador correspondente. O endereço de rede é necessário à conexão e pode ser processado pela infraestrutura de hospedagem.

O relay desta implementação mantém salas e mensagens em memória, sem banco de perfis ou persistência de histórico. Salas são removidas quando o anfitrião sai. O provedor de hospedagem pode manter registros técnicos conforme suas próprias configurações e regras. A hospedagem pública ainda não foi configurada nesta entrega. Ouro e compras permanentes continuam locais, sem sincronização de conta ou nuvem.

Para remover o progresso, feche o jogo e remova o perfil e suas cópias de segurança. Uma tentativa interrompida não é retomada pelo perfil.

O crédito [Feito por Socialy](https://www.instagram.com/socialy_webdesign/) abre o Instagram no navegador, sujeito às regras desse serviço.

A versão 0.4.1 pode guardar registros locais de conexão com endereço do serviço, horário, código de encerramento e contadores técnicos. Eles ficam em `network_<PID>.log` na pasta de dados do jogo e podem ser apagados com o jogo fechado. Não incluem conteúdo das mensagens de partida ou histórico de escolhas.
