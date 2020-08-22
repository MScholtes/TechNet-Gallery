<#
.Synopsis
Inserts a file as a segment into an existing file or overwrites parts of the existing file.
.Description
Inserts a file as a segment into an existing file or overwrites parts of the existing file.
If no target file name is specified, the original file is overwritten.
.Parameter SourceFile
Path to source file
.Parameter InsertFile
Path to the file which is inserted as a segment
.Parameter TargetFile
Path to target file. If this parameter is omitted, the source file will be overwritten
.Parameter Position
Starting point in source file where the file is inserted
.Parameter Replace
From Position source file is overwritten instead of inserted (standard mode: insert).
If the length of InsertFile is greater than the rest of the source file starting from Position, the file
is enlarged
.Inputs
None
.Outputs
None
.Example
Import-FileSegment Originalfile.dat Insertdata.dat Patchedfile.dat 1024

Inserts the content of "Insertdata.dat" into "Originalfile.dat" starting at position 1024 and saves the result to
"Patchedfile.dat". The source file "Originalfile.dat" remains unchanged.
.Example
Import-FileSegment -SourceFile Originalfile.dat -InsertFile Insertdata.dat -Position 0x0400 -Replace

Inserts the content of "Insertdata.dat" into "Originalfile.dat" starting at position 1024 with overwriting the
content of "Originalfile.dat" and writing back the result to "Originalfile.dat".
.Notes
Author: Markus Scholtes
Created: 2020/07/12
#>
function Import-FileSegment([Parameter(Mandatory = $TRUE)][STRING] $SourceFile, [Parameter(Mandatory = $TRUE)][STRING] $InsertFile, [STRING] $TargetFile, [int] $Position = 0, [SWITCH] $Replace)
{
	if ($Position -lt 0)
	{
		Write-Error "Position in file must be greater than or equal to 0"
		return
	}

	try {
		$SourceSize = (Get-ChildItem $SourceFile -ErrorAction Stop).Length
	}
	catch {
		Write-Error "Source file $SourceFile does not exist"
		return
	}

	try {
		$InsertSize = (Get-ChildItem $InsertFile -ErrorAction Stop).Length
	}
	catch {
		Write-Error "Insert file $InsertFile does not exist"
		return
	}

	if ($InsertSize -eq 0)
	{
		Write-Error "Insert file $InsertFile must not be an empty file"
		return
	}

	if ($Position -gt $SourceSize)
	{
		Write-Error "Position must be within the source file"
		return
	}

	$TEMPFILE = "$ENV:TEMP\$((Get-ChildItem $SourceFile).Name)"
	try {
		$OBJWRITER = New-Object System.IO.BinaryWriter([System.IO.File]::Create($TEMPFILE))
	}
	catch {
		Write-Error "Error while creating the temporary file"
		return
	}

	# Schreibe Inhalt vor Einfügung
	if ($Position -gt 0)
	{
		Write-Output "Write content from $SourceFile up to position $Position"
		[Byte[]]$BUFFER = New-Object Byte[] $Position

		try {
			$OBJREADER = New-Object System.IO.BinaryReader([System.IO.File]::Open($SourceFile, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read))
			$BYTESREAD = $OBJREADER.Read($BUFFER, 0, $Position)
			$OBJWRITER.Write($BUFFER, 0, $BYTESREAD)
			$OBJREADER.Close()
		}
		catch {
			Write-Error $_
			$OBJREADER.Close()
			$OBJWRITER.Close()
			return
		}
	}

	# Schreibe Einfügung
	Write-Output "Write content from $InsertFile"
	try {
		$OBJREADER = New-Object System.IO.BinaryReader([System.IO.File]::Open($InsertFile, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read))
		$OBJWRITER.BaseStream.Position = $OBJWRITER.BaseStream.Length
		$OBJREADER.BaseStream.CopyTo($OBJWRITER.BaseStream)
		$OBJWRITER.BaseStream.Flush()
		$OBJREADER.Close()
	}
	catch {
		Write-Error $_
		$OBJREADER.Close()
		$OBJWRITER.Close()
		return
	}

	# Schreibe Inhalt nach Einfügung
	if ($Replace)
	{ # Replace old content at $Position, so continue behind insertion
		$Position += $InsertSize
	}

	if ($Position -lt $SourceSize)
	{
		Write-Output "Write content from $SourceFile starting with position $Position"
		try {
			$OBJREADER = New-Object System.IO.BinaryReader([System.IO.File]::Open($SourceFile, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read))
			$OBJREADER.BaseStream.Position = $Position
			$OBJREADER.BaseStream.CopyTo($OBJWRITER.BaseStream)
			$OBJWRITER.BaseStream.Flush()
			$OBJREADER.Close()
		}
		catch {
			Write-Error $_
			$OBJREADER.Close()
			$OBJWRITER.Close()
			return
		}
	}

	$OBJWRITER.Close()

	if ([STRING]::IsNullOrEmpty($TargetFile)) { $TargetFile = $SourceFile }
	Write-Output "Create target file $TargetFile"
	Move-Item -Path $TEMPFILE -Destination $TargetFile -Force
}
