<#
.Synopsis
Replaces text in files while preserving the encoding
.Description
Replaces text in files while preserving the encoding. Optionally, the file's time information is kept as well.
The result is output to the pipeline if no -Overwrite is specified.
If the encoding can not be determined, ASCII is assumed.
.Parameter Pattern
Search as a regular expression
.Parameter Replacement
Replaced text
.Parameter Path
File or directory name
.Parameter Recurse
Work files recursively in subdirectories
.Parameter CaseSensitive
Case-sensitive search
.Parameter Unix
For search patterns with end of line, this is searched for as a Unix line end (only NewLine instead of LineFeed + NewLine)
.Parameter Overwrite
The edited texts are copied to the original files (instead of given to the pipeline)
.Parameter Force
For -Overwrite: Even unchanged texts are written to the original files
.Parameter PreserveDate
The modified files retain the original time stamps
.Parameter Quiet
No output at the console
.Parameter OEM
Files in ASCII format are processed with OEM character set 850 (instead of Windows character set 1252)
.Parameter Encoding
Force writing of files in this encoding
.Inputs
File names can be passed over the pipeline
.Outputs
Edited texts, if not -Overwrite is specified
.Example
Replace-InFile.ps1 -Pattern "Mister" -Replacement "Lady" -Path Test.txt -Quiet > result.txt

Replaces Mister with Lady in the file "Test.txt" and writes the result to result.txt
.Example
dir | Replace-InFile.ps1 -Pattern "12" -Replacement "34" -Overwrite

Replaces 12 with 34 in all files of the current directory
.Example
gci | Replace-InFile.ps1 -Pattern "spät" -Replacement "später" -CaseSensitive -Recurse -OEM

Replaces spät with später in all files of the current directory and all subdirectories.
The case is case-sensitive. ASCII files are interpreted as OEM files.
The result is not written back to the files, but is output to the pipeline.
.Example
Get-ChildItem "*.txt" | Replace-InFile.ps1 -Pattern "t$" -Replacement "T" -Encoding UNICODE -Overwrite

Replaces t at the end of the line with T in all txt files of the current directory.
The files are written in UNICODE encoding.
.Example
Get-ChildItem "*.txt" | Replace-InFile.ps1 -Pattern "t\r\n" -Replacement "T\r\n" -Overwrite

Replaces t at the end of the line with T in all txt files of the current directory.
.Example
"*.txt" | Replace-InFile.ps1 -Pattern "<NL>" -Replacement "`n" -enc "Ascii" -VERBOSE

Replaces <NL> with an end of line in all txt files of the current directory.
The result is output in ASCII encoding. There is a verbose output.
.Example
Replace-InFile.ps1 -Pattern "weg" -Path "*.txt" -Overwrite -PreserveDate -WhatIf

Removes the expression weg in all txt files of the current directory, preserving the time stamp of the
files. No change is made because of the switch -WhatIf.
.Example
Replace-InFile.ps1 "*" -patt "Search" -repl "Replace" -rec -enc UTF8 -u -over

Replaces Search with Replace in all files of the current directory and all subdirectories.
UTF8 is written as encoding, line breaks are interpreted as Unix line breaks.
.Notes
Author: Markus Scholtes, 06.02.2017
#>
[CmdletBinding(SupportsShouldProcess=$TRUE)]
param(
  [parameter(Mandatory=$TRUE, Position=0)] [STRING]$Pattern,
  [parameter(Position=1)] [STRING][AllowEmptyString()]$Replacement,
  [parameter(Mandatory=$FALSE, Position=2, ValueFromPipeline=$TRUE)] [STRING][AllowEmptyString()]$Path,
  [SWITCH]$CaseSensitive,
  [SWITCH]$Unix,
  [SWITCH]$Overwrite,
  [SWITCH]$Force,
  [SWITCH]$Recurse,
  [SWITCH]$PreserveDate,
  [SWITCH]$Quiet,
  [SWITCH]$OEM,
  [Microsoft.PowerShell.Commands.FileSystemCmdletProviderEncoding]$Encoding = "Unknown"
)



