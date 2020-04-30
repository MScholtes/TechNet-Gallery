# Markus Scholtes, 2016
# checks the open Internet Explorer windows for tabs with given URLs and clicks on links in them to a given title
# Example:
# .\ClickInIETabs.ps1 "wikipedia" "Portal.Geogra"
# Clicks on links to the geography startpage in Wikipedia pages

param([ARRAY] $URLList, [STRING] $Search)

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
						# check links in web page for title search string
						@([System.__ComObject].InvokeMember("getElementsByTagName",[System.Reflection.BindingFlags]::InvokeMethod, $null, $oWindow.Document, "a")) | foreach {
#						$oWindow.Document.getElementsByTagName("a") | foreach {
							if ($_.title -match $Search) 
							{ # found a link for search string
								Write-Output "Clicking on link $($_.title) in tab $($oWindow.LocationURL)"
								$_.Click()
							}
						}
					}
				}
			}
		}
	}
	# wait for 2 seconds
	Start-Sleep 2
}

# remove key out of buffer
[VOID]$host.UI.RawUI.Readkey("NoEcho,IncludeKeyUp")

# free shell object
$oWindows = $NULL
