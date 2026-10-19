# ROCCAT Syn Pro Air — gerenciamento e diagnóstico de áudio

[![Versão 1.1.0](https://img.shields.io/badge/vers%C3%A3o-1.1.0-blue)](https://github.com/Emertels/Roccat-Syn-Pro-Air-Fix/releases/tag/v1.1.0) · [English](README-EN.md) · [Changelog](CHANGELOG-PT-BR.md)

Painel portátil para Windows 10/11, com dez idiomas, correção reversível do serviço Waves, preservação dos dispositivos e padrões de áudio e diagnóstico dos endpoints do SYN Pro Air.

## O que foi identificado

Na investigação de 18/10/2026, saída e microfone do SYN Pro Air alternavam entre desativado e ativo, enquanto o dongle continuava presente. A reprodução também voltava ao headset após escolher a caixa de som. Encerrar apenas os auxiliares do Swarm/Waves não interrompeu o ciclo.

Em um teste controlado, parar **Waves Audio Services (`WavesTBSvc`)** interrompeu as trocas; iniciar esse mesmo serviço fez o ciclo voltar. Com a nova correção aplicada, foram observados **60 segundos sem troca de saída, sem amostras fora da saída escolhida e sem eventos de mudança de estado do SYN Pro Air**, preservando os três padrões de captura. Posteriormente o serviço foi restaurado a pedido do usuário para testar pelo painel; o usuário relatou o retorno da falha.

Isso associa a falha deste computador ao funcionamento desse componente Waves. Ainda não identifica a instrução interna defeituosa, nem demonstra que todos os casos de desconexão tenham a mesma causa. O script oferece um contorno persistente e reversível; não modifica os binários do fabricante. A persistência após reiniciar precisa ser confirmada pelo usuário. Atualizações ou reparos do fabricante podem reativar o serviço.

## Como usar a opção principal

1. Baixe e extraia os dois arquivos do [ZIP da versão 1.1.0](https://github.com/Emertels/Roccat-Syn-Pro-Air-Fix/releases/tag/v1.1.0).
2. Abra **`Roccat-SynPro-Manager.vbs`** e aceite o UAC. O lançador abre o PowerShell diretamente, sem uma janela intermediária de CMD.
3. Escolha **1** e pressione **Enter** para aplicar. Não é necessário escolher um dispositivo; os padrões atuais são preservados.
4. Acompanhe as quatro etapas: cópia do serviço, desativação/parada do serviço Waves, conferência de disponibilidade do headset, microfone e dispositivos antes ativos e observação por 30 segundos.
5. Ao terminar, confira o resultado. O contorno não depende de manter o painel aberto. Para desfazer, use **R → W** no menu principal.

A correção não troca o padrão e não desativa endpoints. A observação confere os padrões existentes e a disponibilidade dos dispositivos. Se o headset, o microfone ou um dispositivo antes ativo ficar indisponível, tenta restaurar o serviço anterior e informa o resultado no relatório. A verificação de dispositivos não comprova áudio audível. Se for interrompida, se os eventos estiverem indisponíveis ou se houver novas alterações, a estabilidade fica **não confirmada**. O relatório completo fica em `diagnostics\last-system-repair.json` dentro da pasta de dados.

## Funções do menu

- **1 — Corrigir troca automática de áudio (desativar Waves):** digite **1 e Enter** no menu principal. Inicia diretamente as etapas, sem confirmação extra nem escolha de dispositivo. Salva o estado original, desativa/para somente `WavesTBSvc`, confere headset/microfone e dispositivos antes ativos e observa por 30 segundos. Não desativa endpoints nem o driver `WavesTBVirtual`; não escreve nos padrões de reprodução/captura. Se houver indisponibilidade, tenta restaurar o serviço e informa a falha. Barra com porcentagem aparece abaixo da etapa.
- **2 — Monitoramento passivo:** registra eventos de áudio 65, estados PnP, padrões de reprodução e serviço Waves. Somente leitura. ESC/Ctrl+C volta ao menu.
- **3 — Diagnóstico e painel de som:** salva relatório e abre `mmsys.cpl`. Você escolhe headset ou caixa de som manualmente no Windows.
- **4 — Idioma:** dez traduções incorporadas, português com acentos e cedilha; preferência salva no perfil.
- **R — Restaurar configurações:** **W** restaura o serviço Waves; **E** restaura os ajustes antigos de energia/comunicações se existir a cópia. Reativar Waves pode reproduzir a falha.
- **0 ou ESC:** fecha o painel.

Swarm temporário e aplicação de ajustes USB/energia foram retirados do menu para manter o foco no contorno identificado. A restauração de ajustes antigos e a recuperação de uma sessão temporária pendente de versões anteriores foram preservadas. Você continua podendo abrir o Swarm normalmente fora do script.

## Efeito no headset e no Swarm

A opção 1 deixa os dispositivos de áudio e microfone habilitados e preserva o padrão de captura. Não encerra o Swarm nem seu monitor. Entretanto, desativar o serviço Waves pode indisponibilizar equalização, efeitos e processamento avançado dependentes desse serviço. O Swarm abrir não comprova que todos os seus efeitos estão ativos.

O usuário observou funcionamento do headset e do Swarm durante o contorno. Volume audível, qualidade do microfone, LEDs e cada controle do Swarm exigem confirmação no equipamento; a verificação do script mede estados e padrões do Windows. Para reativar o serviço, use R → W; isso pode trazer o ciclo de volta.

## Dados e restauração

Os dados ficam em `%LOCALAPPDATA%\RoccatSynProManager`, com fallback para a pasta do script:

- `config.json`: preferência de idioma.
- `waves-service-backup.json`: estado original do serviço, usado por R → W. Reaplicar não sobrescreve esse original.
- `swarm-session.json`: estado temporário pendente de versões anteriores; removido após a restauração confirmada do serviço e driver. A restauração da saída também é tentada e uma falha é informada separadamente.
- `system-backup.json`: cópia dos ajustes de energia/comunicações.
- `diagnostics`: relatórios e registros de observação.

Não apague cópias necessárias para desfazer alterações. O JSON separado de traduções não é necessário na pasta portátil. Esses arquivos de dados têm outra finalidade e são criados durante o uso. Relatórios podem conter nome do computador, IDs e eventos locais; revise antes de compartilhar.

## Base técnica e manutenção

O Windows distingue [mudança de padrão](https://learn.microsoft.com/en-us/windows/win32/api/mmdeviceapi/nf-mmdeviceapi-immnotificationclient-ondefaultdevicechanged) e [mudança de estado do endpoint](https://learn.microsoft.com/en-us/windows/win32/api/mmdeviceapi/nf-mmdeviceapi-immnotificationclient-ondevicestatechanged). O evento 65 isolado não identifica o processo responsável. Os padrões são consultados por [direção e papel](https://learn.microsoft.com/en-us/windows/win32/api/mmdeviceapi/nf-mmdeviceapi-immdeviceenumerator-getdefaultaudioendpoint). A restauração de sessões antigas pode usar um setter de reprodução com `IPolicyConfig`, interface sem documentação pública; em falhas, o painel oferece seleção manual no painel de som. Preferências de saída individuais dos aplicativos não são sobrescritas.

No repositório, `i18n.json` é a fonte editável das traduções. `tools/New-PortablePackage.ps1` incorpora esse conteúdo ao script e gera um PS1 UTF-8 com BOM, compatível com Windows PowerShell 5.1. O ZIP contém **somente PS1 e VBS**, sem documentação, BAT ou JSON separado. É um pacote portátil, não um instalador. Os guias [AGENTS-PT-BR.md](AGENTS-PT-BR.md) e [AGENTS-EN.md](AGENTS-EN.md) descrevem manutenção e limites.

## Créditos

Desenvolvido com **Antigravity e Codex**. Licença [MIT](LICENSE).
