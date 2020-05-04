<#
.SYNOPSIS
Modifies permissions stored in registry values
.DESCRIPTION
Modifies permissions stored in registry values, e.g. permissions for the server service, for shares, for
Remote Desktop connections, for the access to services or DCOM applications.
Since the permissions are modified directly in the registry, the responsible service usually does not
notice the change and has to be restarted (or the computer has to be restarted).
.PARAMETER Key
Registry key
.PARAMETER Name
Registry value
.PARAMETER Account
User or group account
.PARAMETER Action
Selected action. GRANT grants the permission, REVOKE revokes the permission, SET sets exactly the chosen
permission. REMOVE removes the access control entry.
.PARAMETER Accessmask
Access as bit mask
.PARAMETER Deny
Allow or deny
.NOTES
Author: Markus Scholtes
Copyright: Markus Scholtes
Version: 1.0
Creation date: 2018/10/08
.EXAMPLE
Set-AclInRegistry.ps1 -Account "Markus" -Accessmask 0x1
Modifies permissions for the access to administrative shares.
A restart of the service LanManServer is necessary (e.g. with Restart-Service Lanmanserver -Force).
.EXAMPLE
Set-AclInRegistry.ps1 -Key "HKLM:\SYSTEM\CurrentControlSet\Services\lanmanserver\DefaultSecurity" -Name "SrvsvcFile" -Account "Power Users" -Action GRANT -AccessMask 0x00000011
Modifies permissions for enumerating and closing open files.
A restart of the service LanManServer is necessary (e.g. with Restart-Service Lanmanserver -Force).
.EXAMPLE
Set-AclInRegistry.ps1 "HKLM:\SYSTEM\CurrentControlSet\Services\lanmanserver\Shares\Security" "MyShare" "$ENV:COMPUTERNAME\Markus" remove
Modifies permissions for the share "MyShare".
A restart of the service LanManServer is necessary (e.g. with Restart-Service Lanmanserver -Force).
.EXAMPLE
Set-AclInRegistry.ps1 "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations" "DefaultSecurity" "DOMAIN\GROUP" SET 0x00000121 -Deny
Modifies default permissions for Remote Desktop connections.
The change applies to all future Remote Desktop connections.
.EXAMPLE
Set-AclInRegistry.ps1 "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\services\BITS\Security" Security "nt authority\interactive" "revoke" 0x0002018d
Modifies permissions for the control of the BITS service. The change applies after restart of the computer.
.EXAMPLE
Set-AclInRegistry.ps1 "HKEY_LOCAL_MACHINE\SOFTWARE\Classes\AppID\{588E10FA-0618-48A1-BE2F-0AD93E899FCC}" "LaunchPermission" "S-1-5-32-547" "Grant" 0xb
Modifies the launch security of the DCOM application "PrintNotify" of Windows 10.
#>
Param([STRING]$Key = "HKLM:\SYSTEM\CurrentControlSet\Services\lanmanserver\DefaultSecurity", [STRING]$Name = "SrvsvcShareAdminConnect",
	[Parameter(Mandatory = $TRUE)]$Account, [ValidateSet("GRANT", "REVOKE", "SET", "REMOVE")][STRING]$Action = "GRANT", [INT]$AccessMask = 0, [SWITCH]$Deny)

# validate parameter -Accessmask
if (($Accessmask -eq 0) -And ($Action -ne "REMOVE"))
{	if ($Action -ne "SET")
	{	# Mask 0 is invalid
		Write-Error "Missing parameter"
		exit
	}
	else
	{	# "SET" with mask 0 gets "REMOVE"
		$Action = "REMOVE"
	}
}

# transformation of the account if it is not already from type SecurityIdentifier
if ($Account -isnot [System.Security.Principal.SecurityIdentifier])
{
	if ($Account -is [System.Security.Principal.NTAccount])
	{ # transform NTAccount
		$Account = $Account.Translate([System.Security.Principal.SecurityIdentifier])
	}
	else
	{
		if ($Account -isnot [STRING])
		{ # no String -> Error
			Write-Error "Invalid account"
			exit
		}
		try
		{ # SID as string
			$Account = New-Object System.Security.Principal.SecurityIdentifier($Account)
		}
		catch
		{ # Accountname as string
			$Account = (New-Object System.Security.Principal.NTAccount($Account)).Translate([System.Security.Principal.SecurityIdentifier])
		}
	}
}

