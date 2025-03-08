# Changes

### Version 1.0.39 / 2025-03-08
VirtualDesktop 2.21:
- new commands Pin-ActiveWindow and Unpin-ActiveWindow
- Windows 11: parameter -NoAnimation for Switch-Desktop

Control-IE: Create or close tabs in Internet Explorer
- removed since no longer required

### Version 1.0.38 / 2025-01-05
PS2EXE v0.5.0.31:
- supplements to readme text
- only changes for compatibility with module version of PS2EXE

### Version 1.0.37 / 2024-09-21
VirtualDesktop 2.20:
- faster API call FindWindow instead of EnumWindows
- Windows 11: animated switch to new desktop

### Version 1.0.36 / 2024-09-15
AclInRegistry 1.1:
- Get-AclInRegistry.ps1 shows extended attributes

PS2EXE-GUI v0.5.0.30:
- new parameter -? for compiled executables to show the help of the original Powershell script
- in GUI mode window titles are the application title (when set compiling with parameter -title)

### Version 1.0.35 / 2024-06-29
VirtualDesktop 2.19:
- changes for Win 11 24H2 and fixing of messages

### Version 1.0.34 / 2024-02-22
VirtualDesktop 2.18:
- changes for Win 11 3085 and up

### Version 1.0.33 / 2024-02-03
Powershell Webserver 1.6:
 - parameters can be handed to PSP files per POST method too
 - added wasm extension to mime list

### Version 1.0.32 / 2023-09-26
PS2EXE v0.5.0.29:
- now [ and ] are supported in directory name of script
- source file might be larger than 16 MB (for whoever that needs)
- new addtional parameter text field in Win-PS2EXE

### Version 1.0.31 / 2023-09-21
VirtualDesktop 2.17:
- bug fix for Win 11 Insider Canary
- Remove-AllDesktops for all versions

### Version 1.0.30 / 2023-09-02
VirtualDesktop 2.16:
- bug fix for Win 11 22H2 Build 22621.2215

### Version 1.0.29 / 2023-08-29
VirtualDesktop 2.15:
- integration of Win 11 22H2 Build 22621.2215 and Insider versions
- Remove-AllDesktops without function on Win 11 22H2 Build 22621.2215 and Insider versions (will soon be fixed)

### Version 1.0.28 / 2023-07-23
VirtualDesktop 2.14:
- no flashing icons after switching of desktops

### Version 1.0.27 / 2023-03-27
Powershell Webserver 1.5:
- changed header encoding to Windows 1252 to prevent data loss in cjk encodings
- fixed bug that cut file names with semicolons in it

### Version 1.0.26 / 2023-03-25
Transpose-Object 1.2:
- values of 0, $FALSE or "" not longer identified as $NULL

### Version 1.0.25 / 2023-02-19
VirtualDesktop 2.13:
- support for Windows 11 Insider 25276+

### Version 1.0.24 / 2022-11-25
PS2EXE-GUI v0.5.0.28:
- new parameter -winFormsDPIAware to support scaling for WinForms in noConsole mode (only Windows 10 or up)

### Version 1.0.23 / 2022-11-24
Transpose-Object 1.1:
- workaround for Out-GridView error, select title property, fixed error detecting doubled titles

### Version 1.0.22 / 2022-08-21
GetAllEvents 1.0.1.0:
- omit Security log and events of log level LogAlways per default for overview reasons

### Version 1.0.21 / 2022-08-15
Powershell Webserver 1.4:
- introduced PSP files (Powershell Server Pages) for embedded execution
- updated list of mime types

### Version 1.0.20 / 2022-07-29
VirtualDesktop 2.12:
- bug fix: desktop for pinned windows and apps are recognized

### Version 1.0.19 / 2022-04-15
Powershell Webserver 1.3:
- logs response code
- scripts (.ps1, .bat and .cmd) in web directory are executed by web server

### Version 1.0.18 / 2022-03-13
VirtualDesktop 2.11:
- support for Powershell Core
- support for Windows Server 2022
- support for Windows Terminal

### Version 1.0.17 / 2022-01-21
Powershell Webserver 1.2.2:
- load index file in base dir instead of default page when present

### Version 1.0.16 / 2022-01-04
ExportImportFirewallRules 1.1.1:
- export enum values as string instead of int to JSON files

### Version 1.0.15 / 2021-11-27
VirtualDesktop 2.10:
- support for Windows 11 Insider build 22449 and up

### Version 1.0.14 / 2021-11-21
PS2EXE-GUI v0.5.0.27:
- fixed password longer than 24 characters error
- new parameter -DPIAware to support scaling in noConsole mode
- new parameter -exitOnCancel to stop program execution on cancel in input boxes (only in noConsole mode)

### Version 1.0.13 / 2021-10-22
VirtualDesktop 2.9:
- support for Windows 10 21H2 and Windows 11
- Set-DesktopName works on current virtual desktop if parameter -desktop is missing

### Version 1.0.12 / 2021-07-04
- Powershell Webserver 1.2.1: mime type table updated

### Version 1.0.11 / 2021-04-10
- PS2EXE 0.5.0.26: parameter outputFile now accepts a target folder (without filename)

### Version 1.0.10 / 2021-02-28
PS2EXE 0.5.0.25:
- new parameter UNICODEEncoding to output as UNICODE
- changed parameter debug to prepareDebug
- finally dared to use advanced parameters

VirtualDesktop 2.7:
- fixes for Get-DesktopIndex

### Version 1.0.9 / 2020-12-12
- ExportImportFirewallRules 1.1.0: new parameter -Policystore

### Version 1.0.8 / 2020-11-28
VirtualDesktop 2.6:
- compatible to Powershell Core 7.0 (but not 7.1)
- parameter -PassThru for Set-DesktopName (by sirAndros)

### Version 1.0.7 / 2020-10-24
- PS2EXE 0.5.0.24: refactored

### Version 1.0.6 / 2020-10-14
- ExportImportFirewallRules V1.0.3: default file name for JSON data has extension json now

### Version 1.0.5 / 2020-08-28
- PS2EXE 0.5.0.23: bug fix for simultanous progress bars in one pipeline

### Version 1.0.4 / 2020-08-22
- added Export-FileSegment: Powershell functions to extract and insert binary data from and to files

### Version 1.0.3 / 2020-08-11
PS2EXE 0.5.0.22:
- prompt for choice behaves like Powershell now (console mode only)
- (limited) support for Powershell Core (starts Windows Powershell in the background)
- fixed processing of negative parameter values
- support for animated progress bars (noConsole mode only)

### Version 1.0.2 / 2020-07-11
- PS2EXE 0.5.0.21: nested progress bars

### Version 1.0.1 / 2020-06-27
- Virtualdesktop 2.5: support for virtual desktop names (new in Win 10 2004)

### Version 1.0.0 / 2020-05-07
- initial transfer from Technet Gallery
