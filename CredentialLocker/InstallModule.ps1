# Install module CredentialLocker to "All Users" module directory

$MODULEPATH = "$ENV:ProgramFiles\WindowsPowerShell\Modules\CredentialLocker"
$MODULEVERSION = "1.0.0"
if ($PSVersionTable.PSVersion.Major -ge 5) { 	$MODULEPATH = Join-Path $MODULEPATH $MODULEVERSION }

New-Item "$MODULEPATH" -Type Directory -EA SilentlyContinue | Out-Null
if (!(Test-Path "$MODULEPATH"))
{
	Write-Error "Cannot create module directory. Please execute script with administrative rights"
	exit 1
}

copy-item "$PSScriptRoot\CredentialLocker.psd1" "$MODULEPATH"
copy-item "$PSScriptRoot\CredentialLocker.psm1" "$MODULEPATH"

Write-Output "Module CredentialLocker installed, please restart Powershell before using the new module"