function Replace-InFile
{
	[CmdletBinding(SupportsShouldProcess=$TRUE)]
	param(
	  [parameter(Mandatory=$TRUE, Position=0)] [STRING]$Pattern,
	  [parameter(Position=1)] [STRING][AllowEmptyString()]$Replacement,
	  [parameter(Mandatory=$FALSE, Position=2, ValueFromPipeline=$TRUE)] [STRING][AllowEmptyString()]$Path,
	  [SWITCH]$CaseSensitive,
	  [SWITCH]$Unix,
	  [SWITCH]$Overwrite,
	  [SWITCH]$Force,
	  [SWITCH]$Recurse,
	  [SWITCH]$PreserveDate,
	  [SWITCH]$Quiet,
	  [SWITCH]$OEM,
	  [Microsoft.PowerShell.Commands.FileSystemCmdletProviderEncoding]$Encoding = "Unknown"
	)


	BEGIN
	{
		function Get-FileEncoding {
		##############################################################################
		##
		## Get-FileEncoding
		##
		## From Windows PowerShell Cookbook (O'Reilly)
		## by Lee Holmes (http://www.leeholmes.com/guide)
		##
		## expandend and switched to FileSystemCmdletProviderEncoding
		## by Markus Scholtes, 2014
		##
		##############################################################################
		<#

		.SYNOPSIS

		Gets the encoding of a file

		.EXAMPLE

		Get-FileEncoding.ps1 .\UnicodeScript.ps1

		Unicode

		.EXAMPLE

		Get-ChildItem *.ps1 | Select FullName, @{n='Encoding';e={Get-FileEncoding $_.FullName}} | where {$_.Encoding -ne 'ASCII'}

		This command gets ps1 files in current directory where encoding is not ASCII

		.EXAMPLE

		Get-ChildItem *.ps1 | Select FullName, @{n='Encoding';e={Get-FileEncoding $_.FullName}} | where {$_.Encoding -ne 'ASCII'} | foreach {(Get-Content $_.FullName) | Set-Content $_.FullName -Encoding ASCII}

		Same as previous example but fixes encoding using set-content

		#>

		## The path of the file to get the encoding of.
		param($PATH)

		# Markus Scholtes, 2014
		# converts Encoding value of type [System.Text.Encoding] to type [Microsoft.Powershell.Commands.FileSystemCmdletProviderEncoding]
		#
		# Example
		# Convert-EncodingType ([System.Text.Encoding]::'ASCII')
		# Types can be output by using:
		#[Microsoft.Powershell.Commands.FileSystemCmdletProviderEncoding] | gm -Static -MemberType Property
		#[System.Text.Encoding] | gm -Static -MemberType Property

		function Convert-EncodingType([System.Text.Encoding]$KODIERUNG)
		{
			if ($KODIERUNG)
			{	[Microsoft.Powershell.Commands.FileSystemCmdletProviderEncoding]$KODIERUNG.BodyName.ToUpper().Replace("US-","").Replace("-","").Replace("UNICODEFFFE","BigEndianUnicode").Replace("UTF16BE","BigEndianUnicode").Replace("UTF16","Unicode").Replace("ISO88591","Default") }
			else
			{ $NULL }
		}

		Set-StrictMode -Version Latest

		## The hashtable used to store our mapping of encoding bytes to their
		## name. For example, "255-254 = Unicode"
		$ENCODINGS = @{}

		## Find all of the encodings understood by the .NET Framework. For each,
		## determine the bytes at the start of the file (the preamble) that the .NET
		## Framework uses to identify that encoding.
		$ENCODINGMEMBERS = [System.Text.Encoding] | Get-Member -Static -MemberType Property

		$ENCODINGMEMBERS | Foreach-Object {
			$ENCODINGBYTES = [System.Text.Encoding]::($_.Name).GetPreamble() -join '-'
			$ENCODINGS[$ENCODINGBYTES] = $_.Name
		}

		## Find out the lengths of all of the preambles.
		$ENCODINGLENGTHS = $ENCODINGS.Keys | Where-Object { $_ } | Foreach-Object { ($_ -split "-").Count }

		## Assume the encoding is ASCII by default
		$RESULT = "ASCII"

		if (($PATH -ne $NULL) -and ($PATH -ne "")) {
			if (Get-Content $PATH)
			{
				## Go through each of the possible preamble lengths, read that many bytes
				## from the file, and then see if it matches one of the encodings we know
				## about.
				foreach ($ENCODINGLENGTH in $ENCODINGLENGTHS | Sort -Descending)
				{
		    	$BYTES = (Get-Content -Encoding BYTE -Readcount $ENCODINGLENGTH $PATH)[0]
		    	$ENCODING = $ENCODINGS[$BYTES -join '-']

		    	## If we found an encoding that had the same preamble bytes, save that
		    	## output and break.
		    	if ($ENCODING)
		    	{
		    		$RESULT = $ENCODING
		      	break
		    	}
				}
			}
		}

		## Finally, output the encoding.
		Convert-EncodingType ([System.Text.Encoding]::$RESULT)
		}

		# Working function
		function Work-File([STRING]$Name)
		{
		  if (!$Quiet) { Write-Output "Processing file '$Name'" }

		  if ($PreserveDate)
		  {	$Datei = Get-Item "$Name"
		  	$LastAccess = $Datei.LastAccessTime
		  	$Creation = $Datei.CreationTime
		  	$LastWrite = $Datei.LastWriteTime
		  }

	 		# determine the current encoding of the source file
 			$ActualEncoding = Get-FileEncoding "$Name"

			# ReadAllText must be used to read the contents of the file
			# so it is inserted into a string and not a string array
      try {
        Write-Verbose "Reading file $Name."
	      if ($ActualEncoding -eq "ASCII")
  	    { # ASCII-Encoding, select the right codepage for the umlauts
    	  	if ($OEM)
      		{ # DOS codepage
      			$Inhalt = [IO.File]::ReadAllText($Name, [System.Text.Encoding]::GetEncoding(850))
	      	}
  	    	else
    	  	{ # Windows codepage
      			$Inhalt = [IO.File]::ReadAllText($Name, [System.Text.Encoding]::GetEncoding(1252))
	      	}
  	    }
    	  else
      	{ # other encoding, ReadAllText recognizes the correct one
      		$Inhalt = [IO.File]::ReadAllText($Name)
      	}
	      Write-Verbose "Read from file $Name finished."
	    }
	    catch [Management.Automation.MethodInvocationException]
	    {
	      Write-Error $ERROR[0]
	      return
	    }

      if (!$Quiet) { Write-Output "$($RegEx.Matches($Inhalt).Count) matches" }

      if (-not $Overwrite)
      {
	      if (-not $WHATIFPREFERENCE)
	      {
	        $RegEx.Replace($Inhalt, $Replacement)
	      }
        return
      }

      if ($Force -or ($Inhalt -cne $RegEx.Replace($Inhalt, $Replacement)))
      {
	      Write-Verbose "Writing to $Name."
	      if (-not $WHATIFPREFERENCE)
	      {
	      	try
  	    	{
		      	if ($Encoding -eq "Unknown")
		      	{ # if parameter Encoding is not set, keep current encoding
    	  			Write-Verbose "Using current encoding $ActualEncoding"
      				$TargetEncoding = $ActualEncoding
      			}
      			else
	      		{ # use chosen encoding
  	    			$TargetEncoding = $Encoding
    	  		}
      			if ($TargetEncoding -eq "ASCII")
      			{ # ASCII-Encoding, select the right codepage for the umlauts
      				if ($OEM)
      				{ # DOS codepage
      					[IO.File]::WriteAllText("$Name", $RegEx.Replace($Inhalt, $Replacement), [System.Text.Encoding]::GetEncoding(850))
      				}
	      			else
  	    			{ # Windows codepage
    	  				[IO.File]::WriteAllText("$Name", $RegEx.Replace($Inhalt, $Replacement), [System.Text.Encoding]::GetEncoding(1252))
		  	    	}
    			  }
      			else
	      		{ # andere Kodierung
  	      		[IO.File]::WriteAllText("$Name", $RegEx.Replace($Inhalt, $Replacement), [System.Text.Encoding]::$TargetEncoding)
    	  		}
  	  	  }
      		catch [Management.Automation.MethodInvocationException]
	      	{
  	      	Write-Error $ERROR[0]
    	    	return
      		}
	      }

			  if ($PreserveDate)
	  		{	# Set time stamp to original
	  			Write-Verbose "Setting original time stamp of the file."
	      	if (-not $WHATIFPREFERENCE) {
		  			$Datei.LastAccessTime = $LastAccess
		  			$Datei.CreationTime = $Creation
		  			$Datei.LastWriteTime = $LastWrite
	      	}
	  		}
	      Write-Verbose "Writing to $Name finished."
	    }
	    else
	    {
	     	if (!$Quiet) {
	     		if ($Inhalt -eq "")
	     		{ Write-Output "File is empty." } else { Write-Output "No change in text." }
	     	}
	    }
		}

	  # Replace "$" with "\r$" in regular expression (not if -Unix is set)
	  # \$ has to be preserved
	  if (-not $Unix)
	  {
	  	$NewPattern = $Pattern -replace '(?<!\\)\$', '\r$'
	  }
	  else
	  {
	  	Write-Verbose 'Search for "Unix" linefeed.'
	  	$NewPattern = $Pattern
	  }

	  # create array of Regex options and the RegEx object
	  $Options = @()
	  $Options += "Multiline"
	  if (-not $CaseSensitive)
	  { $Options += "IgnoreCase" } else { Write-Verbose 'Case-sensitive search.' }

	  $RegEx = New-Object Text.RegularExpressions.Regex $NewPattern, $Options
	  if ($Encoding -eq "Unknown")
	  { Write-Verbose "Use current encoding." } else { Write-Verbose "Use encoding $Encoding." }

	}

	PROCESS
	{
		# parameter or pipeline object is handed to $Path
		if ($_ -ne $Null)
		{ # when there is a name in the pipeline, use it
			$Name = $_
		} else {
			$Name = $Path
		}

		if (($Name -is [System.IO.FileInfo]) -or ($Name -is [System.IO.DirectoryInfo]))
		{ # if it is a FileInfo object or a DirectoryInfo object, determine path name
			$FileObject = $Name
		}
		else
		{ # if it is a String, determine complete path name and object
			$FileObject = Get-Item $Name -ErrorAction 'SilentlyContinue'

			# no file or directory found, end function
			if ($FileObject -eq $Null) { return }

			# more than one object found
			if ($FileObject -is [System.Array])
			{ # call Replace-InFile for every file
			  foreach ($FileName in $FileObject) { Replace-InFile -Pattern "$Pattern" -Replacement "$Replacement" -Path "$FileName" -CaseSensitive:$CaseSensitive -Unix:$Unix -Overwrite:$Overwrite -Force:$Force -PreserveDate:$PreserveDate -OEM:$OEM -Encoding $Encoding -Recurse:$Recurse -Quiet:$Quiet }
			  # and end function
			  return
		 	}
		}
		$Name = $FileObject.FullName

		if (Test-Path $Name)
		{ # if the path exists

	    # is it a directory?
	    if ($FileObject.PsIsContainer)
	    { # recursion?
	    	# yes -> then call Replace-InFile with child objects
	    	# no -> do nothing
	      if ($Recurse)
	     	{ Get-ChildItem $Name | Replace-InFile -Pattern "$Pattern" -Replacement "$Replacement" -CaseSensitive:$CaseSensitive -Unix:$Unix -Overwrite:$Overwrite -Force:$Force -PreserveDate:$PreserveDate -OEM:$OEM -Encoding $Encoding -Recurse -Quiet:$Quiet }
	    }
			else
			{ # it is a file -> call working function
			  Work-File $Name
			}
		}
	}
}

Replace-InFile -Pattern "$Pattern" -Replacement "$Replacement" -Path "$Path" -CaseSensitive:$CaseSensitive -Unix:$Unix -Overwrite:$Overwrite -Force:$Force -PreserveDate:$PreserveDate -Recurse:$Recurse -Quiet:$Quiet -OEM:$OEM -Encoding $Encoding
