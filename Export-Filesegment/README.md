# Powershell functions to extract and insert binary data from and to files

Since Technet Gallery is closed, now here.

Now also on Powershell Gallery as part of the **SysAdminsFriends** module, see [here](https://www.powershellgallery.com/packages/SysAdminsFriends/) or install with
```powershell
Install-Module SysAdminsFriends
```

Project page on github is [here](https://github.com/MScholtes/SysAdminsFriends).

## Description
Two Powershell functions to extract and insert binary data from and to files. The functions are using .Net BinaryWriter and BinaryReader methods.

## Usage
in the following examples I assume all files are in the current directory

Dot source the functions first:
```powershell
. .\Export-FileSegment.ps1
. .\Import-FileSegment.ps1
```

You can then extract 4096 bytes from LargeFile.dat starting at position 16777216 and write them to file Extract.dat with
```powershell
Export-FileSegment LargeFile.dat Extract.dat 0x1000000 0x1001000
```

You can read the 11 bytes of the JPEG header from the image and write them to Header.dat in the current directory with
```powershell
Export-FileSegment -Path "C:\Users\He\Pictures\sample.jpg" -Target ".\Header.dat" -Start 0 -Size 11
```

You can insert the content of "Insertdata.dat" into "Originalfile.dat" starting at position 1024 and save the result to "Patchedfile.dat" with
```powershell
Import-FileSegment Originalfile.dat Insertdata.dat Patchedfile.dat 1024
```
The source file "Originalfile.dat" remains unchanged.

You can insert the content of "Insertdata.dat" into "Originalfile.dat" starting at position 1024 with overwriting the content of "Originalfile.dat" and writing back the result to "Originalfile.dat" with
```powershell
Import-FileSegment -SourceFile Originalfile.dat -InsertFile Insertdata.dat -Position 0x0400 -Replace
```
