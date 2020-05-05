<#
.Synopsis
Adds a property / column with a changing color to objects.
.Description
Adds a property / column with a changing color to objects. The coloring can only be seen when outputting
the object to an ANSI escape sequence-capable output device. The standard output properties are extended by
this column if they exist.
.Parameter InputObject
Object to be expanded. Can be handed through the pipeline.
.Parameter OddColor
Color for odd line numbers
.Parameter EvenColor
Color for even line numbers
.Parameter TitleColor
Color for title bar
.Inputs
Object
.Outputs
Object
.Notes
Name: Add-LineColoring
Author: Markus Scholtes
Creation date: 2018/11/27
.Example
dir | Add-LineColoring

Adds changing colors to the directory output.
.Example
Get-LocalGroupMember Administrators | Add-LineColoring -OddColor Green -EvenColor Magenta

Retrieves members of local administrators group and colors them in the output.
.Example
Get-CimInstance Win32_Group | Add-LineColoring -TitleColor Black | Format-Table

Returns all local groups. Format-Table should be added since the Listview output format would be chosen
otherwise because of the new property.
#>
function Add-LineColoring
{
	Param([Parameter(ValueFromPipeline = $TRUE)][OBJECT[]]$InputObject, [STRING]$OddColor = "Yellow", [STRING]$EvenColor = "Red", [STRING]$TitleColor = "Green")

	BEGIN
	{
		$ColorValues = @{"Black" = "30"; "DarkBlue" = "34"; "DarkGreen" = "32"; "DarkCyan" = "36"; "DarkRed" = "31"; "DarkMagenta" = "35"; "DarkYellow" = "33"; "DarkGray" = "37"; "Gray" = "90"; "Blue" = "94"; "Green" = "92"; "Cyan" = "96"; "Red" = "91"; "Magenta" = "95"; "Yellow" = "93"; "White" = "97" }
		if ($ColorValues.ContainsKey($OddColor))
		{
			$OddCode = "$([CHAR]27)[$($ColorValues.($OddColor))m"
		} else {
			$OddCode = "$([CHAR]27)[93m"
		}
		if ($ColorValues.ContainsKey($EvenColor))
		{
			$EvenCode = "$([CHAR]27)[$($ColorValues.($EvenColor))m"
		} else {
			$EvenCode = "$([CHAR]27)[91m"
		}

		$OddOrEven = $TRUE
		# Escapesequenz mit Farbe für Überschrift
		if ($ColorValues.ContainsKey($TitleColor))
		{
			"$([CHAR]27)[$($ColorValues.($TitleColor))m"
		} else {
			"$([CHAR]27)[92m"
		}
	}

	PROCESS
	{
		# nur wenn Eingabeobjekt vorhanden
		if ($InputObject)
		{ # alle Array-Mitglieder durchlaufen (oder nur Objekt selbst, wenn kein Array)
			foreach ($InputItem in $InputObject)
			{ # PSCustomObject zum Hinzufügen der Nummerierungsspalte erstellen
				$OutputItem = New-Object PSCustomObject

				# Spalte " " mit Escapesequenz zum Färben hinzufügen
				if ($OddOrEven)
				{
					$OutputItem | Add-Member -MemberType NoteProperty -Name " " -Value $OddCode
				} else {
					$OutputItem | Add-Member -MemberType NoteProperty -Name " " -Value $EvenCode
				}

				# weitere Eigenschaften hinzufügen
				if (($InputItem | Get-Member -MemberType *Property) -And ($InputItem -isnot [STRING]))
				{ # die bestehenden Eigenschaften des Eingabeobjekts hinzufügen
					$InputItem | Get-Member -MemberType *Property | Select-Object -ExpandProperty Name | % { $OutputItem | Add-Member -MemberType NoteProperty -Name $_ -Value $InputItem.$_ }
				} else { # es gibt keine Eigenschaft, dann Objekt selbst ausgeben
					$OutputItem | Add-Member -MemberType NoteProperty -Name "Value" -Value $InputItem
				}

				# Namen des neuen Typs festlegen
				$OutputItem.PSObject.TypeNames.Insert(0, (($InputItem.GetType().Name) + "LineNumbering"))

				# Standardausgabeeigenschaften hinzufügen
				$DefaultDisplaySet = @(" ")
				if ($InputItem.PSStandardMembers.DefaultDisplayPropertySet.ReferencedPropertyNames)
				{ # es gibt ein Array von Standardeigenschaften, dann diese dem Objekt hinzufügen
					$DefaultDisplaySet += $InputItem.PSStandardMembers.DefaultDisplayPropertySet.ReferencedPropertyNames
				} else {
					if ($InputItem.PSStandardMembers.DefaultDisplayProperty)
					{ # es gibt nur eine Standardeigenschaft, dann diese dem Objekt hinzufügen
						$DefaultDisplaySet += $InputItem.PSStandardMembers.DefaultDisplayProperty
					} else { # es gibt keine Standardeigenschaft, dann auch keine für geändertes Objekt erzeugen
						$DefaultDisplaySet = $NULL
						# Objekt selbst in der Eigenschaft "Value" ausgeben
						# $DefaultDisplaySet += "Value"
					}
				}
				if ($DefaultDisplaySet)
				{ # die ermittelten Standardeigenschaften dem Objekt hinzufügen ([OBJECT].PSStandardMembers.DefaultDisplayPropertySet.ReferencedPropertyNames)
					$DefaultDisplayPropertySet = New-Object System.Management.Automation.PSPropertySet("DefaultDisplayPropertySet", [STRING[]]$DefaultDisplaySet)
					$PSStandardMembers = [System.Management.Automation.PSMemberInfo[]]$DefaultDisplayPropertySet
					$OutputItem | Add-Member -MemberType MemberSet -Name PSStandardMembers -Value $PSStandardMembers
				}

				# Objekt bzw. Zeile an die Pipeline zurückgeben
				$OutputItem
				# Zeilenfarbe tauschen
				$OddOrEven = !$OddOrEven
			}
		}
	}

	END
	{
		# Escapesequenz für Default-Farbe
		"$([CHAR]27)[0m"
	}
}
