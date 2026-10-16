# ROCCAT Syn Pro Air — diagnóstico e gerenciamento de áudio

Ferramenta portátil para manter a saída de reprodução escolhida pelo usuário, investigar mudanças nos endpoints do ROCCAT Syn Pro Air e aplicar ajustes reversíveis no Windows 10 e 11.

[![Versão 1.2.0](https://img.shields.io/badge/vers%C3%A3o-1.2.0-blue)](https://github.com/Emertels/Roccat-Syn-Pro-Air-Fix/releases/tag/v1.2.0) · [English](README-EN.md) · [Changelog](CHANGELOG-PT-BR.md)

> **Limite importante:** a opção 1 é uma proteção temporária: enquanto o painel fica aberto, ela reaplica a saída de reprodução que você escolheu se o Windows mudar para outra. Isso contorna a troca automática, mas não identifica nem corrige a causa que faz o headset sumir e reaparecer. O evento de áudio 65 registra uma mudança de estado, mas não identifica quem a iniciou.

## O que sabemos sobre a falha

No caso relatado, o log mostrou os endpoints de saída e microfone alternando entre desativado e ativo, com `ProblemCode=0`, enquanto o dongle permaneceu listado. Isso confirma uma oscilação dos endpoints de áudio, mas ainda não identifica se começou no driver, no Swarm, no caminho USB, no enlace sem fio ou nos serviços de áudio do Windows. A nova leitura registra separadamente quando o Windows troca a saída padrão.

O painel nunca escolhe o headset automaticamente: na opção 1, você seleciona explicitamente a saída que quer manter. A proteção mexe somente nos três papéis de reprodução do Windows e deixa o dispositivo padrão de captura/microfone intocado. Ela só funciona enquanto o painel estiver aberto; depois de ESC, a saída escolhida permanece padrão, mas o Windows ou outro programa ainda pode trocá-la.

O ajuste do padrão de reprodução usa uma interface de política do Windows que não é documentada publicamente. Se o Windows não confirmar a alteração, o script restaura os papéis anteriores quando possível e abre `mmsys.cpl` para seleção manual. Saídas escolhidas individualmente por aplicativos não são sobrescritas por esta proteção.

## Base técnica

O Core Audio do Windows consulta o endpoint padrão por direção e papel (`Console`, `Multimídia` ou `Comunicações`). A documentação também trata a mudança do endpoint padrão e a mudança de estado do endpoint como notificações distintas. Por isso, o relatório registra esses sinais separadamente; nenhum deles, isoladamente, revela qual programa iniciou a mudança. Os IDs de endpoint são tratados como identificadores opacos, conforme a documentação da Microsoft.

Referências: [consulta do endpoint padrão](https://learn.microsoft.com/pt-br/windows/win32/api/mmdeviceapi/nf-mmdeviceapi-immdeviceenumerator-getdefaultaudioendpoint), [notificação de troca do dispositivo padrão](https://learn.microsoft.com/en-us/windows/win32/api/mmdeviceapi/nf-mmdeviceapi-immnotificationclient-ondefaultdevicechanged), [notificação de estado do endpoint](https://learn.microsoft.com/en-us/windows/win32/api/mmdeviceapi/nf-mmdeviceapi-immnotificationclient-ondevicestatechanged) e [estados possíveis do endpoint](https://learn.microsoft.com/en-us/windows/win32/coreaudio/device-state-xxx-constants). A interface privada usada para aplicar o padrão não faz parte da API pública documentada; a compatibilidade depende da implementação do Windows.

## Menu

| Opção | O que faz | Efeitos e limites |
|---|---|---|
| **1 — Fixar saída padrão** | Lista as saídas ativas; você escolhe uma. O painel a define como padrão para Console, Multimídia e Comunicações e reaplica a escolha se ela mudar enquanto o monitor está aberto. | Não altera o microfone nem o driver Waves. A proteção para com ESC/Ctrl+C; a saída escolhida permanece padrão ao sair. Registra trocas em `default-output-guard.log`. |
| **2 — Swarm temporário** | Registra o estado anterior do driver, habilita/inicia Waves e abre o Swarm. Aguarda o processo da interface `ROCCAT_Swarm.exe`, ignorando o auxiliar `ROCCAT_Swarm_Monitor.exe`, que pode ficar residente. | Serve para configurar EQ/microfone; não corrige a troca de saída. Feche Swarm completamente pelo ícone da bandeja ou use ESC/Ctrl+C para restaurar o driver. O Swarm fica aberto quando o monitor é cancelado. |
| **3 — Monitoramento passivo** | Acompanha o evento 65, estados PnP dos endpoints e os padrões de reprodução Console, Multimídia e Comunicações. | Somente leitura: não altera driver, endpoint, microfone ou saída padrão. ESC/Ctrl+C volta ao menu. O registro fica em `%LOCALAPPDATA%\RoccatSynProManager\diagnostics\sentinela.log`. |
| **4 — Energia USB e comunicações** | Salva uma cópia e ajusta a suspensão seletiva USB nos planos de energia, a atenuação de comunicações do usuário e, quando a consulta WMI permite, a economia de energia dos Root Hubs. | As alterações verificadas e a cópia ficam em `%LOCALAPPDATA%\RoccatSynProManager\system-backup.json`. `R` restaura a cópia, `Enter` aplica/reaplica e `Q` cancela. Pode não resolver a falha. |
| **5 — Diagnóstico e painel de som** | Gera um relatório com endpoints PnP, driver, eventos recentes de áudio/USB, saída padrão de reprodução por função e abre `mmsys.cpl`. | O relatório fica na pasta `diagnostics`. Revise-o antes de compartilhar: inclui nome do computador, IDs de dispositivos e eventos locais. |
| **6 — Idioma** | Escolhe um entre dez idiomas, com detecção automática inicial. | As traduções do pacote portátil estão dentro do próprio `.ps1`; a escolha fica no perfil local do usuário. |

Para proteger a caixa de som, escolha-a na lista da opção 1 e deixe o painel aberto enquanto usa o computador. Se a saída escolhida ficar indisponível, o script aguarda que ela reapareça e registra o estado. A opção 2 pode alterar temporariamente o driver Waves e afetar efeitos do Swarm. A opção 1 não modifica a captura/microfone; nenhuma opção garante LEDs ou outros controles.

## Como iniciar

1. Baixe `Roccat-Syn-Pro-Air-Fix-v1.2.0-Portable.zip` na [página da versão](https://github.com/Emertels/Roccat-Syn-Pro-Air-Fix/releases/tag/v1.2.0) e extraia os dois arquivos na mesma pasta.
2. Abra **`Roccat-SynPro-Manager.vbs`**. Ele solicita elevação pelo UAC e inicia o PowerShell sem passar por uma janela de CMD.
3. Para impedir que a reprodução volte ao headset durante a sessão, escolha **1**, selecione a caixa de som e mantenha o painel aberto. `ESC` encerra a proteção e volta ao menu; `ESC` no menu principal fecha o painel.

O pacote é portátil e não tem instalador: contém somente o script PowerShell e o lançador VBS. A execução requer privilégios de administrador para as opções que alteram o driver ou as configurações do sistema. O Windows pode mostrar um aviso de segurança para scripts baixados; confira a origem e o conteúdo antes de autorizar.

## Dados e restauração

O script guarda configuração, cópia de segurança e diagnósticos em `%LOCALAPPDATA%\RoccatSynProManager` (com fallback para a pasta do script se o perfil não estiver disponível). Opções que alteram configurações verificam os valores antes/depois sempre que o Windows expõe uma forma de consulta. A opção 4 pode restaurar a cópia; não apague `system-backup.json` antes de restaurar.

O monitoramento da opção 3 é somente leitura. Ele separa a reativação do endpoint da troca real de saída padrão. Um evento ainda não identifica o programa responsável; compare os horários com a árvore PnP e eventos USB/Kernel-PnP. Registros e cópias ficam em `%LOCALAPPDATA%\RoccatSynProManager`.

## Arquivos do repositório

- `Roccat-SynPro-Manager.ps1`: fonte do painel. No repositório, as traduções são editadas em `i18n.json`; o processo de pacote as incorpora ao script distribuído.
- `Roccat-SynPro-Manager.vbs`: lançador elevado, sem janela intermediária de CMD.
- `tools/New-PortablePackage.ps1`: monta e confere um ZIP com somente o `.ps1` e o `.vbs`.
- `AGENTS-PT-BR.md` / `AGENTS-EN.md`: arquitetura e diretrizes de manutenção.

## Créditos

Desenvolvido com **Antigravity e Codex**. O projeto é distribuído sob a licença MIT; consulte [LICENSE](LICENSE).
