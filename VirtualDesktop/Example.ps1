. "$PSScriptRoot\VirtualDesktop.ps1"

"Number of virtual desktops: $(Get-DesktopCount)"

Sleep 1

"Create a new desktop:"
$NewDesktop = New-Desktop
$OldDesktop = Get-CurrentDesktop

"Number of virtual desktops: $(Get-DesktopCount)"
"Number of new desktop: $(Get-DesktopIndex($NewDesktop))"
"Name of new desktop: $(Get-DesktopName($NewDesktop))"

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
Remove-Desktop $OldDesktop -Verbose

"Number of virtual desktops: $(Get-DesktopCount)"

Sleep 1

# function by ComFreek (https://github.com/ComFreek)
function Request-NamedDesktop {
	<#
		.SYNOPSIS
			Retrieves or creates (if non-existing) the virtual desktop with the given name.

		.INPUTS
			The desktop name can be piped into this function.

		.OUTPUTS
			A virtual desktop with the given name.

		.EXAMPLE
			Request-NamedDesktop "My Secret Desktop"
		.EXAMPLE
			"My Secret Desktop" | Request-NamedDesktop | Switch-Desktop

		.NOTES
			The function assumes that the PSVirtualDesktop module [0] is installed.

			[0]: https://github.com/MScholtes/PSVirtualDesktop
	#>
	param(
		<#
			The name of the virtual desktop to retrieve or create (if non-existing)
		#>
		[Parameter(Mandatory=$true, ValueFromPipeline=$true)]
		[ValidateNotNullOrEmpty()]
		[string]$name
	)

	$desktop = Get-DesktopList | Where-Object Name -eq $name | Select-Object -First 1

	# The if condition below is susceptible to a TOCTOU bug (https://en.wikipedia.org/wiki/Time-of-check_to_time-of-use).
	# But this is probably okay since virtual desktops aren't something that is created every second.
	if ($desktop) {
		Get-Desktop -Index $desktop.Number
	} else {
		$desktop = New-Desktop
		$desktop | Set-DesktopName -Name $name
		$desktop
	}
}

"Create virtual desktop 'Games' if it does not already exist"
Request-NamedDesktop "Games"
