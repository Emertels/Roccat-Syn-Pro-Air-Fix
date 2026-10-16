# Changelog — ROCCAT Syn Pro Air

Histórico das mudanças do painel e do pacote portátil.

## [1.2.0] — 2026-10-16

### Corrigido

- A sentinela passou a ser **passiva**: registra eventos de áudio e estados PnP sem trocar a saída padrão, selecionar o headset ou alterar o driver.
- O monitor continua consultando o log quando ainda não há eventos novos; ESC e Ctrl+C encerram o monitor e retornam ao menu.
- A restauração do driver no fluxo temporário do Swarm agora parte do estado anterior capturado e verifica o resultado.
- A opção 1 exige que os dados necessários para restauração estejam disponíveis antes de parar/desativar o driver Waves.
- A opção de energia confere as mudanças que o Windows permite consultar e informa quando o ajuste de Root Hubs não pôde ser confirmado.
- O lançador VBS chama o PowerShell elevado sem abrir primeiro uma janela de CMD e seleciona o caminho nativo em Windows 64 bits quando necessário.

### Melhorado

- Relatório de diagnóstico com endpoints PnP, código de problema, relação pai do endpoint, serviço Waves e eventos recentes de áudio e USB.
- Estado da interface descreve o que foi observado e evita tratar presença PnP como prova de áudio funcional.
- Preferência de idioma e dados de diagnóstico ficam no perfil local do usuário, com fallback para a pasta portátil.
- Dez idiomas incorporados ao PS1 distribuído. O pacote ZIP contém somente o script PowerShell e o lançador VBS.
- README e guias técnicos revisados para separar evidência de hipótese e explicar efeitos e restauração.

### Limites conhecidos

- Não foi possível validar esta versão no headset/dongle do usuário durante a falha. A causa do desaparecimento/reaparecimento dos endpoints continua não confirmada.
- A versão melhora o diagnóstico e a segurança das ações, mas não é uma promessa de correção definitiva. Desativar `WavesTBVirtual` pode retirar recursos de áudio do Swarm.

### Créditos

- Desenvolvido com Antigravity e Codex.

## [1.0.0] — 2026-09-26

- Primeira versão pública do painel PowerShell com opções de driver, monitoramento, ajustes de energia, painel de som e interface multilíngue.
- O texto de apresentação original fazia promessas de estabilidade que não estavam demonstradas por telemetria; a documentação da versão 1.2.0 corrige esse enquadramento.
