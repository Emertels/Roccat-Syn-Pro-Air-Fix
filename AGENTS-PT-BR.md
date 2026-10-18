# Guia técnico de manutenção e agentes

Aplica-se ao painel, traduções, lançador e empacotamento deste repositório. Mantenha as instruções de uso alinhadas à implementação.

## Evidência e limites

- Em 18/10/2026, observações controladas associaram o ciclo ao `WavesTBSvc` (Waves Audio Services) no computador investigado: parar o serviço interrompeu o ciclo e iniciá-lo reproduziu a falha. Encerrar apenas auxiliares da interface não resolveu.
- Após desativar/parar o serviço, o núcleo do script observou 60 segundos sem trocas de padrão, amostras fora da saída escolhida ou eventos de estado do SYN Pro Air, preservando os padrões de captura. Isso não garante correção permanente, áudio audível ou LEDs. A persistência após reiniciar ainda não foi confirmada.
- O evento 65 isolado não identifica o processo iniciador. Presença do dongle não comprova headset ligado nem áudio funcional. Não atribua a mesma causa a todos os casos nem afirme que binários do fabricante foram corrigidos.

## Contrato da implementação

1. Opção 1 começa diretamente ao digitar 1 e Enter. Salva a cópia original uma vez e desativa/para somente `WavesTBSvc`. Nunca solicita dispositivo nem escreve padrões de reprodução/captura; nunca desativa endpoints ou `WavesTBVirtual`. Confere render/captura do SYN Pro Air e todos os endpoints antes ativos pela API Core Audio. Observa 30 segundos, com porcentagem inline abaixo da etapa; não usar Write-Progress. Perda de disponibilidade tenta restaurar o serviço e registra falha. Configuração aplicada e estabilidade confirmada são resultados distintos; confirmação exige observação completa, eventos disponíveis, padrões preservados e dispositivos disponíveis.
2. Monitoramento passivo registra evento 65, PnP, padrões e serviço sem alterar nenhum deles. Continua consultando sem eventos novos. ESC/Ctrl+C volta ao menu.
3. Diagnóstico salva serviço/driver/processos, padrões de captura/reprodução, PnP e eventos; abre mmsys.cpl para escolha manual de saída pelo usuário. PnP Unknown isolado não significa endpoint desativado: consultar a API de áudio.
4. Idioma grava primeiro no perfil usado pela leitura. Manter todos os textos e chaves nos dez idiomas; português com acentos e cedilha, UTF-8 com BOM.
5. R abre restauração: W restaura a cópia do serviço; E restaura energia/comunicações de versões anteriores, sem alterar Waves. Não adicionar confirmação extra à opção 1. A aplicação de novos ajustes de energia e o Swarm temporário foram retirados do menu.
6. Manter recuperação de sessões Swarm pendentes de versões antigas: validar cópia, conferir PID/caminho/horário antes de encerrar auxiliares, restaurar serviço/driver e informar falhas. Esse é um fluxo de compatibilidade; não reintroduzir ativação temporária como correção principal.

## Arquivos e pacote

- `Roccat-SynPro-Manager.ps1`: fonte Windows PowerShell 5.1, UTF-8 com BOM, exatamente um marcador `@@ROCCAT_I18N_JSON_EMBED@@`.
- `i18n.json`: traduções editáveis mantidas no repositório.
- `Roccat-SynPro-Manager.vbs`: elevação e abertura do PowerShell nativo sem CMD; BAT legado fora do ZIP.
- `tools/New-PortablePackage.ps1`: incorpora traduções e confere ZIP com exatamente PS1 e VBS. Não distribuir o PS1 fonte sem compilar como portátil autossuficiente.
- `README.md` e `README-PT-BR.md` devem coincidir; manter guias em inglês e changelogs alinhados. Créditos: Antigravity e Codex.

Dados em `%LOCALAPPDATA%\RoccatSynProManager`, com fallback para a pasta do script: `config.json`, `waves-service-backup.json`, `swarm-session.json`, `system-backup.json` e diagnósticos. Remover JSON de tradução da pasta portátil não autoriza apagar cópias de restauração.

## Segurança e compatibilidade

- Preservar os padrões atuais de reprodução e captura; não solicitar seleção de dispositivo no fluxo principal. O setter usa IPolicyConfig sem documentação pública; tratar falhas e oferecer mmsys.cpl. Não selecionar o headset pelo nome nem sobrescrever preferências individuais de aplicativos.
- A desativação fica na configuração do Windows; não instalar tarefa agendada nem guardião em segundo plano. Reparos/atualizações do fabricante podem reativar o serviço. Desligar Waves pode afetar EQ/efeitos mesmo com Swarm aberto. Explicar limites sem garantir LEDs ou qualidade do microfone.
- Usar nomes exatos e cópias validadas, conferir resultados e informar falhas parciais. Não remover drivers nem modificar outros serviços/dispositivos de áudio.
- Não aplicar mudanças reais de serviço/driver apenas para conferir um pacote. Respeitar a autorização da tarefa e instruções posteriores para deixar a máquina sem novas alterações.
