Markus Scholtes, 2019-01-11

Transpose-Object: Powershell script to transpose objects from columns to rows


Transpose-Object: Powershell script to transpose objects from columns to rows. Useful when the order displayed in a GridView (with Out-GridView)
or in a CSV file (with Export-Csv) has to be rotated.


The function Transpose-Object works on an object passed to it through the pipeline and flips propertys of the object.
It uses the name property as new property names (column headers) if it exists.

The information about the default view gets lost since new objects are created, you may have to place an limiting select statement before (see example below).



Examples (assuming Transpose-Object.ps1 is in the current directory):

Shows directory listing with a column instead of a row for every file/directory:

. .\Transpose-Object.ps1
dir | Transpose-Object | Out-GridView


Creates a CSV file with a column instead of a row for every process:

. .\Transpose-Object.ps1
ps | Transpose-Object | Export-Csv Processes.csv -Delimiter ';' -NoTypeInformation


Use and transpose only the default view properties:

. .\Transpose-Object.ps1
Get-ChildItem | Select-Object Mode, LastWriteTime, Length, Name | Transpose-Object



Version: 1.1 - workaround for Out-GridView error, select title property, fixed error detecting doubled titles
Creation Date: 11/11/2022
