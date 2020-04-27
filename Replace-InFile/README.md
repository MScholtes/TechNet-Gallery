# Replace-InFile.ps1: Replace text in files while preserving the encoding
Replace-InFile.ps1 is a Powershell script I made to replace text in files programmatically without getting a mess with the text encodings.

Since Technet Gallery will be closed, now here.

See Script Center version: [Replace-InFile.ps1: Replace text in files while preserving the encoding](https://gallery.technet.microsoft.com/Replace-InFileps1-Replace-1e0be31a).

Now also on Powershell Gallery as part of the **SysAdminsFriends** module, see [here](https://www.powershellgallery.com/packages/SysAdminsFriends/) or install with
```powershell
Install-Module SysAdminsFriends
```

Project page on github is [here](https://github.com/MScholtes/SysAdminsFriends).

## Description
Replace-InFile.ps1 is a Powershell script I made to replace text in files programmatically without getting a mess with the text encodings.

The script detects the encoding of each processed file and writes it back with the same encoding.

## Examples:
all the examples assume the script is found in the path

Replaces "Mister" with "Lady" in the content of the file "Test.txt" and writes the result to result.txt:
```powershell
Replace-InFile.ps1 -Pattern "Mister" -Replacement "Lady" -Path Test.txt -Quiet > result.txt
```

Replaces the expression "spät" with "später" in all files of the current directory and all subdirectories.

The search is case-sensitive. ASCII files are interpreted as OEM files.

The result is not written back to the files, but is output to the pipeline:
```powershell
gci | Replace-InFile.ps1 -Pattern "spät" -Replacement "später" -CaseSensitive -Recurse -OEM
```

Replaces t at the end of the line with T in all txt files of the current directory.

The files are written in UNICODE encoding:
```powershell
Get-ChildItem "*.txt" | Replace-InFile.ps1 -Pattern "t$" -Replacement "T" -Encoding UNICODE -Overwrite
```

Removes the expression "away" in all txt files of the current directory, preserving the time stamp of the files.

No change is made because of the switch -WhatIf:
```powershell
Replace-InFile.ps1 -Pattern "away" -Path "*.txt" -Overwrite -PreserveDate -WhatIf
```
