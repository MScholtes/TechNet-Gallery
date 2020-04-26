. "$PSScriptRoot\VirtualDesktop.ps1"

"Number of virtual desktops: $(Get-DesktopCount)"

Sleep 1

"Create a new desktop:"
$NewDesktop = New-Desktop
$OldDesktop = Get-CurrentDesktop

"Number of virtual desktops: $(Get-DesktopCount)"
"Number of new desktop: $(Get-DesktopIndex($NewDesktop))"

Sleep 1

"Switch to new desktop, start notepad there and switch back"

Sleep 1

$NewDesktop | Switch-Desktop
notepad
Sleep 1
Switch-Desktop $OldDesktop
Sleep 1

"Move notepad to current desktop"
(ps notepad)[0].MainWindowHandle | Move-Window (Get-CurrentDesktop) | Out-Null

Sleep 1

"Move powershell window to new desktop and switch to it"
$NewDesktop | Move-Window (Get-ConsoleHandle) | Switch-Desktop

Sleep 1

"Pin notepad window to all desktops"
Pin-Window ((Get-Process "notepad")[0].MainWindowHandle)

Sleep 1

"Remove original desktop"
Remove-Desktop $OldDesktop

"Number of virtual desktops: $(Get-DesktopCount)"

Sleep 1
