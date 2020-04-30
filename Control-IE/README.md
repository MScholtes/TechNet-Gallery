# Create or close tabs in Internet Explorer
With the COM interface and DOM you can control the browser Internet Explorer. I made a - for me - useful script to start a new Internet Explorer tab from powershell or close an existing tab.

Since Technet Gallery will be closed, now here.

See Script Center version: [Create or close tabs in Internet Explorer](https://gallery.technet.microsoft.com/scriptcenter/Create-or-close-tabs-in-cc6a4e39).

## Examples:
Assuming the script is in the current directory, you can start a new google tab with
```powershell
.\Add-IETab.ps1 www.google.com
```
If no Internet Explorer instance is running, a new one is started.


You can close all google tabs with
```powershell
.\Add-IETab.ps1 google -Close
```

You can start a new MSDN tab and retrieve the COM object with
```powershell
$oIE = .\Add-IETab.ps1 https://msdn.microsoft.com/en-us -Passthru
```
Then you can click on all links containing text "Windows Server" with
```powershell
$oIE.Document.getElementsByTagName("a") | foreach { 
    if ($_.textContent -match "windows server")  
    { 
        $_.Click() 
    } 
}
```
(on error see remarks below)

## Extras:
I added two fun scripts to annoy your colleagues :-) when run in the background on their computers.

Here are examples:

```powershell
.\ClickInIETabs.ps1 "scriptcenter" "Downloads"
```
clicks on links with title "Downloads" in all Internet Explorer tabs whose URL contain "scriptcenter"

```powershell
.\CloseIETabs.ps1 "google","bing"
```
closes all open Internet Explorer tabs with google and bing pages.

Both fun scripts run endlessly and wait for a fitting tab to act on until a key is pressed.


## Remarks:
* On some computers the typelib for IE DOM seems to be missing. I do not know the reason for it (security???).
In this case you have to use
```powershell
@([System.__ComObject].InvokeMember("getElementsByTagName",[System.Reflection.BindingFlags]::InvokeMethod, $null, $oIE.Document, "a"))
```
instead of
```powershell
$oIE.Document.getElementsByTagName("a")
```
in the example above.

Hints for the reason und for solutions to this problem are very welcome.

* The IE COM implementation seems not very stable to me.
Sometimes the script does not return a working object with -Passthru, sometimes you have to start the script twice before a tab is opened.

I guess it has something to do with compatibility mode, 64 bit to 32 bit and integrity level transitions.
Hints, explanations and solutions are very welcome too.
