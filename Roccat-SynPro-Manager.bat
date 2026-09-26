@echo off
title ROCCAT Syn Pro Air - Master Manager Launcher
chcp 65001 >nul 2>&1
cd /d "%~dp0"

:: 1. Verifica se o script PowerShell mestre existe no mesmo diretorio
if not exist "%~dp0Roccat-SynPro-Manager.ps1" (
    echo.
    echo ==============================================================================
    echo  [ERRO] O arquivo Roccat-SynPro-Manager.ps1 nao foi encontrado!
    echo  Certifique-se de manter o .bat e o .ps1 na mesma pasta.
    echo ==============================================================================
    echo.
    pause
    exit /b 1
)

:: 2. Executa o PowerShell de forma modular, com elevacao administrativa transparente
:: O uso do array de argumentos @(...) garante suporte perfeito a caminhos com espacos
powershell -NoProfile -ExecutionPolicy Bypass -Command "$psScript = Join-Path '%~dp0' 'Roccat-SynPro-Manager.ps1'; Start-Process powershell.exe -ArgumentList @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-NoExit', '-File', $psScript) -Verb RunAs"
exit /b 0
