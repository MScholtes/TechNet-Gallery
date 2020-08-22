# TechNet-Gallery
You find copies of my *'Script Center'* and *'Technet Gallery'* publications here because Technet Gallery will be closed soon.

### Version 1.0.4 / 2020/08/22
- added Export-FileSegment: Powershell functions to extract and insert binary data from and to files

For a complete list of changes see here: [Changes](Changes.md) 

##
## PS2EXE-GUI: "Convert" PowerShell Scripts to EXE Files with GUI
Overworking of the great script of Ingo Karstein with GUI support. The GUI output and input is activated with one switch, real windows executables are generated. With Powershell 5.x support and graphical front end.

#### Project page: [PS2EXE-GUI](https://github.com/MScholtes/TechNet-Gallery/tree/master/PS2EXE-GUI)

##
## Powershell Webserver
Powershell script that starts a webserver (without IIS). Powershell command execution, script execution, upload, download and other functions are implemented.

#### Project page: [Powershell Webserver](https://github.com/MScholtes/TechNet-Gallery/tree/master/Powershell%20Webserver)

##
## Powershell commands to manage virtual desktops of Windows 10
Windows 10 introduced a great new feature with virtual desktops. This set of powershell commandlets helps out and lets you control virtual desktops from scripts. Compatible to Windows 10 1607, Server 2016, 1803 up to 2004!

#### Project page: [VirtualDesktop](https://github.com/MScholtes/TechNet-Gallery/tree/master/VirtualDesktop)

##
## Powershell scripts to export and import firewall rules
Powershell scripts to export and import firewall rules in CSV or JSON format.

#### Project page: [ExportImportFirewallRules](https://github.com/MScholtes/TechNet-Gallery/tree/master/ExportImportFirewallRules)

##
## Powershell functions to split and join binary files fast
Two Powershell functions to split and join binary files fast. The functions are using .Net BinaryWriter methods. If .Net 4 or above is detected, the quick .CopyTo() method is used to join files.

#### Project page: [Split-File](https://github.com/MScholtes/TechNet-Gallery/tree/master/Split-File)

##
## Powershell functions to extract and insert binary data from and to files
Two Powershell functions to extract and insert binary data from and to files. The functions are using .Net BinaryWriter and BinaryReader methods.

#### Project page: [Export-Filesegment](https://github.com/MScholtes/TechNet-Gallery/tree/master/Export-Filesegment)

##
## Replace-InFile.ps1: Replace text in files while preserving the encoding
Replace-InFile.ps1 is a Powershell script I made to replace text in files programmatically without getting a mess with the text encodings. The script detects the encoding of each processed file and writes it back with the same encoding.

#### Project page: [Replace-InFile](https://github.com/MScholtes/TechNet-Gallery/tree/master/Replace-InFile)

##
## Inputbox for Powershell
With [System.Windows.Forms.MessageBox]::Show(...) you can display a messagebox in every powershell script, but a function to display an inputbox is missing. So I wrote this small c# class InputBox for it.

#### Project page: [Inputbox](https://github.com/MScholtes/TechNet-Gallery/tree/master/Inputbox)

##
## Transpose-Object: Powershell script to transpose objects from columns to rows
Transpose-Object: Powershell script to transpose objects from columns to rows. Useful when the order displayed in a GridView (with Out-GridView) or in a CSV file (with Export-Csv) has to be rotated.

#### Project page: [Transpose-Object](https://github.com/MScholtes/TechNet-Gallery/tree/master/Transpose-Object)

##
## Get-Sessions: Powershell script for information on interactive logins (incl RDP)
Get-Sessions: Powershell script to get information about interactive logins (including RDP sessions) including logon, connect, disconnect and logoff times.

Session ID and remote host for RDP can be requested per parameter.

#### Project page: [Get-Sessions](https://github.com/MScholtes/TechNet-Gallery/tree/master/Get-Sessions)

##
## Retrieve latest reboot time(s)
Short script to retrieve the latest reboot time(s) of a computer

#### Project page: [Get-RebootTime](https://github.com/MScholtes/TechNet-Gallery/tree/master/Get-RebootTime)

