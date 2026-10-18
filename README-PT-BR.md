# ROCCAT Syn Pro Air — gerenciamento e diagnóstico de áudio

[![Versão 1.2.0](https://img.shields.io/badge/vers%C3%A3o-1.2.0-blue)](https://github.com/Emertels/Roccat-Syn-Pro-Air-Fix/releases/tag/v1.2.0) · [English](README-EN.md) · [Changelog](CHANGELOG-PT-BR.md)

Painel portátil para Windows 10/11, com dez idiomas, correção reversível do serviço Waves, escolha explícita da saída de áudio e diagnóstico dos endpoints do SYN Pro Air.

## O que foi identificado

Na investigação de 18/10/2026, saída e microfone do SYN Pro Air alternavam entre desativado e ativo, enquanto o dongle continuava presente. A reprodução também voltava ao headset após escolher a caixa de som. Encerrar apenas os auxiliares do Swarm/Waves não interrompeu o ciclo.

Em um teste controlado, parar **Waves Audio Services (`WavesTBSvc`)** interrompeu as trocas; iniciar esse mesmo serviço fez o ciclo voltar. Com a nova correção aplicada, foram observados **60 segundos sem troca de saída, sem amostras fora da saída escolhida e sem eventos de mudança de estado do SYN Pro Air**, preservando os três padrões de captura. Posteriormente o serviço foi restaurado a pedido do usuário para testar pelo painel; o usuário relatou o retorno da falha.

Isso associa a falha deste computador ao funcionamento desse componente Waves. Ainda não identifica a instrução interna defeituosa, nem demonstra que todos os casos de desconexão tenham a mesma causa. O script oferece um contorno persistente e reversível; não modifica os binários do fabricante. A persistência após reiniciar precisa ser confirmada pelo usuário. Atualizações ou reparos do fabricante podem reativar o serviço.

## Como usar a opção principal

1. Baixe e extraia os dois arquivos do [ZIP da versão 1.2.0](https://github.com/Emertels/Roccat-Syn-Pro-Air-Fix/releases/tag/v1.2.0).
2. Abra **`Roccat-SynPro-Manager.vbs`** e aceite o UAC. O lançador abre o PowerShell diretamente, sem uma janela intermediária de CMD.
3. Escolha **1**, pressione **Enter** para aplicar e selecione sua saída na lista — por exemplo, CREATIVE 2.1.
4. Acompanhe as quatro etapas: cópia do serviço, desativação/parada do serviço Waves, aplicação da saída escolhida nos três papéis de reprodução e observação por 30 segundos.
5. Ao terminar, confira o resultado. O contorno não depende de manter o painel aberto. Para desfazer, volte à opção **1** e pressione **R**.

A observação não reaplica continuamente o padrão: ela verifica se surgiram novas trocas após o ajuste. Se for interrompida, se os eventos estiverem indisponíveis ou se houver novas alterações, a estabilidade fica **não confirmada**. O relatório completo fica em `diagnostics\last-system-repair.json` dentro da pasta de dados.

## Funções do menu

- **1 — Correção do serviço Waves:** salva o estado original uma vez, define `WavesTBSvc` como Desativado, para o serviço e verifica o estado. Não tenta desativar o driver de kernel `WavesTBVirtual`. Seleciona somente a saída escolhida pelo usuário; não altera o microfone padrão. **R** restaura o serviço. **P** abre a proteção opcional de saída, que reaplica a escolha enquanto a janela estiver aberta e termina com ESC/Ctrl+C.
- **2 — Swarm temporário:** guarda os estados de serviço, driver e saída; habilita temporariamente Waves e abre o Swarm para configuração. Acompanha a interface `ROCCAT_Swarm.exe`, ignorando o monitor residente. Quando o Swarm sai completamente ou você usa ESC/Ctrl+C, restaura o estado anterior. Se o Swarm apenas minimizar para a bandeja, o monitor continua aguardando. Cancelar o monitor deixa o Swarm aberto. O ciclo pode voltar durante essa sessão porque o serviço foi reativado. Uma sessão interrompida à força é recuperada na próxima abertura; falhas preservam a cópia para nova tentativa.
- **3 — Monitoramento passivo:** registra eventos de áudio 65, estados PnP, padrões de reprodução e mudanças do serviço Waves. Não aplica correções. ESC/Ctrl+C volta ao menu.
- **4 — Energia USB e comunicações:** salva e verifica ajustes de suspensão USB, atenuação de comunicações e economia dos Root Hubs quando acessíveis. **R** restaura essa cópia. A restauração de energia não altera o serviço/driver Waves.
- **5 — Diagnóstico e painel de som:** salva relatório de endpoints, pais PnP, serviço, driver, processos relevantes, padrões de reprodução/captura e eventos recentes; abre `mmsys.cpl`.
- **6 — Idioma:** dez traduções incorporadas ao PS1 portátil; preferência salva no perfil do usuário.
- **0 ou ESC no menu:** fecha o painel. Nos monitores, ESC/Ctrl+C retorna ao menu.

## Efeito no headset e no Swarm

A opção 1 deixa os dispositivos de áudio e microfone habilitados e preserva o padrão de captura. Não encerra o Swarm nem seu monitor. Entretanto, desativar o serviço Waves pode indisponibilizar equalização, efeitos e processamento avançado dependentes desse serviço. O Swarm abrir não comprova que todos os seus efeitos estão ativos.

O usuário observou funcionamento do headset e do Swarm durante o contorno. Volume audível, qualidade do microfone, LEDs e cada controle do Swarm exigem confirmação no equipamento; a verificação do script mede estados e padrões do Windows. A opção 2 permite uma sessão temporária com Waves ativo, com o risco de a falha reaparecer nessa sessão.

## Dados e restauração

Os dados ficam em `%LOCALAPPDATA%\RoccatSynProManager`, com fallback para a pasta do script:

- `config.json`: preferência de idioma.
- `waves-service-backup.json`: estado original do serviço, usado pela opção 1 / R. Reaplicar não sobrescreve esse original.
- `swarm-session.json`: estado temporário pendente da opção 2; removido após a restauração confirmada do serviço e driver. A restauração da saída também é tentada e uma falha é informada separadamente.
- `system-backup.json`: cópia dos ajustes de energia/comunicações.
- `diagnostics`: relatórios e registros de observação.

Não apague cópias necessárias para desfazer alterações. O JSON separado de traduções não é necessário na pasta portátil. Esses arquivos de dados têm outra finalidade e são criados durante o uso. Relatórios podem conter nome do computador, IDs e eventos locais; revise antes de compartilhar.

## Base técnica e manutenção

O Windows distingue [mudança de padrão](https://learn.microsoft.com/en-us/windows/win32/api/mmdeviceapi/nf-mmdeviceapi-immnotificationclient-ondefaultdevicechanged) e [mudança de estado do endpoint](https://learn.microsoft.com/en-us/windows/win32/api/mmdeviceapi/nf-mmdeviceapi-immnotificationclient-ondevicestatechanged). O evento 65 isolado não identifica o processo responsável. Os padrões são consultados por [direção e papel](https://learn.microsoft.com/en-us/windows/win32/api/mmdeviceapi/nf-mmdeviceapi-immdeviceenumerator-getdefaultaudioendpoint). O setter de reprodução usa `IPolicyConfig`, interface sem documentação pública; em falhas, o painel oferece seleção manual no painel de som. Preferências de saída individuais dos aplicativos não são sobrescritas.

No repositório, `i18n.json` é a fonte editável das traduções. `tools/New-PortablePackage.ps1` incorpora esse conteúdo ao script e gera um PS1 UTF-8 com BOM, compatível com Windows PowerShell 5.1. O ZIP contém **somente PS1 e VBS**, sem documentação, BAT ou JSON separado. É um pacote portátil, não um instalador. Os guias [AGENTS-PT-BR.md](AGENTS-PT-BR.md) e [AGENTS-EN.md](AGENTS-EN.md) descrevem manutenção e limites.

## Créditos

Desenvolvido com **Antigravity e Codex**. Licença [MIT](LICENSE).
