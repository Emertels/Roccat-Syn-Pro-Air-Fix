@echo off
setlocal
if not exist "%~dp0Roccat-SynPro-Manager.vbs" (
    echo [ERRO] O arquivo Roccat-SynPro-Manager.vbs nao foi encontrado.
    echo Mantenha o VBS e o PS1 juntos na mesma pasta.
    pause
    exit /b 1
)
start "" wscript.exe "%~dp0Roccat-SynPro-Manager.vbs"
exit /b 0
