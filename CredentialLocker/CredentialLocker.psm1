<#
.SYNOPSIS
CredentialLocker is a module that provides commandlets to manage credentials in the password vault.
.NOTES
Version: 1.0.0
Date: 2019-09-10
Author: Markus Scholtes
#>

#Requires -Version 3.0

# Load assembly
[VOID][Windows.Security.Credentials.PasswordVault,Windows.Security.Credentials,ContentType=WindowsRuntime]


function Get-VaultCredential
{
<#
.SYNOPSIS
Retrieves credentials stored in the password vault searched by resource and/or user name.
.DESCRIPTION
Retrieves credentials stored in the password vault searched by resource and/or user name. If a password cannot
be resolved a space is returned as password. If a credential does not exist $NULL is returned.
.PARAMETER Resource
Name of the resource to find
.PARAMETER UserName
Username to find
.EXAMPLE
Get-VaultCredential "https://github.com/"

Retrieves stored user name(s) and password(s) for GitHub if credential exists
.LINK
https://gallery.technet.microsoft.com/scriptcenter/Powershell-Module-f0f91920
.NOTES
Author: Markus Scholtes
Created: 2019/09/10
#>
	Param([Parameter(ValueFromPipeline = $TRUE,ValueFromPipelineByPropertyName = $TRUE)][STRING]$Resource = $NULL, [STRING]$UserName = $NULL)

	if ((!$Resource) -And (!$UserName))
	{
		Write-Error "Resource or user name has to be provided."
		return $NULL
	}
	# connect to password vault
	$VAULT = New-Object Windows.Security.Credentials.PasswordVault

	try {
		# retrieve all credentials, filter manually and unhide passwords
		# do not use FindAllByResource() and FindAllByUserName() since it is case sensitive
		$CREDENTIALS = $VAULT.RetrieveAll() | ? { ($_.Resource -match $Resource) -And ($_.UserName -match $UserName) } | %{ $_.RetrievePassword(); $_ }
		return $CREDENTIALS
	}
	catch
	{
		Write-Error "Error retrieving credentials"
		return $NULL
	}
}


function Show-VaultCredentials
{
<#
.SYNOPSIS
List all credentials stored in the password vault.
.DESCRIPTION
List all credentials stored in the password vault. If a password cannot be resolved a space is returned as
password.
.EXAMPLE
Show-VaultCredentials

Lists all credentials stored in the current user's password vault.
.LINK
https://gallery.technet.microsoft.com/scriptcenter/Powershell-Module-f0f91920
.NOTES
Author: Markus Scholtes
Created: 2019/09/10
#>
	Param([Parameter(ValueFromPipeline = $TRUE,ValueFromPipelineByPropertyName = $TRUE)][ValidateNotNullOrEmpty()][STRING]$Resource)

	# connect to password vault
	$VAULT = New-Object Windows.Security.Credentials.PasswordVault
	try {
		# retrieve all credentials and unhide passwords
		$CREDENTIALS = $VAULT.RetrieveAll() | %{ $_.RetrievePassword(); $_ }
		return $CREDENTIALS
	}
	catch
	{
		Write-Error "Error retrieving credentials"
		return $NULL
	}
}


