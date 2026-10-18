# Changelog — ROCCAT Syn Pro Air

## [1.2.0] — revisão de 2026-10-18

### Correção principal

- A opção 1 atua em **Waves Audio Services (`WavesTBSvc`)**, componente isolado por testes de parada/início na máquina investigada. Não depende de parar o driver de kernel que falhava na versão anterior.
- Fluxo em quatro etapas: cópia original, desativação/parada do serviço, seleção explícita da saída e observação de 30 segundos. A configuração permanece salva no Windows sem exigir painel aberto.
- A aplicação e a estabilidade são verificadas separadamente. Interrupção, eventos inacessíveis ou novas alterações impedem confirmação de estabilidade. O relatório registra os valores reais.
- **R** restaura o serviço original; **P** mantém disponível o guardião temporário de saída. Nenhum modo escolhe o headset automaticamente ou altera o microfone padrão.

### Melhorias nas demais opções

- Swarm temporário salva serviço, driver e padrões de reprodução; restaura no bloco finally e recupera sessões interrompidas na próxima abertura. Auxiliares iniciados pela sessão são identificados por PID, caminho e horário. Falhas mantêm a cópia.
- A opção 2 informa que reativar Waves pode trazer o ciclo de volta; fechar apenas a janela para a bandeja não encerra necessariamente o Swarm.
- Monitoramento passivo inclui mudanças do serviço e separa estados dos endpoints de trocas de saída. Consulta PnP compartilhada reduz trabalho repetido.
- Energia e comunicações têm restauração independente do driver. Uma falha de leitura do driver não bloqueia essa opção.
- Diagnóstico inclui configuração do serviço, processos relevantes e padrões de captura, além de PnP, reprodução e eventos.
- Preferência de idioma grava primeiro no perfil usado pela leitura; dez traduções incorporadas no PS1 portátil.
- Lançador VBS direto para PowerShell, cópias independentes por finalidade e mensagens sem promessas de “restauração” não confirmada.
- README e guias de manutenção em português e inglês atualizados. ZIP contém somente PS1 e VBS, sem JSON separado, documentação ou BAT.

### Evidência e limites

- Com o serviço desativado/parado, observação de 60 segundos registrou zero trocas, zero amostras fora da saída escolhida e zero eventos de estado SYN Pro Air; captura permaneceu igual. Iniciar o serviço reproduziu o ciclo em observação controlada. Após restauração para teste pelo painel, o usuário também relatou retorno da falha.
- O teste não identifica o defeito interno do fabricante nem garante todos os casos ou persistência após reiniciar. O contorno pode afetar EQ/efeitos Waves. Áudio audível, LEDs e cada controle do Swarm dependem de confirmação no equipamento. Atualizações/reparos do fabricante podem reativar o serviço.

### Créditos

- Desenvolvido com **Antigravity e Codex**.

## [1.2.0] — publicação inicial em 2026-10-16

- Monitoramento passivo, guardião de saída escolhida, restauração temporária do driver, verificações de energia, lançador VBS sem CMD e pacote com traduções incorporadas.
- A revisão de 18/10 substitui o ZIP dessa mesma versão a pedido do mantenedor e incorpora a investigação do serviço Waves.

## [1.0.0] — 2026-09-26

- Primeira versão pública com gerenciamento de driver, monitoramento, energia, painel de som e idiomas.
