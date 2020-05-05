<#
.Synopsis
Adds file count and length properties to file system directory objects.
.Description
Adds file count and length properties with the total count and total size of the contained files to file
system directory objects. The output may take a long time depending on the depth of recursion.
Non file system directory objects remain unchanged.
.Parameter InputObject
Object to be expanded. Can be handed through the pipeline.
.Inputs
Object
.Outputs
Object
.Notes
Name: Add-SizeToDir
Author: Markus Scholtes
Creation date: 2018/11/27
.Example
dir | Add-SizeToDir | Format-Table

Adds number of contained files with size to directory output. Format-Table should be added since Listview
output format would be chosen otherwise because of the new properties.
#>
function Add-SizeToDir
{
	Param([Parameter(ValueFromPipeline = $TRUE)][OBJECT[]]$InputObject)

	BEGIN
	{	}

	PROCESS
	{
		# nur wenn Eingabeobjekt vorhanden
		if ($InputObject)
		{ # alle Array-Mitglieder durchlaufen (oder nur Objekt selbst, wenn kein Array)
			foreach ($InputItem in $InputObject)
			{
				if ($_ -is [System.IO.DirectoryInfo])
				{
					# PSCustomObject zum Hinzufügen der Summenspalte erstellen
					$OutputItem = New-Object PSCustomObject

					# die bestehenden Eigenschaften des Eingabeobjekts hinzufügen
					$InputItem | Get-Member -MemberType *Property | Select-Object -ExpandProperty Name | % {
						if ($_ -eq "Name")
						{
							$CALCSIZE = Get-ChildItem -Path $InputItem.FullName -ErrorAction "SilentlyContinue" -Recurse -Force | Measure-Object -ErrorAction "SilentlyContinue" -Sum Length
							# Spalte "Files" mit Anzahl der enthaltenen Dateien hinzufügen
							$OutputItem | Add-Member -MemberType NoteProperty -Name "Files" -Value ($CALCSIZE.Count)

							# Spalte "Length" mit Größe der enthaltenen Dateien hinzufügen
							$OutputItem | Add-Member -MemberType NoteProperty -Name "Length" -Value ($CALCSIZE.Sum)
						}
						$OutputItem | Add-Member -MemberType NoteProperty -Name $_ -Value $InputItem.$_
					}

					# Namen des neuen Typs festlegen
					$OutputItem.PSObject.TypeNames.Insert(0, (($InputItem.GetType().Name) + "WithSize"))

					# Standardausgabeeigenschaften hinzufügen
					$DefaultDisplaySet = @("Mode", "LastWriteTime", "Files", "Length", "Name")
					# die Standardeigenschaften dem Objekt hinzufügen ([OBJECT].PSStandardMembers.DefaultDisplayPropertySet.ReferencedPropertyNames)
					$DefaultDisplayPropertySet = New-Object System.Management.Automation.PSPropertySet("DefaultDisplayPropertySet", [STRING[]]$DefaultDisplaySet)
					$PSStandardMembers = [System.Management.Automation.PSMemberInfo[]]$DefaultDisplayPropertySet
					$OutputItem | Add-Member -MemberType MemberSet -Name PSStandardMembers -Value $PSStandardMembers

					# Objekt bzw. Zeile an die Pipeline zurückgeben
					$OutputItem
				} else {
					# kein Verzeichnisobjekt, identisch zurückgeben
					$InputItem
				}
			}
		}
	}

	END {	}
}
