<#
.SYNOPSIS
Shows permissions stored in registry values
.DESCRIPTION
Shows permissions stored in registry values, e.g. permissions for the server service, for shares, for
Remote Desktop connections, for the access to services or DCOM applications.
.PARAMETER Key
Registry key
.PARAMETER Name
Registry value
.NOTES
Author: Markus Scholtes
Copyright: Markus Scholtes
Version: 1.0
Creation date: 2018/10/08
.EXAMPLE
Get-AclInRegistry.ps1
Shows permissions for the access to administrative shares.
.EXAMPLE
Get-AclInRegistry.ps1 -Key "HKLM:\SYSTEM\CurrentControlSet\Services\lanmanserver\DefaultSecurity" -Name "SrvsvcFile"
Shows permissions for enumerating and closing open files.
.EXAMPLE
Get-AclInRegistry.ps1 "HKLM:\SYSTEM\CurrentControlSet\Services\lanmanserver\Shares\Security" "MyShare"
Shows permissions for the share "MyShare".
.EXAMPLE
Get-AclInRegistry.ps1 "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations" "DefaultSecurity"
Shows default permissions for Remote Desktop connections.
.EXAMPLE
Get-AclInRegistry.ps1 "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\services\BITS\Security" Security
Shows permissions for the control of the BITS service.
.EXAMPLE
Get-AclInRegistry.ps1 "HKEY_LOCAL_MACHINE\SOFTWARE\Classes\AppID\{588E10FA-0618-48A1-BE2F-0AD93E899FCC}" "LaunchPermission"
Shows the launch security of the DCOM application "PrintNotify" of Windows 10.
#>
Param([STRING]$Key = "HKLM:\SYSTEM\CurrentControlSet\Services\lanmanserver\DefaultSecurity", [STRING]$Name = "SrvsvcShareAdminConnect")

# registry can be a drive or a path, possibly transform to drive
$Key =  $Key -replace "^HKEY_LOCAL_MACHINE", "HKLM:"
# read key
$REGKEY = Get-Item -Path $Key
# read binary value with ACL
$REGBINARY = $REGKEY.GetValue($Name)

# transform binary value to ACL
$SECDESCR = New-Object -TypeName System.Security.AccessControl.CommonSecurityDescriptor -ArgumentList $TRUE, $FALSE, $REGBINARY, 0

"Content of the ACL in registry value $Key\$Name`n"

# show owner of ACL
$OWNER = ""
try { $OWNER = $SECDESCR.Owner.Translate([System.Security.Principal.NTAccount]).Value } catch { }
"Owner: $OWNER ($($SECDESCR.Owner.Value))"

# show group of ACL
$GROUP = ""
try { $GROUP = $SECDESCR.Group.Translate([System.Security.Principal.NTAccount]).Value } catch { }
"Group: $GROUP ($($SECDESCR.Group.Value))`n"

# iterate over ACEs in ACL and show ACLs
$SECDESCR.DiscretionaryAcl | % {
	$ACCOUNT = ""
	try { $ACCOUNT = $_.SecurityIdentifier.Translate([System.Security.Principal.NTAccount]).Value } catch { }
	"$($_.Acetype.ToString()): $ACCOUNT ($($_.SecurityIdentifier.Value)) - $("0x{0:x8}" -f $_.AccessMask)"
}
