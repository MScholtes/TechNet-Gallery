<#
.Synopsis
Adds a numbering property / column to objects.
.Description
Adds a numbering property / column to objects. The default output properties get extended by this column
if they exist.
.Parameter InputObject
Object to be expanded. Can be handed through the pipeline.
.Parameter StartNumber
Numbering start number
.Parameter Step
Numbering increment
.Inputs
Object
.Outputs
Object
.Notes
Name: Add-LineNumbering
Author: Markus Scholtes
Creation date: 2018/11/27
.Example
dir | Add-LineNumbering

Adds line numbering to the directory output.
.Example
Get-LocalGroupMember Administrators | Add-LineNumbering -Startnumber 10 -Step 5

Retrieves members of local administrators group and numbers them by starting at 10 with increment 5.
.Example
Get-CimInstance Win32_Group | Add-LineNumbering | Format-Table

Returns all local groups. Format-Table should be added since the Listview output format would be chosen
otherwise because of the new property.
#>
function Add-LineNumbering
{
	Param([Parameter(ValueFromPipeline = $TRUE)][OBJECT[]]$InputObject, [INT]$StartNumber = 1, [INT]$Step = 1)

	BEGIN
	{
		$STARTCOUNT = $StartNumber
	}

	PROCESS
	{
		# nur wenn Eingabeobjekt vorhanden
		if ($InputObject)
		{ # alle Array-Mitglieder durchlaufen (oder nur Objekt selbst, wenn kein Array)
			foreach ($InputItem in $InputObject)
			{ # PSCustomObject zum Hinzufügen der Nummerierungsspalte erstellen
				$OutputItem = New-Object PSCustomObject

				# Spalte "#" mit aktueller Zeilennummer hinzufügen
				$OutputItem | Add-Member -MemberType NoteProperty -Name "#" -Value $STARTCOUNT

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
				$DefaultDisplaySet = @("#")
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
				# Zeilennummer erhöhen
				$STARTCOUNT += $Step
			}
		}
	}

	END {	}
}
