<#
.SYNOPSIS
Opens new Internet Explorer tab with given URL
.DESCRIPTION
Opens new Internet Explorer tab with given URL. When no Internet Explorer is already running, a new instance will be created.
The script can also close tabs or return a COM object for a tab on demand.
.PARAMETER URL
URL to open (or part of URL to close for parameter -Close)
.PARAMETER Close
All Internet Explorer tabs with URLs that match the parameter URL will be closed.
.PARAMETER Passthru
Return COM object to opened tab
.INPUTS
STRING
.OUTPUTS
System.__ComObject with parameter -Close
.NOTES
Name: Add-IETab.ps1
Author: Markus Scholtes
Creation Date: 13.06.2016
.LINK
https://gallery.technet.microsoft.com/scriptcenter/Create-or-close-tabs-in-cc6a4e39
.EXAMPLE
.\Add-IETab.ps1 "www.google.com"
Opens Internet Explorer tab with google search
.EXAMPLE
.\Add-IETab.ps1 "google" -Close
Closes all Internet Explorer tabs with google search
.EXAMPLE
$oIE = .\Add-IETab.ps1 "www.google.com" -Passthru
Opens Internet Explorer tab with google search and returns COM object of it
#>
param([STRING][Parameter(ValueFromPipeline=$TRUE)] $URL = "about:blank", [SWITCH] $Close, [SWITCH] $Passthru)


# create object "Shell.Application" and get window list
$oWindows = (New-Object -ComObject Shell.Application).Windows

$IEexists = $FALSE
if ($Passthru) { $TIMESTAMP = (Get-Date).ToString() }

# only if window present
if ($oWindows.Invoke().Count -gt 0)
{ # check every window
	foreach ($oWindow in $oWindows.Invoke())
	{
		# only windows of Internet Explorer
		if ($oWindow.Fullname -match "IEXPLORE.EXE")
		{
			if ($Close)
			{ # close tab
				# does Internet Explorer tab match this URL?
				if ($oWindow.LocationURL -match $URL)
				{
					# URL found
					$IEexists = $TRUE
					# close tab
					Write-Host "Closing tab $($oWindow.LocationURL)"
					$oWindow.Quit()
				}
			}
			else
			{ # create tab
				if (!$IEexists)
				{ # get COM object of existing Internet Explorer
					$oIE = $oWindow
					$IEexists = $TRUE
					if (!$Passthru)
					{ break }
				}
				if ($Passthru)
				{ # mark window to recognize as existing window later
					$oWindow.PutProperty($TIMESTAMP, $TIMESTAMP)
				}
			}
		}
	}
}

if ($IEexists)
{ # existing Internet Explorer found
	if (!$Close)
	{ # add tab
		Write-Host "Creating Internet Explorer tab with URL $URL."
		# navOpenInNewTab = 0x800
		# navOpenInBackgroundTab = 0x1000
		# navOpenNewForegroundTab = 0x10000
	  # create new foreground tab
	  $oIE.Navigate2($URL, 0x10000)
	}
}
else
{
	if ($Close)
	{ # no tab to close found
		Write-Host "No Internet Explorer tab with URL $URL found."
	}
	else
	{ # existing Internet Explorer found, creating new instance
		Write-Host "Creating Internet Explorer instance with URL $URL."
		$oIE = New-Object -ComObject "InternetExplorer.Application"
  	$oIE.Navigate2($URL)
  	while ($oIE.Busy) { sleep -Milliseconds 50 }
  	$oIE.visible = $TRUE
  }
}

if ($Passthru -and !$Close)
{ # to return the correct window handle we have to enumerate windows once again
	# and return the object of the tab we did not mark at the beginning of the script

	# give time to rebuild window list
	Sleep 1

	# create object "Shell.Application" and get window list
	$oWindows = (New-Object -ComObject Shell.Application).Windows

	# only if window present
	if ($oWindows.Invoke().Count -gt 0)
	{ # check every window
		foreach ($oWindow in $oWindows.Invoke())
		{
			# only windows of Internet Explorer
			if ($oWindow.Fullname -match "IEXPLORE.EXE")
			{ # check for mark
				if ($oWindow.GetProperty($TIMESTAMP) -eq $TIMESTAMP)
				{ # remove mark
					$oWindow.PutProperty($TIMESTAMP, $NULL)
				}
				else
				{ # no mark found, this has to be the new window
					$oIE = $oWindow
				}
			}
		}
	}
	# return COM object
	return $oIE
}
