<#
.SYNOPSIS
Highlight string according to a regular expression.
Worker function for Write-Highlight.
.DESCRIPTION
Highlight string according to a regular expression.
Multiple search expressions are allowed, each expression is highlighted with its own color
Worker function for Write-Highlight.
.PARAMETER Pattern
Array of regular expressions to highlight
.PARAMETER Text
String to search in
.PARAMETER CaseSensitive
Search is case sensitive
.PARAMETER Onlymatches
Only lines with matches are displayed
.PARAMETER PassThru
Parameter has no effect
.NOTES
Author: Markus Scholtes, 2017/04/18
#>
function Highlight-String
{
	[CmdletBinding()]
	param(
		[Parameter(Mandatory = $FALSE, Position = 0) ] [STRING[]]$Pattern = @(""),
		[Parameter(Mandatory = $FALSE, Position = 1, ValueFromPipeline = $TRUE)][AllowEmptyString()]$Text,
		[SWITCH]$CaseSensitive,
		[SWITCH]$OnlyMatches,
		[SWITCH]$PassThru
	)

	BEGIN
	{
		# add color to color queue if not foreground or background color
		# attention: as a queue is an object it is always handed to a function per reference. 
		# So the variable $ColorQueue in the calling context gets changed (and the function works independant of variable scopes)
		function AddColorToQueue([STRING]$ColorToAdd, $Queue)
		{
			if (($Host.UI.RawUI.ForegroundColor -ne $ColorToAdd) -and ($Host.UI.RawUI.BackgroundColor -ne $ColorToAdd))
			{	$Queue.Enqueue($ColorToAdd) }
		}

		# queue for available colors
		$ColorQueue = New-Object System.Collections.Queue

		# add all powershell colors to queue
 		AddColorToQueue 'Yellow' $ColorQueue
		AddColorToQueue 'Magenta' $ColorQueue
		AddColorToQueue 'Red' $ColorQueue
		AddColorToQueue 'Cyan' $ColorQueue
		AddColorToQueue 'Green' $ColorQueue
		AddColorToQueue 'Blue' $ColorQueue
		AddColorToQueue 'Gray' $ColorQueue
		AddColorToQueue 'White' $ColorQueue
		AddColorToQueue 'DarkGray' $ColorQueue
		AddColorToQueue 'DarkYellow' $ColorQueue
		AddColorToQueue 'DarkMagenta' $ColorQueue
		AddColorToQueue 'DarkRed' $ColorQueue
		AddColorToQueue 'DarkCyan' $ColorQueue
		AddColorToQueue 'DarkGreen' $ColorQueue
		AddColorToQueue 'DarkBlue' $ColorQueue
		AddColorToQueue 'Black' $ColorQueue

		# create regular expression hash and color hash for every search pattern
		$RegExHash = @{}
		$ColorHash = @{}
		if (!$CaseSensitive)
		{	# search is case insensitive
			foreach ($SingleSearch In $Pattern)
			{ # create regular expression object and chose next color
				$RegExHash[$SingleSearch] = New-Object System.Text.RegularExpressions.Regex($SingleSearch, @([System.Text.RegularExpressions.RegexOptions]::IgnoreCase))
				$ColorHash[$SingleSearch] = $ColorQueue.Dequeue()
				$ColorQueue.Enqueue($ColorHash[$SingleSearch])
			}
		}
		else
		{ # search is case sensitive
			foreach ($SingleSearch In $Pattern)
			{	# create regular expression object and chose next color
				$RegExHash[$SingleSearch] = New-Object System.Text.RegularExpressions.Regex($SingleSearch, @([System.Text.RegularExpressions.RegexOptions]::None))
				$ColorHash[$SingleSearch] = $ColorQueue.Dequeue()
				$ColorQueue.Enqueue($ColorHash[$SingleSearch])
			}
		}

		# split string into substrings according to regular expressions
		function Split-Regex([STRING]$Text, $HashTable, [SWITCH]$OnlyMatches)
		{
			# if text is empty we're ready
			if ($Text -eq "")
			{ return $FALSE }

			# search for every regular expression
			$Found = $FALSE
			foreach ($Index In $HashTable.Keys)
			{
				if ($Index -eq "")
				{ # if search pattern is an empty string -> highlight complete string
					$FOUND = $TRUE
					Write-Host $Text -ForegroundColor $ColorHash[$Index] -NoNewline
					break
				}

				# search for pattern
				$Match = $HashTable[$Index].Match($Text)
				if (($Match.Success) -And ($Match.Length -gt 0))
				{ # pattern found, split string and compute substrings recursively
					$FOUND = $TRUE
					# compute string before match
					Split-Regex $Text.Substring(0, $Match.Index) $HashTable -OnlyMatches:$FALSE
					# highlight match
					Write-Host $Match.Value.ToString() -ForegroundColor $ColorHash[$Index] -NoNewline
					# compute string after match
					Split-Regex $Text.Substring($Match.Index + $Match.Length, $Text.Length - $Match.Index - $Match.Length) $HashTable -OnlyMatches:$FALSE
					break
				}
			}
			if ($FOUND)
			{ # pattern found
				return $TRUE
			}
			else
			{ # no pattern found, write string only if -OnlyMatches is not set
				if (!$OnlyMatches)
				{ Write-Host $Text -NoNewline }
				return $FALSE
			}
		}
	}

	PROCESS
	{
		# parameter or pipeline object is handed to variable $Line
		if ($_ -ne $NULL)
		{ # string is in pipeline
			$Line = $_
		}
		else
		{ # string is in parameter $Text
			$Line = $Text
		}

		# search for patterns
		if ((Split-Regex $Line $RegExHash -OnlyMatches:$OnlyMatches) -Or (!$OnlyMatches))
		{ # if found or -OnlyMatches not set, write new line
			Write-Host
		}
	}

	END
	{
	}
}


