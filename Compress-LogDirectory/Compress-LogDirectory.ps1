<#
.Synopsis
Compress log files older than the current month in a given directory or the IIS log directories.
.Description
Compress log files older than the current month in a given directory or the IIS log directories.
Zip archives with the name ZipArchiveYYYY.zip are created in the log directories, where YYYY is the year of change of the archived file.
By default, only files with the extension ".log" are archived. This extension, the month, the archive name and recursive processing of subdirectories can be selected by parameters.

A regular start via scheduled tasks can be set up at a command prompt for example via (the path to the script has to be adjusted):

schtasks.exe /Create /TN "Archive IIS log files" /TR "Powershell.exe -NoProfile -Command \"^& 'C:\Work\Compress-LogDirectory.ps1' -IIS\"" /SC MONTHLY /D 15 /ST 21:15 /RU SYSTEM /RL HIGHEST /F
.Parameter Path
Path of the log directory (also via pipeline)
.Parameter IIS
IIS log directories are processed
.Parameter Filter
Filter of the files to be archived
.Parameter MonthBack
Number of months in the past for checking the change date
.Parameter ArchiveName
Name part of the archives
.Parameter Recurse
Recursive processing of subdirectories of $Path
.Inputs
Directory path
.Outputs
None
.Example
.\Compress-LogFileDirectory.ps1 -Path "C:\LogFiles" -Filter "*.*" -MonthBack 3 -ArchiveName "zip"

Archives all files in directory C:\LogFiles which are 3 months older than the current month in the archives "zipYYYY.zip" (YYYY = year of change of the respective file).
.Example
.\Compress-LogFileDirectory.ps1 -IIS

Archives all files in IIS log directories older than the current month in the archives "ZipArchiveYYYY.zip" (YYYY = year of change of the respective file) in the log directories.
.Notes
Author: Markus Scholtes
Version: 1.0
Date: 2019-05-06
#>
Param([Parameter(Position=1,Mandatory,ValueFromPipeline,ValueFromPipelineByPropertyName,ParameterSetName="PerPath")][Alias("FullName")]$Path,
		[Parameter(Position=1,Mandatory,ParameterSetName="ForIIS")][SWITCH]$IIS,
		[Parameter(Position=2,ParameterSetName="PerPath")][STRING]$Filter = "*.log",
		[Parameter(Position=3,ParameterSetName="PerPath")][Parameter(Position=2,ParameterSetName="ForIIS")][INT]$MonthBack = 0,
		[Parameter(Position=4,ParameterSetName="PerPath")][Parameter(Position=3,ParameterSetName="ForIIS")][STRING]$ArchiveName = "ZipArchive",
		[Parameter(Position=5,ParameterSetName="PerPath")][SWITCH]$Recurse
)

function Compress-LogDirectory
{ # directory names can be passed per parameter or pipeline
	Param(
		[Parameter(Mandatory,ValueFromPipeline,ValueFromPipelineByPropertyName)][Alias("FullName")]$Path,
		[STRING]$Filter = "*.log",
		[INT]$MonthBack = 0,
		[STRING]$ArchiveName = "ZipArchive"
	)

	# compute the date of the first day after the month to archive
	$DateBack = (Get-Date).AddMonths(-1*$MonthBack)
	$DateFilter = [DateTime]::new($DateBack.Year, $DateBack.Month, 1)

	Write-Output ("-"*80)
	# process only if path is a directory
	if (Test-Path -Path $Path -PathType Container)
	{
		if ($Path -is [STRING])
		{ # if path is of type string, convert to DirectoryInfo
			$Path = Get-Item -Path $Path
		}

		Write-Output "Processing directory $($Path.FullName)"
		# retrieve filtered files older then $DateFilter
		$FILES = Get-ChildItem -Path $Path -Filter $Filter -File | ? { $_.LastWriteTime -lt $DateFilter }
		if ($FILES.Count -gt 0)
		{ # if files found fitting to filter
			Write-Output "Found $($FILES.Count) files to compress."
			$FILES | % { # for each file: compute archive name to last write time, add file to archive and delete file
				try {
					$NAMEWITHYEAR = Join-Path -Path $Path.FullName -ChildPath "$ArchiveName$($_.LastWriteTimeUtc.Year.ToString()).zip"

					if ($_.FullName -ne $NAMEWITHYEAR)
					{ # only compress if not archive file itself
						Write-Output "Compressing file $($_.Name) to archive $NAMEWITHYEAR"
						Compress-Archive -Path $_.FullName -DestinationPath $NAMEWITHYEAR -Update:(Test-Path $NAMEWITHYEAR) -CompressionLevel Optimal -ErrorAction Stop

						Write-Output "Removing file $($_.Name)"
						Remove-Item -Path $_.FullName
					}
					else
					{ # archive file itself is ignored
						Write-Output "Ignoring archive file $NAMEWITHYEAR"
					}
				}
				catch { # error occured on archiving or deleting
					Write-Error $PSItem.Exception.Message
				}
			}
		}
		else
		{ # no files to archive found
			Write-Output "Found no files to compress."
		}
	}
	else
	{	# file found or path does not exist, error and return
		if (Test-Path -Path $Path)
		{ # file found
			Write-Error "$Path is a file."
		}
		else
		{ # path does not exist
			Write-Error "$Path does not exist."
		}
	}
}


if ($IIS)
{ # process IIS logfile directories
	try { # load IIS module
		Import-Module WebAdministration -ErrorAction Stop
	}
	catch { # cannot load IIS module
		Write-Error "Cannot load IIS Powershell module, are IIS and administrative rights present?"
		exit
	}

	ForEach ($WEBSITE in (Get-Website))
	{ # iterate through websites
		$IISLOGDIR = $WEBSITE.LogFile.Directory + "\W3SVC" + $WEBSITE.Id -replace "%SystemDrive%", $ENV:SystemDrive -replace "%LOGFILEDIR%", $ENV:LOGFILEDIR
		Write-Output "Processing log directory $IISLOGDIR of web site '$($WEBSITE.Name)'"
		Compress-LogDirectory -Path $IISLOGDIR -Filter "*.log" -MonthBack $MonthBack -Archive $ArchiveName
	}
}
else
{ # process directory in parameter -Path
	# archive logs in directory $Path
	Compress-LogDirectory -Path $Path -Filter $Filter -MonthBack $MonthBack -Archive $ArchiveName

	if ($RECURSE)
	{ # archive logs in subdirectories too
		Get-ChildItem -Path $Path -Directory -Recurse | % { Compress-LogDirectory -Path $_.FullName -Filter $Filter -MonthBack $MonthBack -Archive $ArchiveName }
	}
}
