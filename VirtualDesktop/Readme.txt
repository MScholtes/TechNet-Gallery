Virtualdesktop.ps1		by Markus Scholtes, 2023

Powershell commands to manage virtual desktops of Windows 10 and Windows 11



Windows 10 introduced a great new feature with virtual desktops, but missed to
document a programming interface to manage virtual desktops from a script or
program. This set of powershell commands helps out and lets you control virtual
desktops from scripts.

Now with support for Windows 11 including Insider!
Now with support for Windows Server 2022!
Now with support for Powershell Core!
Now with support for Windows Terminal!

Update 2.15:
integration of Win 11 22H2 Build 22621.2215 and Insider versions
Remove-AllDesktops without function on Win 11 22H2 Build 22621.2215 and Insider versions (will soon be fixed)
Update 2.14:
no flashing icons after switch desktops
Update 2.13:
support for Windows 11 Insider 25276+
Update 2.12:
bug fix: desktop for pinned windows and apps are recognized
Update 2.11:
support for Powershell Core
support for Windows Server 2022
support for Windows Terminal
Update 2.10:
support for Windows 11 Insider build 22449 and up
Update 2.9:
support for Windows 10 21H2 and Windows 11
Update 2.8:
integrating fixes from VirtualDesktop.cs
Update 2.7:
fixes for Get-DesktopIndex
Update 2.6:
compatible to Powershell Core 7.0 (but not 7.1 or up)
parameter -PassThru for Set-DesktopName (by sirAndros)
Update 2.5:
support for desktop names introduced with Win 10 2004
new functions Get-DesktopList, Get-DesktopName and Set-DesktopName
desktop name as parameter for many functions
support for verbose output
Update 2.4: new function Find-WindowHandle
Minor Update 2.3.1: fixed examples
Update 2.3: fixed COM interface error with Pin-Application
Update 2.2: new commands Move-ActiveWindow and Get-ActiveWindowHandle
Minor Update 2.1.1: support for ISE (Get-ConsoleHandle) and RunSpaces (Windows version checking)
Update 2.1: Support for Windows 10 1809
Update 2.0: Support for Windows 10 1803



Sample session:

# Load commands (assumes VirtualDesktop.ps1 is in the current path)
. .\VirtualDesktop.ps1

# Create a new virtual desktop and switch to it
New-Desktop | Switch-Desktop

# Create a new virtual desktop and name it (only on Win 10 2004 or up)
New-Desktop | Set-DesktopName -Name "The new one"

# Get second virtual desktop (count starts with 0) and remove it
Get-Desktop 1 | Remove-Desktop -Verbose

# Retrieves the count of virtual desktops
Get-DesktopCount

# Show list of virtual desktops
Get-DesktopList

# Move notepad window to current virtual desktop
(ps notepad)[0].MainWindowHandle | Move-Window (Get-CurrentDesktop) | Out-Null

# Move powershell window to last virtual desktop and switch to it
Get-Desktop ((Get-DesktopCount)-1) | Move-Window (Get-ConsoleHandle) | Switch-Desktop

# Retrieve virtual desktop on which notepad runs and switch to it
Get-DesktopFromWindow ((Get-Process "notepad")[0].MainWindowHandle) | Switch-Desktop

# Pin notepad to all desktops
Pin-Window ((Get-Process "notepad")[0].MainWindowHandle)



Remarks:
For a C# implementation look here: https://github.com/MScholtes/VirtualDesktop

The API is not or rarely documented by Microsoft. So there is a risk Microsoft
changes the API with an os update and this script will then not work anymore
(Microsoft did so already with anniversary update, 1803, 1809, Server 2022 and Windows 11).




List of commands:
(for most of the functions you can hand the parameter as parameter or through the pipeline)
In most commands you can use a desktop object, the desktop number or a part of the desktop name as parameter desktop, see online help for more information.


Get-DesktopCount
Get count of virtual desktops

