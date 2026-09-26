# 🎧 ROCCAT Syn Pro Air — Gerenciador Mestre de Áudio & Correção Definitiva
### Suíte Definitiva de Estabilização, Controle de Áudio & Correção de Ciclagens (Windows 10 & 11)

<div align="center">

**🌐 Idiomas / Languages:**  
[![Português Brasil](https://img.shields.io/badge/Idioma-Portugu%C3%AAs%20(Brasil)-green?style=for-the-badge)](README-PT-BR.md)
[![English](https://img.shields.io/badge/Language-English-blue?style=for-the-badge)](README-EN.md)

<br/>

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=flat-square)](LICENSE)
[![Plataforma: Windows 10 / 11](https://img.shields.io/badge/Plataforma-Windows%2010%20%2F%2011-0078D6.svg?style=flat-square&logo=windows&logoColor=white)](https://microsoft.com)
[![Idiomas: 10 Auto-Detectados](https://img.shields.io/badge/Idiomas-10%20Auto--Detectados-2ea44f.svg?style=flat-square)](#-6-suporte-multilíngue-10-idiomas-nativos)
[![Discord Oficial](https://img.shields.io/badge/Discord-Emertels%20Server-5865F2?style=flat-square&logo=discord&logoColor=white)](https://discord.gg/cnTxQhWWQp)
[![Telegram Mods](https://img.shields.io/badge/Telegram-Aplicativos%20Mods-26A5E4?style=flat-square&logo=telegram&logoColor=white)](https://t.me/apksmodsandroid)
[![Apoie no Ko-fi](https://img.shields.io/badge/Ko--fi-Apoiar%20Projetos-FF5E5B?style=flat-square&logo=kofi&logoColor=white)](https://ko-fi.com/emertels)
[![IA Pair: Google DeepMind Antigravity](https://img.shields.io/badge/IA%20Pair-Antigravity%20(Google%20DeepMind)-orange.svg?style=flat-square)](#)

<br/>
<br/>

<img src="assets/roccat-syn-pro-air-manager.png" alt="ROCCAT Syn Pro Air Master Manager Painel" width="850">

*Painel Mestre Modular em execução: status da blindagem em tempo real, monitoramento dos drivers e 6 modos de estabilização.*

</div>

---

> [!NOTE]
> **English Documentation:** For the complete English documentation, please visit [README-EN.md](README-EN.md).

---

## 📌 1. Apresentação & Aviso de Responsabilidade (Disclaimer)

Este projeto nasceu de uma necessidade real de engenharia: solucionar de forma definitiva o bug crônico de desconexão, queda de áudio e alternância para caixas de som secundárias no headset sem fio **ROCCAT Syn Pro Air**. Esse problema persistiu durante mais de 3 anos, ocorrendo em mais de 5 a 7 ocasiões diferentes, inclusive logo após formatar o Windows do zero.

> [!WARNING]
> **Aviso de Isenção (Disclaimer):**  
> Este script **não tem garantia absoluta de 100% de funcionamento para todas as placas-mãe e configurações de hardware do mundo**, pois cada computador possui barramentos USB, chipsets e versões de drivers diferentes. **Porém, comigo (o autor) ele solucionou definitiva e comprovadamente o problema após anos de frustração.** Use por sua conta e risco.

> [!IMPORTANT]
> **Autoria & Créditos:**  
> Desenvolvido por **Emerson Teles** em colaboração técnica com o agente de IA **Antigravity (Google DeepMind)**.

---

## 🛑 2. O Problema Crônico: O que acontece?

Quem possui o **ROCCAT Syn Pro Air** (e modelos semelhantes como Elo 7.1 Air ou Syn Max Air) costuma enfrentar o seguinte ciclo no Windows:

1. O headset conecta normalmente e reproduz áudio.
2. Após alguns segundos ou minutos (~10 a 30s), o som é subitamente interrompido.
3. O Windows redireciona o áudio automaticamente para as caixas de som secundárias (ex: caixas Creative 2.1, áudio da placa de vídeo ou monitor).
4. Em seguida, o headset reaparece e o som tenta voltar, criando um **loop infinito de vai-e-volta**.
5. Ao abrir o software **ROCCAT Swarm**, surge a notificação:
   > *"Detetámos que o microfone e os altifalantes de SYN PRO AIR estão desativados. Para poderes usar todos os recursos dos auscultadores na SWARM, ativa os altifalantes e o microfone através do painel de controlo de som do Windows."*
6. **O mistério do tempo:** Quando o computador é formatado do zero, o headset funciona bem no início, mas **depois de semanas de uso, acúmulo de cache e atualizações cumulativas do Windows, o bug sempre retorna.**

---

## 🔬 3. O Porquê Técnico: Por que isso acontece?

### A. O Abandono Corporativo (ROCCAT x Turtle Beach)
* A tradicional marca alemã de periféricos **ROCCAT** foi adquirida pela norte-americana **Turtle Beach**, que posteriormente decidiu **aposentar o nome ROCCAT**.
* A Turtle Beach lançou sua nova suíte de controle, o **Swarm II**, mas **NÃO incluiu suporte para o Syn Pro Air**.
* O headset ficou abandonado na versão legada **ROCCAT Swarm 1**, com firmware congelado (v1.09) e um driver de áudio da Turtle Beach (`WavesTBVirtual.sys`) que não recebe atualizações desde 2021/2022.

### B. O Conflito de Endpoints e o Loop de Polling
* Para habilitar recursos de software (Waves 3D Audio, Equalizador de 10 bandas e monitoramento de microfone), o Swarm exige a instalação do **Turtle Beach Audio Driver**.
* Esse pacote instala o driver de kernel `WavesTBVirtual.sys` (`ROOT\MEDIA\0000`), criando o endpoint virtual `Headset Chat (Turtle Beach)`.
* Conforme o Windows Update instala atualizações no subsistema de áudio (`audiosrv.dll`, `AudioEndpointBuilder`), o driver legado da Turtle Beach perde o sincronismo de buffers.
* O driver desativa o endpoint de áudio para tentar se recuperar. O Windows, ao ver o fone sumir, joga o som para a Creative 2.1. O Swarm detecta o sumiço e tenta religar, gerando a rajada de eventos `MMDevAPI` (Event ID 65) a cada ~10 a 30 segundos.

### C. A Armadilha da Suspensão Seletiva USB
* O Windows vem de fábrica com a **Suspensão Seletiva USB ATIVADA** (`0x00000001`).
* Durante momentos de silêncio (pausa em vídeos, telas de carregamento), o Windows corta a energia do receptor USB de 2.4GHz para poupar eletricidade, quebrando o handshake do driver da Turtle Beach.

### D. Sobrecarga de Endpoints no Controlador USB (Intel vs. ASMedia)
* Quando o dongle USB é conectado em portas USB controladas por chips secundários (como **ASMedia** ou portas frontais com hubs integrados), os controles (DualSense, Xbox, teclado, mouse) esgotam os *recursos isócronos de largura de banda* do controlador, disparando o aviso do Windows:
  > *"Recursos de controlador USB excedidos — O controlador não tem recursos suficientes disponíveis para este dispositivo."*

---

## 💡 4. Todos os Macetes Descobertos (Manual de Boas Práticas)

| # | Macete | Explicação Prática |
| :-: | :--- | :--- |
| **1** | **Conectar no Controlador Nativo Intel/AMD** | Conecte o dongle USB diretamente nas portas USB traseiras soldadas na placa-mãe que pertencem ao chipset principal (Intel ou AMD). Evite portas frontais do gabinete ou hubs com muitos periféricos juntos. |
| **2** | **Desativar a Suspensão Seletiva USB** | O comando `powercfg` deve forçar o valor para `0x00000000` em todos os planos de energia (AC e Bateria). |
| **3** | **Desativar Gerenciamento de Energia nos Hubs** | No Gerenciador de Dispositivos (`devmgmt.msc`) > Controladores USB > desmarcar *"Permitir que o computador desligue este dispositivo para economizar energia"* em todos os Root Hubs USB. |
| **4** | **Configurar Ducking para 'Não Fazer Nada'** | No painel de som (`mmsys.cpl`) > aba Comunicações > selecionar *"Não fazer nada"*. Isso impede que o Windows reduza o volume ou desvie o som ao detectar comunicação de voz. |
| **5** | **Desmarcar Modo Exclusivo** | Nas propriedades do Headset > aba Avançado > desmarcar *"Permitir que aplicativos assumam controle exclusivo deste dispositivo"*. |
| **6** | **O Macete do Auto-Piloto Swarm** | No dia a dia, mantenha o driver de kernel da Turtle Beach desabilitado (`Start = 4`). O headset funcionará 100% estável no driver nativo da Microsoft com controle de LEDs no Swarm. Quando quiser regular o equalizador ou microfone, use a Opção 2 para abrir o Swarm e ele desligará o driver sozinho ao fechar! |

---

## 🛠️ 5. Manual Passo a Passo das Opções do Script

O script detecta o idioma do Windows automaticamente entre 10 idiomas e exibe um **Badge de Status em tempo real**:
* `[ ✓ POSITIVO: SISTEMA TOTALMENTE BLINDADO & FIX APLICADO ]`: Indica que as portas USB, a energia e o registro já estão protegidos contra o bug.
* `[ ✗ PENDENTE: FIX NÃO APLICADO OU INCOMPLETO ]`: Indica que a Opção 4 ainda precisa ser executada.

### Descrição Detalhada de Cada Opção:

* **`[1] Modo Estável Definitivo (Uso Diário / Zero Falhas)`**:
  * **O que faz:** Encerra os processos Waves e desativa o driver `WavesTBVirtual` no kernel do Windows (`Start = 4`).
  * **Resultado:** O headset passa a operar no driver nativo de alta estabilidade da Microsoft (`usbaudio.sys`). O áudio **nunca mais cai para a Creative 2.1**, e os LEDs/AIMO continuam funcionando normalmente no Swarm!
  * **Quando usar:** Ideal para jogar, assistir vídeos e usar o PC sem se preocupar com bugs.

* **`[2] Modo Swarm Auto-Piloto (Configurar EQ e Microfone)`**:
  * **O que faz:** Habilita temporariamente o driver da Turtle Beach (`Start = 3`), inicia o serviço e abre o ROCCAT Swarm.
  * **A mágica:** O script fica vigiando em segundo plano. **Assim que você terminar suas regulagens e fechar a janela do Swarm, o script desliga o driver automaticamente!**
  * **Quando usar:** Sempre que você quiser alterar o equalizador, graves, agudos ou sensibilidade do microfone no Swarm sem deixar o bug rodando solto no sistema.

* **`[3] Modo Sincronizado / Sentinela Ativa (Turtle Beach + Swarm Ativos)`**:
  * **O que faz:** Mantém o driver da Turtle Beach rodando e ativa um vigia em C# nativo (`CoreAudio`) que monitora o endpoint a cada 500ms.
  * **Resultado:** Se o Windows ou o driver tentar desviar o som para a Creative 2.1, a sentinela intercepta a queda e restaura o Headset instantaneamente.
  * **Quando usar:** Deixe esta janela aberta enquanto joga caso queira utilizar os efeitos proprietários Waves 3D Audio ativos em tempo real.

* **`[4] Otimização Mestra do Windows (USB, Ducking e Energia)`**:
  * **O que faz:** Varre todos os planos de energia do Windows desativando a Suspensão Seletiva USB, remove o modo de economia dos hubs USB da placa-mãe e trava a atenuação de comunicação em "Não Fazer Nada".
  * **Quando usar:** Execute agora no seu Windows atual e sempre que formatar o computador no futuro.

* **`[5] Abrir Painel de Som do Windows (mmsys.cpl)`**:
  * **O que faz:** Abre a interface clássica do painel de som do Windows para conferência dos dispositivos de Reprodução e Gravação.

* **`[6] Alterar Idioma / Change Language`**:
  * **O que faz:** Permite trocar manualmente o idioma do painel entre os 10 idiomas disponíveis (as preferências são salvas em `config.json`).

---

## 🌐 6. Suporte Multilíngue (10 Idiomas Nativos)

O script auto-reconhece o idioma do sistema operacional do usuário entre 10 opções:

1. 🇧🇷 **Português (Brasil)** — `pt-BR`
2. 🇺🇸 **English (US)** — `en-US`
3. 🇪🇸 **Español** — `es-ES`
4. 🇫🇷 **Français** — `fr-FR`
5. 🇩🇪 **Deutsch** — `de-DE`
6. 🇮🇹 **Italiano** — `it-IT`
7. 🇷🇺 **Русский** — `ru-RU`
8. 🇯🇵 **日本語** — `ja-JP`
9. 🇨🇳 **简体中文** — `zh-CN`
10. 🇰🇷 **한국어** — `ko-KR`

---

## 💻 7. Como Executar

* **Método 1 (Dois Cliques no Prompt de Comando):**
  1. Dê dois cliques em **`Roccat-SynPro-Manager.bat`**.
  2. Confirme a solicitação de Administrador (UAC).
  3. O menu interativo se abrirá diretamente no terminal.

* **Método 2 (PowerShell):**
  1. Clique com o botão direito em **`Roccat-SynPro-Manager.ps1`**.
  2. Selecione **"Executar com o PowerShell"**.
  3. O script solicitará permissão de Administrador e permanecerá aberto sem fechar sozinho.

---

## 🛡️ 8. Segurança e Integridade
* **Sem arquivos destrutivos:** Nenhum driver oficial do Windows é deletado ou corrompido.
* **100% Transparente & Auditável:** Código limpo e aberto em PowerShell e C# puro.
* **Totalmente Reversível:** Todas as operações podem ser ligadas, desligadas ou reconfiguradas a qualquer momento pelo menu.

---

## 👤 Sobre o Autor

Desenvolvido por **Emerson Teles** (mais conhecido na comunidade como **Emertels**).

Apaixonado por tecnologia, informática, hardware, jogos, manutenção avançada de sistemas e tradução/localização de softwares, sistemas e emuladores para o Português do Brasil (PT-BR).

### 🛠️ Projetos & Contribuições Notáveis:
- **Softwares & Utilitários:** Tradução 100% de **DSX** (DualSense X — Trusted Translator), **ASUS GPU Tweak III**, **dnGrep**, **XWidget**, **Microsoft Photos Fix**, **AI-Chat-Vault**, e utilitários web (**DualSense Tester**, **DualShock Tools**).
- **Emulação & Consoles:** Criador da suíte de tradução multilíngue **PSBBN-Translator** (PlayStation Broadband Navigator do PS2), localização de emuladores como **PCSX2**, **Dolphin**, **shadPS4**, **Azahar** e **RetroArch**.
- **Jogos:** Tradução de **Silent Hill 5: Homecoming**, projetos em andamento em **Silent Hill 4: The Room** e diversos outros.

---

### 🌐 Conecte-se comigo & Comunidades Oficiais:

<div align="left">

[![Discord](https://img.shields.io/badge/Discord-Emertels%20Server-5865F2?style=for-the-badge&logo=discord&logoColor=white)](https://discord.gg/cnTxQhWWQp)
[![Telegram](https://img.shields.io/badge/Telegram-Aplicativos%20Mods-26A5E4?style=for-the-badge&logo=telegram&logoColor=white)](https://t.me/apksmodsandroid)
[![GitHub](https://img.shields.io/badge/GitHub-Emertels-181717?style=for-the-badge&logo=github&logoColor=white)](https://github.com/emertels)
[![YouTube](https://img.shields.io/badge/YouTube-Emerson_Teles-FF0000?style=for-the-badge&logo=youtube&logoColor=white)](https://www.youtube.com/@emersonteles2379)
[![X / Twitter](https://img.shields.io/badge/X-@emertels-000000?style=for-the-badge&logo=x&logoColor=white)](https://x.com/emertels)
[![Ko-fi](https://img.shields.io/badge/Ko--fi-Apoiar%20Projetos-FF5E5B?style=for-the-badge&logo=kofi&logoColor=white)](https://ko-fi.com/emertels)

</div>