# retrieve account name for outputs
$AccountName = $Account.Translate([System.Security.Principal.NTAccount]).Value

# registry can be a drive or a path, possibly transform to drive
$Key =  $Key -replace "^HKEY_LOCAL_MACHINE", "HKLM:"
# read key
$REGKEY = Get-Item -Path $Key
# read binary value with ACL
$REGBINARY = $REGKEY.GetValue($Name)

# transform binary value to ACL
$SECDESCR = New-Object -TypeName System.Security.AccessControl.CommonSecurityDescriptor -ArgumentList $TRUE, $FALSE, $REGBINARY, 0

# determine the access type
if ($Deny)
{	$AccessType = [System.Security.AccessControl.AccessControlType]::Deny }  # = 1
else
{	$AccessType = [System.Security.AccessControl.AccessControlType]::Allow }  # = 0

# modify DiscretionaryAcl according to -Action
switch ($Action)
{
	"GRANT"
	{ # grant permissions (OR)
		"Granting permissions to $AccountName"
		$SECDESCR.DiscretionaryAcl.AddAccess($AccessType, $Account, $AccessMask, 0, 0)
	}

	"REVOKE"
	{ # revoke permissions (AND NOT)
		"Revoking permissions of $AccountName"
		[VOID]$SECDESCR.DiscretionaryAcl.RemoveAccess($AccessType, $Account, $AccessMask, 0, 0)
	}

	"SET"
	{ # set permissions (overwrite)
		"Setting permissions of $AccountName"
		$SECDESCR.DiscretionaryAcl.SetAccess($AccessType, $Account, $AccessMask, 0, 0)
	}

	"REMOVE"
	{ # remove permissions (delete ACE), is achieved by "revoke full access"
		"Removing permission entry of  $AccountName"
		[VOID]$SECDESCR.DiscretionaryAcl.RemoveAccess($AccessType, $Account, 0xffffffff, 0, 0)
	}
}

# Overwrite SecurityDescriptor in the registry with the new DACL
# generate byte array
$BINDATA = New-Object -TypeName System.Byte[] -ArgumentList $SECDESCR.BinaryLength
# convert SecurityDescriptor to Byte-Array
$SECDESCR.GetBinaryForm($BINDATA, 0)
# and write to registry
Set-ItemProperty -Path $Key -Name $Name -Value $BINDATA


# read in again
$REGKEY = Get-Item -Path $Key
# read binary value with ACL
$REGBINARY = $REGKEY.GetValue($Name)

# transform binary value to ACL
$SECDESCR = New-Object -TypeName System.Security.AccessControl.CommonSecurityDescriptor -ArgumentList $TRUE, $FALSE, $REGBINARY, 0

"New content of the ACL in registry value $Key\$Name`n"

# show owner of the object
$OWNER = ""
try { $OWNER = $SECDESCR.Owner.Translate([System.Security.Principal.NTAccount]).Value } catch { }
"Owner: $OWNER ($($SECDESCR.Owner.Value))"

# show group of the object
$GROUP = ""
try { $GROUP = $SECDESCR.Group.Translate([System.Security.Principal.NTAccount]).Value } catch { }
"Group: $GROUP ($($SECDESCR.Group.Value))`n"

# iterate over ACEs in ACL and show ACLs
$SECDESCR.DiscretionaryAcl | % {
	$ACCOUNT = ""
	try { $ACCOUNT = $_.SecurityIdentifier.Translate([System.Security.Principal.NTAccount]).Value } catch { }
	"$($_.Acetype.ToString()): $ACCOUNT ($($_.SecurityIdentifier.Value)) - $("0x{0:x8}" -f $_.AccessMask)"
}
