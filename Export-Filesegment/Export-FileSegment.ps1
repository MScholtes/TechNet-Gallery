<#
.Synopsis
Writes a segment of a file to a new file
.Description
Writes a segment of a file to a new file. The source file will not be changed.
The length of the segment can be determined via block size or end position.
If no segment length is specified the rest of the file is written as segment.
.Parameter Path
Path to source file
.Parameter Target
Path to target file
.Parameter Start
Starting point of segment in source file
.Parameter End
Ending point of segment in source file (is preferred before specifying -Size)
.Parameter Size
Size of the segment in the file (specification of -End is preferred)
.Inputs
None
.Outputs
None
.Example
Export-FileSegment LargeFile.dat Extract.dat 0x1000000 0x1001000

Extracts 4096 bytes from LargeFile.dat starting at position 16777216 and writes them to file Extract.dat
.Example
Export-FileSegment -Path "C:\Users\He\Pictures\sample.jpg" -Target ".\Header.dat" -Start 0 -Size 11

Reads the 11 bytes of the JPEG header from the image and writes it to Header.dat in the current directory
.Notes
Autor: Markus Scholtes
Created: 2018, translated 2020/06/30
#>
function Export-FileSegment([Parameter(Mandatory = $TRUE)][STRING] $Path, [Parameter(Mandatory = $TRUE)][STRING] $Target, [int] $Start = 0, [int] $End = -1, [int] $Size = -1)
{
	if ($Start -lt 0)
	{
		Write-Error "Start position in file must be greater than or equal to 0"
		return
	}
	if ($End -ge 0)
	{
		if ($Start -gt $End)
		{
			Write-Error "End position in file must be greater than or equal to start position"
			return
		}
		$Size = $End - $Start
	}

	Write-Output "Processing file '$Path'"
	try {
		$OBJREADER = New-Object System.IO.BinaryReader([System.IO.File]::Open($Path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read))
	}
	catch {
		Write-Error "Error opening '$Path'"
		return
	}
	if ($Start -gt [int]$OBJREADER.BaseStream.Length)
	{
		$OBJREADER.Close()
		Write-Error "Start position must not be larger than file size"
		return
	}

 	if ($Size -lt 0) { $Size = [int]$OBJREADER.BaseStream.Length - $Start	}

	[Byte[]]$BUFFER = New-Object Byte[] $Size
	[int]$BYTESREAD = 0

	if ($Start -gt 0) { $OBJREADER.BaseStream.Seek($Start, [System.IO.SeekOrigin]::Begin) | Out-Null }

	Write-Output "Reading $Size bytes at position $Start"
	if (($BYTESREAD = $OBJREADER.Read($BUFFER, 0, $BUFFER.Length)) -ge 0)
	{
		Write-Output "Read $BYTESREAD bytes from '$Path'"
		Write-Output "Writing file '$Target'"
		try {
			$OBJWRITER = New-Object System.IO.BinaryWriter([System.IO.File]::Create($Target))
			$OBJWRITER.Write($BUFFER, 0, $BYTESREAD)
			$OBJWRITER.Close()
		}
		catch {
			Write-Error "Error writing '$Target'"
		}
	}
	$OBJREADER.Close()
}
