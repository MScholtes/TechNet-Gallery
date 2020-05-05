# Admin-Explorer.ps1
# Markus Scholtes, 2016



function Select-FileDialog([STRING]$Directory, [STRING]$Title, [STRING]$Filter = "Alle Dateien |*.*", [SWITCH] $SaveDialog, [SWITCH] $CheckFileExists)
{
<#
.SYNOPSIS
Starts grafical dialogue to select a filename
.DESCRIPTION
Starts grafical dialogue to select a filename. You can choose a "Open File" or "Save As" dialogue.
.PARAMETER Directory
Startdircectory of the dialogue
.PARAMETER Title
Window title
.PARAMETER Filter
Filter for the files you can select
.PARAMETER SaveDialog
Display a "Save As" dialogue
.PARAMETER CheckFileExists
In a "File Open" dialogue the selected file has to exist, in a  "Save As" dialogue the file is not allowed to exist
.INPUTS
None
.OUTPUTS
None
.NOTES
Name: Select-FileDialog
Author: Created by Hugo Peeters, modified by Uwe Ziegenhagen for SAVE, optimized by Markus Scholtes
Creation date: 03/24/2016
.LINK
http://www.peetersonline.nl/2008/10/powershell-open-file-dialog-box/
http://uweziegenhagen.de/?p=377
.EXAMPLE
$file = Select-FileDialog -Title "Choose a file" -Directory "C:\" -Filter "All files |*.*" -SaveDialog
Starts "Save As" dialogue in the directory C:\ and let you select all files
.EXAMPLE
$file = Select-FileDialog -Title "Select a file" -Directory "D:\scripts" -Filter "Powershell Scripts|*.ps1"
Starts "Open File" dialogue in the directory D:\scripts and let you select all powershell files
#>
	[System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null
	if (!$SaveDialog)
	{
		$objForm = New-Object System.Windows.Forms.OpenFileDialog
		if (!$CheckFileExists)
		{
			$objForm.CheckFileExists = $FALSE
		}
	}
	else
	{
		$objForm = New-Object System.Windows.Forms.SaveFileDialog
		if (!$CheckFileExists)
		{
			$objForm.OverwritePrompt = $FALSE
		}
	}
	$objForm.InitialDirectory = $Directory
	$objForm.Filter = $Filter
	$objForm.Title = $Title
	if ([System.Threading.Thread]::CurrentThread.GetApartmentState() -eq "MTA")
	{	# dailog hangs in MTA mode, when ShowHelp is not set to $TRUE
		$objForm.ShowHelp = $TRUE
	}
	$Show = $objForm.ShowDialog()
	if ($Show -eq "OK")
	{
  	return $objForm.FileName
	}
	else
	{
  	return ""
  }
}


<#
.Synopsis
Checks whether the current Powershell runs in administrative mode.
.Description
Returns $TRUE when the current Powershell has administrative privilegs, otherwise returns $FALSE.
.Inputs
None
.Outputs
System.Boolean
.Notes
Author: Markus Scholtes
Creation date: 03/24/2016
.Example
Test-Admin

Checks whether the current Powershell runs in administrative mode.
#>
function Test-Admin
{
 $IDENTITY = [Security.Principal.WindowsIdentity]::GetCurrent()
 $PRINCIPAL = New-Object Security.Principal.WindowsPrincipal $IDENTITY
 $PRINCIPAL.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}


<#
.Synopsis
Starts a program with administrative privileges
.Description
Starts a program with administrative privileges and calls UAC if required for credentials or acceptance
.Parameter Command
Program to run administrative
.Parameter Arguments
List of arguments for the administrative program
.Inputs
None
.Outputs
None
.Notes
Author: Markus Scholtes
Creation date: 03/24/2016
.Example
Start-Elevated "cmd.exe" "/c pause"

Starts a command prompt with the command "pause"
.Example
Start-Elevated "cmd.exe" "/c","pause"

Starts a command prompt with the command "pause"
.Example
Start-Elevated "cmd.exe" @("/c","pause")

Starts a command prompt with the command "pause"
#>
function Start-Elevated([STRING] $Command = "cmd.exe", [STRING[]]$Arguments = $NULL)
{
	if ($Arguments)
	{	Start-Process -FilePath $Command -ArgumentList $Arguments -Verb Runas }
	else
	{	Start-Process -FilePath $Command -Verb Runas }
}


<#
.Synopsis
Starts a new powershell with administrative privileges
.Description
Starts a new powershell with administrative privileges and calls UAC if required for credentials or acceptance
.Parameter Arguments
List of arguments for the administrative powershell. When "-exit" is not part of the list, the powershell 
will not end by itself.
If more then one command is issued in the argument list, they have to be ended with ;
.Inputs
None
.Outputs
None
.Notes
Author: Markus Scholtes
Creation date: 03/24/2016
.Example
Start-ElevatedPowerShell

Starts an administrative powershell
.Example
Start-ElevatedPowerShell "-noprofile","ls"

Starts an administrative powershell without profile and call the command ls
.Example
Start-ElevatedPowerShell "cd 'C:\Program Files';","ls","-exit"

Starts an administrative powershell without profile. The current drive in the powershell will be set to
"C:\Program Files", the command ls is executed and the powershell will end.
#>
function Start-ElevatedPowerShell([STRING[]]$Arguments = $NULL)
{
	if ($Arguments)
	{
		if ($Arguments -contains "-exit")
		{
			$Arguments = $Arguments -ne "-exit"
			if ($Arguments)
			{	Start-Process -FilePath "powershell.exe" -ArgumentList $Arguments -Verb Runas }
			else
			{	Start-Process -FilePath "powershell.exe" -Verb Runas }
		}
		else
		{
			Start-Process -FilePath "powershell.exe" -ArgumentList (@("-NoExit")+$Arguments) -Verb Runas
		}
	}
	else
	{	Start-Process -FilePath "powershell.exe" -Verb Runas }
}

if (!(Get-Command -EA SilentlyContinue su)) { Set-Alias -Name su -Value Start-Elevated }
if (!(Get-Command -EA SilentlyContinue sudo)) { Set-Alias -Name sudo -Value Start-Elevated }


$SCRIPT:SCRIPTPATH = $SCRIPT:MyInvocation.MyCommand.Path

<#
.Synopsis
Starts a "file open" dialogue with administrative privileges
.Description
Starts a "file open" dialogue with administrative privileges as a substitute for the Windows Explorer
that cannot be run with administrative privileges
.Parameter Directory
Directory to show in the dialogue
.Inputs
String
.Outputs
None
.Notes
Author: Markus Scholtes
Creation date: 03/24/2016
.Example
AdminExplorer "C:\Program Files"

Starts "AdminExplorer" in the directory "C:\Program Files"
#>
function AdminExplorer([STRING] $Directory)
{
	if (Test-Admin)
	{	$NULL = Select-FileDialog -Directory "$Directory" -Title "AdminExplorer" }
	else
	{	
		Start-ElevatedPowerShell "-sta ","-exit",". $SCRIPT:SCRIPTPATH;","Select-FileDialog -Directory '$Directory' -Title 'AdminExplorer' | Out-Null" 
	}
}
