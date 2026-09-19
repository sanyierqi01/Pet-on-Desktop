Option Explicit

Dim shell, fileSystem, root, command
Set shell = CreateObject("WScript.Shell")
Set fileSystem = CreateObject("Scripting.FileSystemObject")

root = fileSystem.GetParentFolderName(WScript.ScriptFullName)
command = "pwsh.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -STA -File """ _
    & root & "\desktop-pet.ps1"""

shell.CurrentDirectory = root
shell.Run command, 0, False