Get-DesktopList
Show list of virtual desktops

New-Desktop
Create virtual desktop. Returns desktop object.

Switch-Desktop -Desktop desktop
Switch to virtual desktop. Parameter is number of desktop (starting with 0 to count-1) or desktop object.

Remove-Desktop -Desktop desktop
Remove virtual desktop. Parameter is number of desktop (starting with 0 to count-1) or desktop object.
Windows on the desktop to be removed are moved to the virtual desktop to the left except for desktop 0 where the
second desktop is used instead. If the current desktop is removed, this fallback desktop is activated too.
If no parameter is supplied, the last desktop is removed.

Remove-AllDesktops
Remove all virtual desktops but visible. Works only with Windows 11.

Get-CurrentDesktop
Get current virtual desktop as desktop object.

Get-Desktop -Index index
Get virtual desktop with index number (0 to count-1). Returns desktop object.

Get-DesktopIndex -Desktop desktop
Get index number (0 to count-1) of virtual desktop. Returns integer or -1 if not found.

Get-DesktopName -Desktop desktop
Get name of virtual desktop. Returns string.

Set-DesktopName -Desktop desktop -Name name -PassThru
Set name of virtual desktop to name. Works only with Windows 10 2004 or up.

Set-DesktopWallpaper -Desktop desktop -Path path -PassThru
Set wallpaper of virtual desktop to path. Works only with Windows 11.

Set-AllDesktopWallpapers -Path path
Set wallpaper of all virtual desktops to path. Works only with Windows 11.

Get-DesktopFromWindow -Hwnd hwnd
Get virtual desktop of window (whose window handle is passed). Returns desktop object.

Test-CurrentDesktop -Desktop desktop
Checks whether a desktop is the currently displayed virtual desktop. Returns boolean.

Get-LeftDesktop -Desktop desktop
Get the desktop object on the "left" side. If there is no desktop on the "left" side $NULL is returned.
Returns desktop "left" to current desktop if parameter desktop is omitted.

Get-RightDesktop -Desktop desktop
Get the desktop object on the "right" side.If there is no desktop on the "right" side $NULL is returned.
Returns desktop "right" to current desktop if parameter desktop is omitted.

Move-Desktop -Desktop desktop
Move current desktop to other virtual desktop. Works only with Windows 11.

Move-Window -Desktop desktop -Hwnd hwnd
Move window whose handle is passed to virtual desktop.
The parameter values are auto detected and can change places. The desktop object is handed to the output pipeline for further use.
If parameter desktop is omitted, the current desktop is used.

Move-ActiveWindow -Desktop desktop
Move active window to virtual desktop.
The desktop object is handed to the output pipeline for further use.
If parameter desktop is omitted, the current desktop is used.

Test-Window -Desktop desktop -Hwnd hwnd
Check if window whose handle is passed is displayed on virtual desktop. Returns boolean.
The parameter values are auto detected and can change places. If parameter desktop is not supplied, the current desktop is used.

Pin-Window -Hwnd hwnd
Pin window whose window handle is given to all desktops.

Unpin-Window -Hwnd hwnd
Unpin window whose window handle is given to all desktops.

Test-WindowPinned -Hwnd hwnd
Checks whether a window whose window handle is given is pinned to all desktops. Returns boolean.

Pin-Application -Hwnd hwnd
Pin application whose window handle is given to all desktops.

Unpin-Application -Hwnd hwnd
Unpin application whose window handle is given to all desktops.

Test-ApplicationPinned -Hwnd hwnd
Checks whether an application whose window handle is given is pinned to all desktops. Returns boolean.

Get-ConsoleHandle
Get window handle of powershell console in a safe way (means: if powershell is started in a cmd window, the cmd window handle is returned).

Get-ActiveWindowHandle
Get window handle of foreground window (the foreground window is always on the current virtual desktop).

Find-WindowHandle
Find first window handle to title text or retrieve list of windows with title (when called with '*' as parameter)
