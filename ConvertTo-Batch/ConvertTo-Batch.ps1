<#
.Synopsis
Generate cmd.exe batch files from short Powershell scripts
.Description
Generate cmd.exe batch files from short Powershell scripts
The Powershell scripts are Base64 encoded and handed to a new Powershell instance in the batch file.
If special characters like umlauts are used in the script it has to be UTF8 encoded to preserve the special characters.
The following restrictions apply to the generated batch files:
- the script may have a maximum of 2975 characters (because of Unicode and Base64 encoding and the maximum parameter length of 8192 characters in cmd.exe)
- the execution policy is ignored
- all parameters are handed to the batch files as strings
- only position parameters are possible for the batch files (no named parameters)
- a maximum of 9 parameters are possible for the batch files
- default values for parameters do not work
.Parameter Path
Filename(s)
.Inputs
Filenames can be passed through the pipeline
.Outputs
None
.Example
ConvertTo-Batch -Path Test.ps1

Converts the Powershell script "Test.ps1" to "Test.bat"
.Example
dir *.ps1 | ConvertTo-Batch

Converts all Powershell scripts in the current directory to batch files
.Example
ConvertTo-Batch -Path ".\test.ps1", ".\test2.ps1", "c:\Data\demo.ps1"

Converts the passed Powershell scripts to batch files
.Notes
Author: Markus Scholtes, 24.02.2018
Idea: http://community.idera.com/powershell/powertips/b/tips/posts/converting-powershell-to-batch
#>
function ConvertTo-Batch
{ # file names can be passed per parameter or pipeline
	param([Parameter(Mandatory,ValueFromPipeline,ValueFromPipelineByPropertyName)][Alias("FullName")]$Path)

	BEGIN
	{ # initialize counter
		$COUNTCONVERTED = 0
	}

	PROCESS
	{	# found more than one object
		if ($Path -is [System.Array])
		{ # call for each object
		  foreach ($File in $Path) { ConvertTo-Batch $File }
		  # and exit function
		  return
		}

		if (Test-Path -Path $Path -PathType Leaf)
		{	# file found, check extension
			if ([IO.Path]::GetExtension($Path) -eq ".ps1")
			{	# convert only Powershell scripts
				$CONTENT = "function _CT_B_{"
				$CONTENT += Get-Content -Path $Path -Raw -Encoding UTF8
				$CONTENT += "`n};_CT_B_ `$ENV`:1 `$ENV`:2 `$ENV`:3 `$ENV`:4 `$ENV`:5 `$ENV`:6 `$ENV`:7 `$ENV`:8 `$ENV`:9"
				$ENCODED = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($CONTENT))
				$NEWPATH = [IO.Path]::ChangeExtension($Path, ".bat")
				"@echo off`nsetlocal`nset 1=%~1`nset 2=%~2`nset 3=%~3`nset 4=%~4`nset 5=%~5`nset 6=%~6`nset 7=%~7`nset 8=%~8`nset 9=%~9`npowershell.exe -NOP -EP ByPass -Enc $ENCODED" | Set-Content -Path $NEWPATH -Encoding ASCII
				$COUNTCONVERTED++
				Write-Output "Converted $Path`: $NEWPATH written."
			}
			else
			{ # other file type
				Write-Output "$Path is no Powershell script."
			}
		}
		else
		{ # it is a directory or the file does not exist
			Write-Output "$Path is a directory or does not exist."
		}
}

	END
	{ # report count of converted files
		Write-Output "$COUNTCONVERTED files converted."
	}
}
