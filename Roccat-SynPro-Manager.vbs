Option Explicit

Dim fso, shell, environmentShell, processEnvironment, folder, windowsFolder, scriptPath, powershellPath, arguments
Set fso = CreateObject("Scripting.FileSystemObject")
Set shell = CreateObject("Shell.Application")
Set environmentShell = CreateObject("WScript.Shell")
Set processEnvironment = environmentShell.Environment("PROCESS")

folder = fso.GetParentFolderName(WScript.ScriptFullName)
scriptPath = fso.BuildPath(folder, "Roccat-SynPro-Manager.ps1")
windowsFolder = fso.GetSpecialFolder(0)

' Se o WScript for 32 bits em um Windows 64 bits, Sysnative acessa o PowerShell nativo.
If Len(processEnvironment("PROCESSOR_ARCHITEW6432")) > 0 Then
    powershellPath = fso.BuildPath(windowsFolder, "Sysnative\WindowsPowerShell\v1.0\powershell.exe")
Else
    powershellPath = fso.BuildPath(windowsFolder, "System32\WindowsPowerShell\v1.0\powershell.exe")
End If
If Not fso.FileExists(powershellPath) Then
    powershellPath = fso.BuildPath(windowsFolder, "System32\WindowsPowerShell\v1.0\powershell.exe")
End If

If Not fso.FileExists(scriptPath) Then
    MsgBox "O arquivo Roccat-SynPro-Manager.ps1 nao foi encontrado ao lado do lancador." & vbCrLf & _
           "Mantenha os dois arquivos na mesma pasta.", vbCritical, "ROCCAT Syn Pro Air"
    WScript.Quit 1
End If

If Not fso.FileExists(powershellPath) Then
    MsgBox "O Windows PowerShell nao foi encontrado em:" & vbCrLf & powershellPath, vbCritical, "ROCCAT Syn Pro Air"
    WScript.Quit 1
End If

arguments = "-NoProfile -ExecutionPolicy Bypass -File " & Chr(34) & scriptPath & Chr(34)
On Error Resume Next
shell.ShellExecute powershellPath, arguments, folder, "runas", 1
If Err.Number <> 0 Then
    MsgBox "Nao foi possivel iniciar o painel: " & Err.Description, vbCritical, "ROCCAT Syn Pro Air"
    WScript.Quit 1
End If
