# 🤖 AGENTS-PT-BR.md — Guia Técnico para Agentes de IA & Desenvolvedores

Este documento fornece a arquitetura técnica detalhada, parâmetros de hardware, funcionamento de drivers e heurísticas de diagnóstico para agentes autônomos de IA (Antigravity, Claude, Copilot, etc.) ou desenvolvedores que forem continuar ou auditar o projeto **ROCCAT Syn Pro Air Master Fix**.

---

## 📋 1. Contexto & Missão do Projeto

* **Objetivo:** Resolver definitivamente o bug crônico de ciclagem de áudio, desconexão e alternância para saídas secundárias no headset sem fio **ROCCAT Syn Pro Air** no Windows 10 e Windows 11.
* **Autor Original & Pesquisador:** Emerson Teles.
* **Agente de IA Parceiro:** Antigravity (Google DeepMind).
* **Cenário de Mercado:** A ROCCAT foi adquirida e aposentada pela Turtle Beach. O Syn Pro Air é um hardware legado sem suporte na nova plataforma Turtle Beach Swarm II, permanecendo dependente do ROCCAT Swarm 1 com um driver de kernel de 2021 (`WavesTBVirtual.sys`) que sofre falhas silenciosas com as atualizações cumulativas do Windows.
* **Validação Real:** Comprovado e testado pelo autor após anos de falhas em múltiplos formatos e reinstalações do Windows.

---

## 🔌 2. Identificação de Hardware & Endpoints

| Atributo | Valor Identificado |
| :--- | :--- |
| **Vendor ID (VID)** | `1E7D` (ROCCAT / Turtle Beach) |
| **Product ID (PID)** | `3A3B` (Transmissor USB Wireless do Syn Pro Air) |
| **Dispositivo USB Pai** | `USB\VID_1E7D&PID_3A3B\5018C4BF4C18` |
| **Interfaces Compostas** | `MI_00` (Controles HID), `MI_01` (USB Audio Class 1/2), `MI_05` (Iluminação e Firmware) |
| **Driver de Áudio Nativo** | `usbaudio.sys` (`wdma_usb.inf` fornecido pela Microsoft) |
| **Driver Problemático** | `WavesTBVirtual.sys` localizado em `C:\Windows\system32\drivers\WavesTBVirtual.sys` |
| **Dispositivo Virtual** | `ROOT\MEDIA\0000` (*Virtual Audio Device*) |

---

## ⚙️ 3. Mecânica da Falha & Heurística de Diagnóstico

### A Cadeia do Conflito:
1. Quando o pacote *Turtle Beach Audio Driver* está instalado, o serviço `WavesTBVirtual.sys` cria um endpoint de áudio secundário: `Headset Chat (Turtle Beach)`.
2. O serviço de áudio do Windows (`audiosrv.dll`) e o construtor de endpoints (`AudioEndpointBuilder`) sofrem dessincronização de buffers de amostragem durante o polling com o driver legado da Waves.
3. O Windows marca o endpoint principal `HEADSET (SYN Pro Air)` como `Unknown` (desativado na API `MMDevAPI`), alternando a reprodução padrão para caixas de som secundárias (ex: Creative 2.1).
4. O processo `ROCCAT_Waves_Driver.exe` percebe a queda e força a reativação do fone, gerando um **loop infinito de resets** registrado no Visualizador de Eventos:
   * **Caminho:** `Logs de Aplicativos e Serviços > Microsoft > Windows > Audio > Operational`
   * **ID do Evento:** `65` (*MMDevAPI: Estado de dispositivo de áudio foi alterado*)

### Esgotamento de Largura de Banda USB (ASMedia vs. Intel):
* Conectar o receptor em portas controladas por chips de terceiros (como ASMedia `PCI\VEN_1B21&DEV_3241`) frequentemente causa esgotamento de *endpoints periódicos isócronos* ("Recursos de controlador USB excedidos").
* **Diretriz Técnica:** O dongle deve ser conectado exclusivamente em portas USB vinculadas ao controlador nativo do chipset da placa-mãe (Intel `PCI\VEN_8086&DEV_A3AF` ou AMD equivalente).

---

## 🛠️ 4. Registro do Windows & Políticas de Energia

| Diretriz / Chave | Valor Obrigatório | Finalidade |
| :--- | :--- | :--- |
| `HKLM:\SYSTEM\CurrentControlSet\Services\WavesTBVirtual` -> `Start` | `4` (Desabilitado) ou `3` (Manual) | `4` impede o carregamento do driver no boot, travando o fone no driver nativo estável da Microsoft. |
| `powercfg` Subgrupo `2a737441-1930-4402-8d77-b2bebba308a3`, Opção `48e6b7a6-50f5-4782-a5d4-53bb8f07e226` | `0x00000000` (AC e DC) | Desativa a Suspensão Seletiva USB em todos os esquemas de energia. |
| `HKCU:\SOFTWARE\Microsoft\Multimedia\Audio` -> `UserDuckingPreference` | `3` (DWORD) | Define a política de comunicação (*Ducking*) para "Não Fazer Nada". |
| WMI `root\wmi:MSPower_DeviceEnable` | `Enable = $false` nos Root Hubs | Impede que o Windows desligue os hubs USB internos para economizar energia. |

---

## 🤖 5. Diretrizes para Futuros Agentes de IA

1. **Preservar o Driver Nativo da Microsoft (`usbaudio.sys`):**
   * Nunca tente remover ou substituir o `usbaudio.sys`. O hardware do Syn Pro Air opera com fidelidade de áudio impecável e zero quedas nesse driver nativo.
2. **Manter o Dicionário Multi-Idioma (10 Idiomas):**
   * Todas as strings de interface ficam concentradas em `i18n.json`. Ao criar novas opções no menu do `Roccat-SynPro-Manager.ps1`, reflita as novas strings em todas as 10 chaves de tradução: `pt-BR`, `en-US`, `es-ES`, `fr-FR`, `de-DE`, `it-IT`, `ru-RU`, `ja-JP`, `zh-CN`, `ko-KR`.
3. **Preservar a Injeção COM de Baixa Latência em C#:**
   * A função `AudioController::SetDefaultAudio` utiliza a interface nativa `IPolicyConfigVista` (`870C3566-265F-4D2A-8991-6101216C68FB`). Essa interface permite reatribuir o endpoint padrão em menos de 1 milissegundo, sendo crucial para o funcionamento da Opção 3 (Sentinela).
4. **Sincronização com o Desktop do Usuário:**
   * Qualquer alteração realizada na pasta `C:\Projetos\Roccat-Syn-Pro-Air-Fix` deve ser espelhada em `C:\Users\Emerson Teles\Desktop\` para manter o acesso prático do usuário intacto.
