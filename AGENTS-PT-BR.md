# Guia técnico de manutenção e agentes

Aplica-se ao painel, traduções, lançador e empacotamento deste repositório. Mantenha as instruções de uso alinhadas à implementação.

## Evidência e limites

- Em 18/10/2026, observações controladas associaram o ciclo ao `WavesTBSvc` (Waves Audio Services) no computador investigado: parar o serviço interrompeu o ciclo e iniciá-lo reproduziu a falha. Encerrar apenas auxiliares da interface não resolveu.
- Após desativar/parar o serviço, o núcleo do script observou 60 segundos sem trocas de padrão, amostras fora da saída escolhida ou eventos de estado do SYN Pro Air, preservando os padrões de captura. Isso não garante correção permanente, áudio audível ou LEDs. A persistência após reiniciar ainda não foi confirmada.
- O evento 65 isolado não identifica o processo iniciador. Presença do dongle não comprova headset ligado nem áudio funcional. Não atribua a mesma causa a todos os casos nem afirme que binários do fabricante foram corrigidos.

## Contrato da implementação

1. Opção 1 lê o serviço exato `WavesTBSvc`, salva a cópia original uma única vez, desativa/para o serviço, aplica uma saída ativa escolhida explicitamente aos três papéis de reprodução e observa 30 segundos sem reaplicar o padrão. Estabilidade confirmada exige serviço conferido, observação completa, eventos disponíveis, zero trocas/amostras fora da saída/eventos de estado, captura preservada e padrões finais corretos. Configuração aplicada e estabilidade confirmada são resultados distintos. Falhas antes de concluir a aplicação tentam restaurar serviço e reprodução. R restaura o serviço original; P abre a proteção opcional de sessão. Não desativar `WavesTBVirtual` na opção 1.
2. Opção 2 salva a sessão de serviço/driver/reprodução antes de alterar, habilita Waves e abre Swarm. Acompanha `ROCCAT_Swarm.exe`, ignorando o monitor residente. O bloco finally restaura o estado ao encerrar ou usar ESC/Ctrl+C. Encerrar somente auxiliares criados pela própria sessão, conferindo PID, caminho e horário de início. Recuperar sessão interrompida na próxima abertura e manter a cópia se a restauração do serviço/driver falhar. Informar também falha de restauração da saída. O ciclo pode voltar enquanto Waves estiver temporariamente ativo.
3. Monitoramento passivo registra evento 65, PnP, padrões de reprodução e serviço sem alterá-los. Continuar consultando quando não houver eventos. ESC/Ctrl+C volta ao menu.
4. Energia/comunicações têm cópia e verificação próprias. Sua restauração não pode alterar driver/serviço Waves. Não exigir leitura do driver para ajustar energia.
5. Diagnóstico inclui configuração do serviço, driver, processos relevantes, padrões de captura/reprodução, PnP/pais/códigos e eventos. Relatórios não atribuem causa automaticamente.
6. A gravação do idioma prioriza o mesmo arquivo do perfil usado na leitura. Atualizar os dez idiomas em toda nova chave de interface.

## Arquivos e pacote

- `Roccat-SynPro-Manager.ps1`: fonte Windows PowerShell 5.1, UTF-8 com BOM, exatamente um marcador `@@ROCCAT_I18N_JSON_EMBED@@`.
- `i18n.json`: traduções editáveis mantidas no repositório.
- `Roccat-SynPro-Manager.vbs`: elevação e abertura do PowerShell nativo sem CMD; BAT legado fora do ZIP.
- `tools/New-PortablePackage.ps1`: incorpora traduções e confere ZIP com exatamente PS1 e VBS. Não distribuir o PS1 fonte sem compilar como portátil autossuficiente.
- `README.md` e `README-PT-BR.md` devem coincidir; manter guias em inglês e changelogs alinhados. Créditos: Antigravity e Codex.

Dados em `%LOCALAPPDATA%\RoccatSynProManager`, com fallback para a pasta do script: `config.json`, `waves-service-backup.json`, `swarm-session.json`, `system-backup.json` e diagnósticos. Remover JSON de tradução da pasta portátil não autoriza apagar cópias de restauração.

## Segurança e compatibilidade

- Preservar a escolha explícita de reprodução e os padrões de captura. O setter usa IPolicyConfig sem documentação pública; tratar falhas e oferecer mmsys.cpl. Não selecionar o headset pelo nome nem sobrescrever preferências individuais de aplicativos.
- A desativação fica na configuração do Windows; não instalar tarefa agendada nem guardião em segundo plano. Reparos/atualizações do fabricante podem reativar o serviço. Desligar Waves pode afetar EQ/efeitos mesmo com Swarm aberto. Explicar limites sem garantir LEDs ou qualidade do microfone.
- Usar nomes exatos e cópias validadas, conferir resultados e informar falhas parciais. Não remover drivers nem modificar outros serviços/dispositivos de áudio.
- Não aplicar mudanças reais de serviço/driver apenas para conferir um pacote. Respeitar a autorização da tarefa e instruções posteriores para deixar a máquina sem novas alterações.