function Add-VaultCredential
{
<#
.SYNOPSIS
Adds a credential to the password vault.
.DESCRIPTION
Adds a credential to the password vault. A resource, user name and password can be indicated or alternatively
a password vault credential object.
.PARAMETER Credential
A password vault credential object
.PARAMETER Resource
Resource for the credential (URL or application name).
.PARAMETER UserName
The user name for the credential
.PARAMETER Password
The password for the credential
.PARAMETER IE
Generate web credential for browsers Internet Explorer or Edge (same as -Edge)
.PARAMETER Edge
Generate web credential for browsers Internet Explorer or Edge (same as -IE)
.PARAMETER ApplicationId
Set application id for credential
.PARAMETER Application
Set application name for credential
.PARAMETER HIDE
Hide credential in control panel (it will not be not hidden in Powershell)
.EXAMPLE
Add-VaultCredential -Resource "MyApp" -UserName "Logon" -Password "P@ssw0rd"

Add a credential for a custom application
.EXAMPLE
Add-VaultCredential -Resource "https://www.outlook.com/" -UserName "fakeuser@microsoft.com" -Password "P@ssw0rd" -EDGE

Add a credential for a website login with Edge or Internet Explorer
.EXAMPLE
Get-Credential | ConvertTo-VaultCredential -Resource "MyApp" | Add-VaultCredential -Application "MyApp"

Show a dialog to obtain a Powershell credential, convert it to a password vault credential and store it in the password vault
.LINK
https://gallery.technet.microsoft.com/scriptcenter/Powershell-Module-f0f91920
.NOTES
Author: Markus Scholtes
Created: 2019/09/10
#>
	[CmdletBinding(DefaultParameterSetName = "STRINGS")]
	Param(
		[Parameter(ParameterSetName = "CREDENTIAL",Position = 0,ValueFromPipeline = $TRUE,ValueFromPipelineByPropertyName = $TRUE)][ValidateNotNullOrEmpty()][Windows.Security.Credentials.PasswordCredential]$Credential,
		[Parameter(ParameterSetName = "STRINGS",Position = 0,ValueFromPipeline = $TRUE,ValueFromPipelineByPropertyName = $TRUE)][ValidateNotNullOrEmpty()][STRING]$Resource,
		[Parameter(ParameterSetName = "STRINGS",Position = 1)][ValidateNotNullOrEmpty()][STRING]$UserName,
		[Parameter(ParameterSetName = "STRINGS",Position = 2)][ValidateNotNullOrEmpty()][STRING]$Password,
		[SWITCH]$IE, [SWITCH]$Edge, [STRING]$ApplicationId, [STRING]$Application, [SWITCH]$Hide
	)

	# connect to password vault
	$VAULT = New-Object Windows.Security.Credentials.PasswordVault

	try {
		if ($PSCmdlet.ParameterSetName -eq "STRINGS")
		{ # create new Credential
			$CREDENTIAL = New-Object Windows.Security.Credentials.PasswordCredential($Resource, $UserName, $Password)
		}

		if ($IE -or $Edge)
		{ # set properties to mark as credential for Edge and IE
			$CREDENTIAL.Properties.set_item("application", "Internet Explorer")
			$CREDENTIAL.Properties.set_item("applicationid", (New-Object Guid("4e3cb6d5-2556-4cd8-a48d-c755c737cba6")))
		}
		if ($ApplicationId)
		{ # set ApplicationId for credential
			$CREDENTIAL.Properties.set_item("applicationid", (New-Object Guid($ApplicationId)))
		}
		if ($Application)
		{ # set Application for credential
			$CREDENTIAL.Properties.set_item("application", $Application)
		}
		if ($Hide)
		{ # hide credential in control panel
			$CREDENTIAL.Properties.set_item("hidden", $TRUE)
		}

		# add new credential to vault
		$VAULT.Add($CREDENTIAL)

		Write-Output "Credential of user $($CREDENTIAL.UserName) for resource $($CREDENTIAL.Resource) stored."
	}
	catch
	{
		Write-Error "Error storing credential of user $($CREDENTIAL.UserName) for resource $($CREDENTIAL.Resource)."
	}
}


