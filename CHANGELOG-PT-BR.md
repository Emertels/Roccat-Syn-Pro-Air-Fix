# Changelog — ROCCAT Syn Pro Air

## [1.2.0] — revisão de 2026-10-18

### Correção principal

- A opção 1 atua em **Waves Audio Services (`WavesTBSvc`)**, componente isolado por testes de parada/início na máquina investigada. Não depende de parar o driver de kernel que falhava na versão anterior.
- Fluxo em quatro etapas: cópia original, desativação/parada do serviço, conferência dos dispositivos sem seleção de saída e observação de 30 segundos. A configuração permanece salva no Windows sem exigir painel aberto.
- A aplicação e a estabilidade são verificadas separadamente. Interrupção, eventos inacessíveis ou novas alterações impedem confirmação de estabilidade. O relatório registra os valores reais.
- **R → W** restaura o serviço original. A opção 1 não solicita seleção de saída e não troca padrões de reprodução/captura. Verifica headset, microfone e dispositivos antes ativos; perda de disponibilidade tenta restaurar o serviço e registra a falha.

### Interface e menu simplificados

- Opção 1 executa diretamente com **1 + Enter**, sem confirmação extra e sem escolher ou impor um dispositivo padrão. Você troca a saída manualmente no Windows.
- Menu atual: **1 correção; 2 monitoramento; 3 diagnóstico; 4 idioma; R restauração; 0 sair**.
- Swarm temporário e aplicação de ajustes USB/energia retirados do menu. Recuperação de sessões antigas e restauração de ajustes de energia preservadas por compatibilidade.
- A opção R oferece **W** para restaurar o serviço Waves e **E** para restaurar a cópia antiga de energia/comunicações.
- Português revisado com acentos e cedilha nos menus, etapas, dicas e diagnósticos, preservando UTF-8 com BOM.
- Barra sobreposta do PowerShell substituída por uma barra de porcentagem e tempo abaixo da etapa, atualizada na mesma linha. Interromper não mostra 100% artificialmente.
- Verificação de disponibilidade via Core Audio: headset, microfone e dispositivos antes ativos devem permanecer disponíveis. Perda de disponibilidade tenta restaurar o serviço e registra a falha.
- Cabeçalho consulta a API de áudio para não confundir PnP Unknown com endpoint desativado. Consultas de planos de energia retiradas da inicialização.
- Após reativar o headset manualmente, o usuário relatou que o ciclo parou. Uma leitura posterior mostrou headset, microfone e CREATIVE ativos; isso não comprova áudio audível.
- Código e textos dos fluxos retirados foram removidos; dez idiomas incorporados ao PS1, com salvamento da preferência no perfil.
- Monitoramento passivo e diagnósticos preservados. README e guias técnicos em português/inglês alinhados ao menu atual.
- ZIP contém somente PS1 e VBS, sem JSON separado, documentação ou BAT.

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
