# Convert short Powershell scripts to batches
Script to convert short powershell scripts to batches. Generated batches run on double click and ignore execution policies.

Since Technet Gallery will be closed, now here.

See Script Center version: [Convert short Powershell scripts to batches](https://gallery.technet.microsoft.com/scriptcenter/Convert-short-Powershell-e9b4e81d).

Now also on Powershell Gallery as part of the **SysAdminsFriends** module, see [here](https://www.powershellgallery.com/packages/SysAdminsFriends/) or install with
```powershell
Install-Module SysAdminsFriends
```

Project page on github is [here](https://github.com/MScholtes/SysAdminsFriends).

## Description
Generate cmd.exe batch files from short Powershell scripts. The Powershell scripts get Base64 encoded and handed to a new powershell instance in the batch file. There is a limitation of 2975 characters for the script to convert.

You can find several examples for this in the Internet, but this is the only one I know that can handle parameters (that are treated as string because cmd.exe only knows this type).

There are the following restrictions:
- the script may have a maximum of 2975 characters (because of Unicode and Base64 encoding and the maximum parameter length of 8192 characters in cmd.exe)
- the execution policy is ignored
- all parameters are handed to the batch files as strings
- if special characters like umlauts are used in the script it has to be UTF8 encoded to preserve the special characters.
- only position parameters are possible for the batch files (no named parameters)
- a maximum of 9 parameters are possible for the batch files
- default values for parameters do not work

## Example
Say you have a script test.ps1 with the following content:

```powershell
$Args
```

Start Powershell, run the following commands (assuming ConvertTo-Batch.ps1 is in the current directory):
```powershell
. .\ConvertTo-Batch.ps1
ConvertTo-Batch .\test.ps1
```

Now you can run the following code on a command prompt:
```bat
test.bat
test.bat Parameter1 "Parameter 2" "Last parameter"
```
