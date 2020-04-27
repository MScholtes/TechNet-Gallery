# Inputbox for Powershell
With [System.Windows.Forms.MessageBox]::Show(...) you can display a messagebox in every powershell script, but a function to display an inputbox is missing. So I wrote this small c# class InputBox for it.

Since Technet Gallery will be closed, now here.

See Script Center version: [Inputbox for Powershell](https://gallery.technet.microsoft.com/Inputbox-for-Powershell-6ac0741d).

## Description
The class InputBox features:
* automatic resizing to text sizes
* default value
* input of passwords
* returns the pressed button and the input (in a referenced variable)

## Remarks:
There's no need for dot sourcing the script cause it adds a type.

The referenced variable has to be declared or set before calling.

## Examples:
all the examples assume the script is in the current directory

```powershell
.\Start-InputBox.ps1
$Value = "default value"
if ([InputBox]::Show([ref] $Value, "Title to display", "Type in a text please") -eq "OK") { $Value } else { "Cancelled" }
```

```powershell
.\Start-Inputbox.ps1
New-Variable PASS -Force
if ([InputBox]::Show([ref]$PASS, "", "Need password:", $TRUE) -eq "OK") { "Password stored" } else { "Cancel" }
```

```powershell
.\Start-InputBox.ps1
New-Variable Inp -Force
[InputBox]::Show([ref] $Inp)
```
