<#
.SYNOPSIS
Transpose properties of objects from columns to rows.
.DESCRIPTION
Transpose properties of objects from columns to rows. Useful when the order displayed in a GridView (with
Out-GridView) or in a CSV file (with Export-Csv) should be rotated.
It uses the name property or a given property as new property names (column headers) if it exists.
.PARAMETER Title
Name of property whose values are used as titles
.INPUTS
Object
.OUTPUTS
Transposed object
.EXAMPLE
dir | Transpose-Object | Out-GridView

Shows directory listing with a column instead of a row for every file/directory
.EXAMPLE
ps | Transpose-Object | Export-Csv Processes.csv -Delimiter ';' -NoTypeInformation

Creates a CSV file with a column instead of a row for every process
.NOTES
Name: Transpose-Object
Author: Markus Scholtes
Version: 1.2 - values of 0, $FALSE or "" not longer identified as $NULL
Creation Date: 20/03/2023
#>
function Transpose-Object
{ [CmdletBinding()]
  Param([OBJECT][Parameter(ValueFromPipeline = $TRUE)]$InputObject, [STRING]$Title = "Name")

  BEGIN
  { # initialize variables just to be "clean"
    $Props = @()
    $PropNames = @()
    $InstanceNames = @()
  }

  PROCESS
  {
  	if ($Props.Length -eq 0)
  	{ # when first object in pipeline arrives retrieve its property names
			$PropNames = $InputObject.PSObject.Properties | Select-Object -ExpandProperty Name
			# and create a PSCustomobject in an array for each property
			$InputObject.PSObject.Properties | %{ $Props += New-Object -TypeName PSObject -Property @{Property = $_.Name} }
		}

		if ([BOOL]($InputObject.psobject.Properties | where { $_.Name -eq $Title}))
 		{ # does object have a $Title property (default "Name")?
 			$Property = $InputObject.$Title
 		} else { # no, take object itself as property name
 			$Property = ($InputObject | Out-String).Trim()
		}

 		if ($InstanceNames -contains $Property)
 		{ # does multiple occurence of value of $Title exist?
  		$COUNTER = 0
  		$StoredValue = $Property
 			do { # yes, append a number in brackets to $Title
 				$COUNTER++
 				$Property = "$StoredValue ({0})" -f $COUNTER
 			} while ($InstanceNames -contains $Property)
 		}
 		# add current name to name list for next name check
 		$InstanceNames += $Property

  	# retrieve property values and add them to the property's PSCustomobject
  	$COUNTER = 0
  	$PropNames | %{
  		if ($NULL -ne $InputObject.($_))
  		{ # property exists for current object
  			$Props[$COUNTER] | Add-Member -Name $Property -Type NoteProperty -Value $InputObject.($_)
  		} else { # property does not exist for current object, add $NULL value
  			$Props[$COUNTER] | Add-Member -Name $Property -Type NoteProperty -Value $NULL
  		}
 			$COUNTER++
  	}
  }

  END
  {
  	# return collection of PSCustomobjects with property values
  	$Props
  }
}
