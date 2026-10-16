# Guia técnico para manutenção e agentes

Este arquivo descreve o que o repositório implementa. Não trate hipóteses, nomes de menu ou mensagens históricas como evidência de causa ou de eficácia.

## Objetivo e evidência disponível

O projeto ajuda a observar endpoints de áudio do ROCCAT Syn Pro Air e oferece ajustes reversíveis no Windows 10/11. No relato atual, o dongle pode permanecer conectado enquanto o endpoint de áudio/microfone some e reaparece. O status PnP do dongle não informa se o headset está ligado nem identifica quem iniciou a mudança do endpoint. O evento Audio/Operational 65, quando disponível, registra uma mudança de estado; não é prova de que Waves, Swarm, USB ou hardware seja a causa.

Não afirme que a solução é definitiva, que `usbaudio.sys` sempre será selecionado, que LEDs continuarão funcionando ou que um evento 65 identifica o processo iniciador. Validação final requer observar a máquina e o headset do usuário durante a falha.

## Estrutura e execução

- `Roccat-SynPro-Manager.ps1`: painel PowerShell, compatível com Windows PowerShell 5.1.
- `i18n.json`: fonte editável das traduções de dez idiomas.
- `Roccat-SynPro-Manager.vbs`: solicita elevação pelo UAC e inicia PowerShell; usa `Sysnative` se o host VBS for 32 bits em Windows 64 bits.
- `Roccat-SynPro-Manager.bat`: wrapper legado de compatibilidade, não incluído no pacote portátil.
- `tools/New-PortablePackage.ps1`: substitui exatamente o marcador `@@ROCCAT_I18N_JSON_EMBED@@`, grava PS1 UTF-8 com BOM e cria/verifica o ZIP de distribuição.
- `README.md` e `README-EN.md`: guias de uso; `README-PT-BR.md` é a cópia em português para link explícito.
- `CHANGELOG-PT-BR.md` e `CHANGELOG-EN.md`: histórico por versão.

O ZIP publicado contém só `Roccat-SynPro-Manager.ps1` (traduções embutidas) e `Roccat-SynPro-Manager.vbs`. Não é instalador e não inclui README, arquivos de agentes, JSON de idioma ou BAT.

## Comportamento das opções

1. **Modo estável:** faz backup validado antes de mudar `HKLM:\SYSTEM\CurrentControlSet\Services\WavesTBVirtual\Start` para 4 e parar o driver; verifica a parada. Não altera o endpoint padrão. Pode retirar recursos Waves do Swarm. Restauração do estado salvo é feita pela opção 4 (`R`).
2. **Swarm temporário:** lê estado anterior de inicialização/execução, define Start=3, inicia Waves e Swarm. Ao fechar Swarm ou cancelar com ESC/Ctrl+C, tenta restaurar o estado lido. Cancelar o monitor deixa Swarm aberto; finalizar o processo PowerShell à força pode interromper a restauração.
3. **Sentinela passiva:** observa evento 65 e estados dos endpoints AudioEndpoint de saída/microfone; não altera driver, PnP, endpoint ou saída padrão. Registra transições em `sentinela.log`; continua consultando mesmo quando não há novos eventos. Teclas ESC/Ctrl+C retornam ao menu.
4. **Energia/comunicações:** guarda valores de USB selective suspend por esquema de energia, valor anterior de UserDuckingPreference e estados WMI que consegue ler. Aplica e confere as mudanças; relata quando não consegue enumerar ou verificar Root Hubs. A restauração exige backup com os dados necessários.
5. **Diagnóstico:** salva estado PnP, pai do endpoint, código de problema quando disponível, informações do driver/serviços e eventos consultados; abre `mmsys.cpl`. O relatório não prova causa.
6. **Idioma:** grava preferência no perfil local; traduções vêm de `i18n.json` no repositório ou do JSON incorporado no script publicado.

Arquivos de dados ficam em `%LOCALAPPDATA%\RoccatSynProManager`, com fallback para a pasta do script. A opção ESC no menu principal encerra o processo.

## Regras de manutenção

- Preserve o default output do Windows. Não reintroduza seleção forçada do headset, sentinel que “restaura” sem comprovar, kill automático de processos Waves, ou alteração silenciosa de endpoints.
- Antes de mudar registro, serviço de driver ou energia, confirme que a cópia necessária é completa; depois verifique o estado resultante e informe falhas parciais.
- Não remova nem substitua arquivos de driver do Windows. Alterações em `WavesTBVirtual` devem ser documentadas como mudanças no serviço, com possível impacto em recursos Swarm.
- Atualize as traduções em todos os dez idiomas para cada chave usada pelo menu/monitor; confirme que cada array contém dez valores e que o JSON continua válido.
- Mantenha o marcador de embedding uma única vez no PS1 de origem. Gere a distribuição pelo script de pacote, confira o ZIP e não adicione documentação ao asset portátil.
- Use evidência observada para separar fato de hipótese. Não acrescente IDs de hardware/controladores, diagnósticos de banda USB ou explicações internas do Windows sem dados específicos da máquina e fonte confiável.
