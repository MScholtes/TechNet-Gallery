# Powershell functions to split and join binary files fast
Powershell scripts to export and import firewall rules in CSV or JSON format.

Since Technet Gallery will be closed, now here.

See Script Center version: [Powershell functions to split and join binary files fast](https://gallery.technet.microsoft.com/scriptcenter/Powershell-functions-to-cb6bb05a).

Now also on Powershell Gallery as part of the **SysAdminsFriends** module, see [here](https://www.powershellgallery.com/packages/SysAdminsFriends/) or install with
```powershell
Install-Module SysAdminsFriends
```

Project page on github is [here](https://github.com/MScholtes/SysAdminsFriends).

## Description
Two Powershell functions to split and join binary files fast. The functions are using .Net BinaryWriter methods.

If .Net 4 or above is detected, the quick .CopyTo() method is used to join files.

## Usage:
in the following examples I assume all files are in the current directory

Dot source the functions first:
```powershell
. .\Split-File.ps1
```
You can then split a file BigFile.dat with
```powershell
Split-File "BigFile.dat" 10000000
```
into parts of 10000000 byte size or to parts of the default size of 100 MB with
```powershell
Split-File "BigFile.dat"
```
The generated part files are named BigFile01.dat, BigFile02.dat, BigFile03.dat ...

You can join the part files BigFile01.dat, BigFile02.dat, BigFile03.dat ... to the original file e.g. with
```powershell
dir BigFile??.dat | Join-File Rebuild.dat```
```
Rebuild.dat is the same file as the original BigFile.dat.
