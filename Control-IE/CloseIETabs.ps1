# Markus Scholtes, 2016
# checks the open Internet Explorer windows for tabs with given URLs and closes them
# Example:
# .\CloseIETabs.ps1 "google","bing"
# Closes Internet Explorer tabs with google and bing pages

param([ARRAY] $URLList)

# create object "Shell.Application" and get window list
$oWindows = (New-Object -ComObject Shell.Application).Windows

# empty keyboard buffer
while ($host.UI.RawUI.KeyAvailable)
{	$host.UI.RawUI.ReadKey("IncludeKeyup,NoEcho") | Out-Null }

while (!$host.UI.RawUI.KeyAvailable)
{ # endless loop 'til a key pressed

	# only if window present
	if ($oWindows.Invoke().Count -gt 0)
	{
		# check every window
		foreach ($oWindow in $oWindows.Invoke())
		{
			# only windows of Internet Explorer
			if ($oWindow.Fullname -match "IEXPLORE.EXE")
			{
				# check URL list
				foreach ($URL in $URLList)
				{
					# does Internet Explorer tab match this URL?
					if ($oWindow.LocationURL -match $URL)
					{
						# URL found
						# close tab
						Write-Host "Closing tab $($oWindow.LocationURL)"
						$oWindow.Quit()
					}
				}
			}
		}
	}
	# wait for 1 second
	Start-Sleep 1
}

# remove key out of buffer
[VOID]$host.UI.RawUI.Readkey("NoEcho,IncludeKeyUp")

# free shell object
$oWindows = $NULL
