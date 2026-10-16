# ROCCAT Syn Pro Air — diagnóstico e gerenciamento de áudio

Ferramenta portátil para investigar mudanças nos endpoints de áudio do ROCCAT Syn Pro Air e aplicar alguns ajustes reversíveis no Windows 10 e 11.

[![Versão 1.2.0](https://img.shields.io/badge/vers%C3%A3o-1.2.0-blue)](https://github.com/Emertels/Roccat-Syn-Pro-Air-Fix/releases/tag/v1.2.0) · [English](README-EN.md) · [Changelog](CHANGELOG-PT-BR.md)

> **Limite importante:** esta versão melhora o diagnóstico e torna as ações do painel mais cuidadosas. Ela não prova a causa das desconexões nem promete uma correção permanente. O evento de áudio 65 mostra uma mudança de estado, mas sozinho não diz qual programa, driver ou componente iniciou a mudança.

## O que sabemos sobre a falha

No caso relatado, o dongle USB continua conectado enquanto o Windows faz o endpoint do headset/microfone desaparecer e reaparecer. Isso aponta para uma mudança na enumeração de áudio do Windows, mas o estado PnP `OK` do dongle não confirma que o headset sem fio esteja ligado, que o enlace de rádio esteja estável ou que o áudio esteja funcionando. As causas ainda a comparar incluem o driver `WavesTBVirtual`, o Swarm, a conexão USB e os serviços de áudio do Windows.

O painel não escolhe o Syn Pro Air como saída padrão. Ele também não consegue detectar se o headset está fisicamente ligado quando apenas o dongle está conectado.

## Menu

| Opção | O que faz | Efeitos e limites |
|---|---|---|
| **1 — Modo estável** | Salva ou confere uma cópia do estado e tenta parar o serviço `WavesTBVirtual`, definir sua inicialização como desativada e verificar o resultado. | Pode desativar recursos de áudio Waves no Swarm. Não escolhe uma saída padrão e não garante estabilidade. A opção 4 permite restaurar o estado salvo. |
| **2 — Swarm temporário** | Registra o estado anterior do driver, habilita/inicia o Waves e abre o Swarm. Ao fechar o Swarm, tenta restaurar o estado anterior. | `ESC` ou `Ctrl+C` encerra o monitor e também tenta restaurar o driver; o Swarm fica aberto e pode perder recursos Waves. Fechar à força a janela/processo pode impedir a restauração automática. |
| **3 — Monitoramento passivo** | Acompanha o evento 65 do log `Microsoft-Windows-Audio/Operational` e os estados PnP dos endpoints de saída e microfone. | Não altera driver, endpoint nem saída padrão. `ESC` ou `Ctrl+C` volta ao menu. O registro fica em `%LOCALAPPDATA%\RoccatSynProManager\diagnostics\sentinela.log`. |
| **4 — Energia USB e comunicações** | Salva uma cópia e ajusta a suspensão seletiva USB nos planos de energia, a atenuação de comunicações do usuário e, quando a consulta WMI permite, a economia de energia dos Root Hubs. | As alterações verificadas e a cópia ficam em `%LOCALAPPDATA%\RoccatSynProManager\system-backup.json`. `R` restaura a cópia, `Enter` aplica/reaplica e `Q` cancela. Pode não resolver a falha. |
| **5 — Diagnóstico e painel de som** | Gera um relatório com endpoints PnP, driver, eventos recentes de áudio/USB e abre `mmsys.cpl`. | O relatório fica na pasta `diagnostics`. Revise-o antes de compartilhar: inclui nome do computador, IDs de dispositivos e eventos locais. |
| **6 — Idioma** | Escolhe um entre dez idiomas, com detecção automática inicial. | As traduções do pacote portátil estão dentro do próprio `.ps1`; a escolha fica no perfil local do usuário. |

Na opção 1, o driver Waves é alterado no Registro e parado como serviço de driver. Isso é reversível pela cópia salva, mas pode afetar EQ, surround, monitoramento ou outros recursos do Swarm. Confira reprodução, microfone e o Swarm depois de qualquer mudança. LEDs e outros controles não são garantidos por este script.

## Como iniciar

1. Baixe `Roccat-Syn-Pro-Air-Fix-v1.2.0-Portable.zip` na [página da versão](https://github.com/Emertels/Roccat-Syn-Pro-Air-Fix/releases/tag/v1.2.0) e extraia os dois arquivos na mesma pasta.
2. Abra **`Roccat-SynPro-Manager.vbs`**. Ele solicita elevação pelo UAC e inicia o PowerShell sem passar por uma janela de CMD.
3. Leia cada mensagem antes de escolher uma opção. `ESC` no menu principal fecha o painel; `ESC` nas opções de monitoramento retorna ao menu.

O pacote é portátil e não tem instalador: contém somente o script PowerShell e o lançador VBS. A execução requer privilégios de administrador para as opções que alteram o driver ou as configurações do sistema. O Windows pode mostrar um aviso de segurança para scripts baixados; confira a origem e o conteúdo antes de autorizar.

## Dados e restauração

O script guarda configuração, cópia de segurança e diagnósticos em `%LOCALAPPDATA%\RoccatSynProManager` (com fallback para a pasta do script se o perfil não estiver disponível). Opções que alteram configurações verificam os valores antes/depois sempre que o Windows expõe uma forma de consulta. A opção 4 pode restaurar a cópia; não apague `system-backup.json` antes de restaurar.

O monitoramento é somente leitura. Um evento de endpoint não identifica a causa; compare os horários do relatório com a árvore PnP e os eventos de USB/Kernel-PnP para reunir mais evidências. Para investigar a falha original, rode a opção 3 antes e durante a oscilação e depois gere o relatório da opção 5.

## Arquivos do repositório

- `Roccat-SynPro-Manager.ps1`: fonte do painel. No repositório, as traduções são editadas em `i18n.json`; o processo de pacote as incorpora ao script distribuído.
- `Roccat-SynPro-Manager.vbs`: lançador elevado, sem janela intermediária de CMD.
- `tools/New-PortablePackage.ps1`: monta e confere um ZIP com somente o `.ps1` e o `.vbs`.
- `AGENTS-PT-BR.md` / `AGENTS-EN.md`: arquitetura e diretrizes de manutenção.

## Créditos

Desenvolvido por **Emerson Teles**. O projeto é distribuído sob a licença MIT; consulte [LICENSE](LICENSE).
