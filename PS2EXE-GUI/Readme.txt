PS2EXE-GUI v0.5.0.24
Release: 2020-10-24

Overworking of the great script of Igor Karstein with GUI support by Markus Scholtes.

The GUI output and input is activated with one switch, real windows executables
are generated.

https://github.com/MScholtes/TechNet-Gallery/
https://gallery.technet.microsoft.com/scriptcenter/PS2EXE-GUI-Convert-e7cb69d5


All of you know the fabulous script PS2EXE by Ingo Karstein you can download here: PS2EXE : "Convert" PowerShell Scripts to EXE Files.

Unfortunately Ingo seems to have stopped working on his script so I overworked his script with some error fixes, improvements and output support for non-console WinForms scripts (parameter -noConsole to ps2exe.ps1).


Module based version available now on Powershell Gallery, see here (https://www.powershellgallery.com/packages/ps2exe) or install with Install-Module PS2EXE

Project page on github is here: https://github.com/MScholtes/PS2EXE.


Update v0.5.0.24 - 2020-10-24
- refactored

Full list of changes and fixes in Changes.txt.

Includes Win-PS2EXE, a small graphical front end for PS2EXE.

Not all parameters are supported, requires .Net 4.x. C# WPF application. With drag'n'drop for file names. Has to be placed in the same directory as ps2exe.ps1. Source code and .Net 3.5x version are here: https://github.com/MScholtes/Win-PS2EXE


GUI support:

- expanded every output and input function like Write-Host, Write-Output, Write-Error, Out-Default, Prompt, ReadLine to use WinForms message boxes or input boxes automatically when compiling a GUI application
- no console windows appears, real windows executables are generated
- just compile with switch "-noConsole" for this feature (i.e. .\ps2exe.ps1 .\output.ps1 -noConsole)
- see remarks below for formatting of output in GUI mode



Compile all of the examples in the Examples sub directory with

BuildExamples.bat

Every script will be compiled to a console and a GUI version (-NoConsole).


Remarks:

GUI mode output formatting:
Per default output of commands are formatted line per line (as an array of strings). When your command generates 10 lines of output and you use GUI output, 10 message boxes will appear each awaitung for an OK. To prevent this pipe your command to the comandlet Out-String. This will convert the output to a string array with 10 lines, all output will be shown in one message box (for example: dir C:\ | Out-String).

Config files:
PS2EXE create config files with the name of the generated executable + ".config". In most cases those config files are not necessary, they are a manifest that tells which .Net Framework version should be used. As you will usually use the actual .Net Framework, try running your excutable without the config file.

Parameter processing:
Compiled scripts process parameters like the original script does. One restriction comes from the Windows environment: for all executables all parameters have the type STRING, if there is no implicit conversion for your parameter type you have to convert explicitly in your script. You can even pipe content to the executable with the same restriction (all piped values have the type STRING).

A generated executable has the following reserved parameters:
-debug Forces the executable to be debugged. It calls "System.Diagnostics.Debugger.Break()".
-extract:<FILENAME> Extracts the powerShell script inside the executable and saves it as FILENAME. The script will not be executed.
-wait At the end of the script execution it writes "Hit any key to exit..." and waits for a key to be pressed.
-end All following options will be passed to the script inside the executable. All preceding options are used by the executable itself.

Password security:
Never store passwords in your compiled script! One can simply decompile the script with the parameter -extract. For example
Output.exe -extract:C:\Output.ps1
will decompile the script stored in Output.exe.

Script variables:
Since PS2EXE converts a script to an executable, script related variables are not available anymore. Especially the variable $PSScriptRoot is empty.
The variable $MyInvocation is set to other values than in a script.

You can retrieve the script/executable path independant of compiled/not compiled with the following code (thanks to JacquesFS):

if ($MyInvocation.MyCommand.CommandType -eq "ExternalScript")
{ $ScriptPath = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition }
else
{ $ScriptPath = Split-Path -Parent -Path ([Environment]::GetCommandLineArgs()[0]) }

Window in background in -noConsole mode:
When an external window is opened in a script with -noConsole mode (i.e. for Get-Credential or for a command that needs a cmd.exe shell) the next window is opened in the background.
The reason for this is that on closing the external window windows tries to activate the parent window. Since the compiled script has no window, the parent window of the compiled script is activated instead, normally the window of Explorer or Powershell.
To work around this, $Host.UI.RawUI.FlushInputBuffer() opens an invisible window that can be activated. The following call of $Host.UI.RawUI.FlushInputBuffer() closes this window (and so on).

The following example will not open a window in the background anymore as a single call of "ipconfig | Out-String" will do:
	$Host.UI.RawUI.FlushInputBuffer()
	ipconfig | Out-String
	$Host.UI.RawUI.FlushInputBuffer()
