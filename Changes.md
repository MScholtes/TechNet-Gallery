# Changes

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