<#
.SYNOPSIS
Highlight output according to a regular expression.
.DESCRIPTION
Highlight output according to a regular expression.
Multiple search expressions are allowed, each expression is highlighted with its own color
.PARAMETER Pattern
Array of regular expressions to highlight
.PARAMETER CaseSensitive
Search is case sensitive
.PARAMETER Onlymatches
Only lines with matches are displayed
.PARAMETER PassThru
The incoming object is given to the output queue unchanged
.EXAMPLE
Get-ChildItem | Write-Highlight "\w+\.ps1","\w+\.bat"
Displays the current directory and highlights all files that have a .ps1 or .bat extension
.EXAMPLE
Get-ChildItem | Write-Highlight "\w+\.ps1" -PassThru | Sort -Property Length
Displays the current directory and highlights all files that have a .ps1 extension.
The complete directory listing is handed to the commandlet Sort afterwards.
.EXAMPLE
1..10 | %{ "Line $_" } | Write-Highlight -Pattern "1","2","3","4","5","6","7","8","9","10"
Every number in the output is highlighted with its own color
.EXAMPLE
gc .\Write-Highlight.ps1 | Write-Highlight "STRING" -Case -OnlyMatches
All lines in the file "Write-Highlight.ps1" with the casesensitive expression "STRING" are given out,
the expression "STRING" is highligthed
.NOTES
Author: Markus Scholtes, 2017/04/18
#>
function Write-Highlight([STRING[]]$Pattern, [SWITCH]$CaseSensitive, [SWITCH]$OnlyMatches, [SWITCH]$PassThru)
{
	# make a copy of the input queue before it's gone (for passthru)
	if ($PassThru)
	{ $Return = $INPUT.Clone() }

	# convert input object to string array and hand it to worker function
	$INPUT | Out-String -Stream | Highlight-String @PSBoundParameters

	# return stored input object (for passthru)
	if ($PassThru)
	{ return $Return }
}