##
## Powershell script to compress log files (and IIS logs)
This script compresses log files older than the current month to Zip archives in a given directory or in the IIS log directories and deletes the archived files.

#### Project page: [Compress-LogDirectory](https://github.com/MScholtes/TechNet-Gallery/tree/master/Compress-LogDirectory)

##
## Powershell: Permissions for administrative shares (like ADMIN$) / registry ACLs
Powershell scripts to get or set permissions for administrative shares and other registry stored ACLs like permissions for the server service, for shares, for Remote Desktop connections and for the access to services or DCOM applications.

#### Project page: [AclInRegistry](https://github.com/MScholtes/TechNet-Gallery/tree/master/AclInRegistry)

##
## Convert short Powershell scripts to batches
Script to convert short powershell scripts to batches. Generated batches run on double click and ignore execution policies.

#### Project page: [ConvertTo-Batch](https://github.com/MScholtes/TechNet-Gallery/tree/master/ConvertTo-Batch)

##
## Powershell Module CredentialLocker
Module to manage the Credential Locker, also known as Password Vault, which provides a way for you to store user credentials (username, password) in a secure fashion for web pages or your app. With this module you can manage stored credentials of Internet Explorer and Edge too.

#### Project page: [CredentialLocker](https://github.com/MScholtes/TechNet-Gallery/tree/master/CredentialLocker)

##
## GetAllEvents: Query all events from all event logs
Command line tool to query all events from all event logs (about 1200 in Windows 10) and display in GridView or export to text or csv file.

#### Project page: [GetAllEvents](https://github.com/MScholtes/TechNet-Gallery/tree/master/GetAllEvents)

##
## Powershell MineSweeper
Powershell game of MineSweeper with WinForms graphics.

Based on the game of /\/\o\/\/.

#### Project page: [Powershell MineSweeper](https://github.com/MScholtes/TechNet-Gallery/tree/master/Powershell%20MineSweeper)

##
## Write-Highlight: Highlighting of multiple search patterns in different colors
Powershell script that highlights multiple search patterns in the output. You can give an array of regular expressions, every expression is marked in its own color.

#### Project page: [Write-Highlight](https://github.com/MScholtes/TechNet-Gallery/tree/master/Write-Highlight)

##
## Script to manually import RDP certificates
Script to import the registry keys and certificate thumbnails for unknown RDP connections. No RDP trust warnings will appear for the remote machine after running the script.

#### Project page: [RDP-CertHash](https://github.com/MScholtes/TechNet-Gallery/tree/master/RDP-CertHash)

##
## "File Open" Dialog As Replacement for An Adminstrative Windows Explorer
Since Windows Explorer cannot be started with administrative privileges starting with Windows 7, this script starts an administrative "File Open" dialog as a replacement.

#### Project page: [Admin-Explorer](https://github.com/MScholtes/TechNet-Gallery/tree/master/Admin-Explorer)

##
## Powershell: add line numbering, line coloring, directory size to output/pipeline
Some fun powershell scripts to add additional information to your output or objects in the pipeline.

Add-LineNumbering adds line numbering, Add-LineColoring adds alternating line colors and Add-SizeToDir adds file count and length.

#### Project page: [Add-LineNumbering](https://github.com/MScholtes/TechNet-Gallery/tree/master/Add-LineNumbering)

##
## Create or close tabs in Internet Explorer
With the COM interface and DOM you can control the browser Internet Explorer. I made a - for me - useful script to start a new Internet Explorer tab from powershell or close an existing tab.

#### Project page: [Control-IE](https://github.com/MScholtes/TechNet-Gallery/tree/master/Control-IE)

##
## Tutorial: Graphical WPF programs in C# with just one source file
Have you been already annoyed that you need Visual Studio or MSBuild to create WPF programs?

Here is a small - and not really honest - tutorial of C# WPF programs that can be compiled without Visual Studio or MSBuild.

#### Project page: [WPF Demos](https://github.com/MScholtes/TechNet-Gallery/tree/master/WPF%20Demos)