function Remove-VaultCredential
{
<#
.SYNOPSIS
Removes credentials from the password vault.
.DESCRIPTION
Removes credentials from the password vault. A resource, user name and password can be indicated or alternatively
a password vault credential object.
.PARAMETER Credential
A password vault credential object to remove
.PARAMETER Resource
The resource for which credentials are removed
.PARAMETER UserName
The user name for which credentials are removed
.EXAMPLE
Remove-VaultCredential -Resource "https://github.com/"

Removes all credentials for github web page
.EXAMPLE
Remove-VaultCredential -UserName "logonname"

Removes all credentials for user name "logonname"
.EXAMPLE
Remove-VaultCredential -Resource "https://github.com/" -UserName "logonname"

Removes credential for user name "logonname" on github web page
.EXAMPLE
Get-VaultCredential -Resource "https://github.com/" -UserName "logonname" | Remove-VaultCredential

Removes credential for user name "logonname" on github web page (same effect as example above)
.LINK
https://gallery.technet.microsoft.com/scriptcenter/Powershell-Module-f0f91920
.NOTES
Author: Markus Scholtes
Created: 2019/09/10
#>
	[CmdletBinding(DefaultParameterSetName = "STRINGS")]
	Param(
		[Parameter(ParameterSetName = "CREDENTIAL",Position = 0,ValueFromPipeline = $TRUE,ValueFromPipelineByPropertyName = $TRUE)][ValidateNotNullOrEmpty()][Windows.Security.Credentials.PasswordCredential]$Credential,
		[Parameter(ParameterSetName = "STRINGS",Position = 0,ValueFromPipeline = $TRUE,ValueFromPipelineByPropertyName = $TRUE)][STRING]$Resource = $NULL,
		[Parameter(ParameterSetName = "STRINGS",Position = 1)][STRING]$UserName = $NULL
	)

	if ($PSCmdlet.ParameterSetName -eq "STRINGS")
	{ if ((!$Resource) -And (!$UserName))
		{
			Write-Error "Resource or Username has to be provided."
			return $NULL
		}
	}
	else
	{ # the parameter was a password vault credential
		$Resource = $Credential.Resource
		$UserName = $Credential.UserName
	}
	# connect to password vault
	$VAULT = New-Object Windows.Security.Credentials.PasswordVault

	try {
		# retrieve all credentials and filter manually
		# do not use FindAllByResource() and FindAllByUserName() since it is case sensitive
		$CREDENTIALS = $VAULT.RetrieveAll() | ? { ($_.Resource -match $Resource) -And ($_.UserName -match $UserName) }
		$CREDENTIALS | % {
			$VAULT.Remove($_)
			Write-Output "Credential of user $($_.UserName) for resource $($_.Resource) removed."
		}
	}
	catch
	{
		Write-Error "Error removing credential(s)."
	}
}


function ConvertTo-VaultCredential
{
<#
.SYNOPSIS
Converts Powershell credential to password vault credential.
.DESCRIPTION
Converts Powershell credential to password vault credential. Requires password to be set in Powershell credential.
.PARAMETER Credential
Powershell credential object
.PARAMETER Resource
The resource for which the password vault credential is created
.EXAMPLE
Get-Credential | ConvertTo-VaultCredential -Resource "https://wikipedia.org/"

Shows a dialog to obtain credential information and convert it to a password vault credential for the Wikipedia
web page
.LINK
https://gallery.technet.microsoft.com/scriptcenter/Powershell-Module-f0f91920
.NOTES
Author: Markus Scholtes
Created: 2019/09/10
#>
	Param([Parameter(ValueFromPipeline = $TRUE,ValueFromPipelineByPropertyName = $TRUE)][ValidateNotNullOrEmpty()][PSCREDENTIAL]$Credential, [ValidateNotNullOrEmpty()][STRING]$Resource)

	try {
		# create and return password vault credential
		return New-Object Windows.Security.Credentials.PasswordCredential($Resource, $Credential.UserName, $Credential.GetNetworkCredential().Password)
	}
	catch
	{
		Write-Error "Error creating password vault credential."
		return $NULL
	}
}


function ConvertFrom-VaultCredential
{
<#
.SYNOPSIS
Converts password vault credential to Powershell credential.
.DESCRIPTION
Converts password vault credential to Powershell credential. The resource information gets lost on conversion.
.PARAMETER Credential
Password vault credential object
.EXAMPLE
Get-VaultCredential -Resource "https://msn.com/" -UserName "LilyOhLily" | ConvertFrom-VaultCredential

Converts the credential for MSN in the password vault to a Powershell credential
.LINK
https://gallery.technet.microsoft.com/scriptcenter/Powershell-Module-f0f91920
.NOTES
Author: Markus Scholtes
Created: 2019/09/10
#>
	Param([Parameter(ValueFromPipeline = $TRUE,ValueFromPipelineByPropertyName = $TRUE)][ValidateNotNullOrEmpty()][Windows.Security.Credentials.PasswordCredential]$Credential)

	try {
		# unhide password in password vault credential
		$Credential.RetrievePassword()
		# convert password to secure text
		$SECUREPASSWORD = ConvertTo-SecureString $Credential.Password -AsPlainText -Force
		# create and return Powershell Credential
		return New-Object System.Management.Automation.PSCredential($Credential.UserName, $SECUREPASSWORD)
	}
	catch
	{
		Write-Error "Error creating PSCredential."
		return $NULL
	}
}


# Export functions
Export-ModuleMember -Function @(
	'Get-VaultCredential',
	'Show-VaultCredentials',
	'Add-VaultCredential',
	'Remove-VaultCredential',
	'ConvertTo-VaultCredential',
	'ConvertFrom-VaultCredential'
)
