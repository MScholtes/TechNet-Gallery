# Powershell Module CredentialLocker
Module to manage the Credential Locker, also known as Password Vault, which provides a way for you to store user credentials (username, password) in a secure fashion for web pages or your app. With this module you can manage stored credentials of Internet Explorer and Edge too.

Since Technet Gallery will be closed, now here.

See Script Center version: [Powershell Module CredentialLocker](https://gallery.technet.microsoft.com/scriptcenter/Powershell-Module-f0f91920).

## Description
Module to manage the Credential Locker, also known as Password Vault, which provides a way for you to store user credentials (username, password) in a secure fashion for web pages or your app. Usernames and passwords stored using the Credential Locker are encrypted and saved locally and can only be accessed by the user who saved them.

With this module you can manage stored credentials of Internet Explorer and Edge too.

Requires Windows 8 / Server 2012 or up.

## Usage
Import the module to your powershell session (assume the files are in the current directory):

```powershell
Import-Module .\CredentialLocker.psd1
```

Install the module from an administrative powershell session (assume the files are in the current directory):
```powershell
.\InstallModule.ps1
```

or use the version on Powershell Gallery: see [here](https://www.powershellgallery.com/packages/CredentialLocker) or install with
```powershell
Install-Module CredentialLocker
```
## Commands
```powershell
Get-VaultCredential [-Resource <Resource>] [-UserName <UserName>]
```
Retrieves credentials stored in the password vault searched by resource and/or user name.

```powershell
Show-VaultCredentials
```
List all credentials stored in the password vault.

```powershell
Add-VaultCredential -Resource <Resource> -UserName <UserName> -Password <Password> [-IE] [-Edge] [-Hide]
```
```powershell
Add-VaultCredential -Credential <VaultCredential> [-IE] [-Edge] [-Hide]
```
Adds a credential to the password vault. Parameter -IE or -Edge generates a credential for a web page. Parameter -Hide hides the credential in control panel.

```powershell
Remove-VaultCredential -Resource <Resource> -UserName <UserName>
```
```powershell
Remove-VaultCredential -Credential <VaultCredential>
```
Removes credentials from the password vault.

```powershell
ConvertTo-VaultCredential -Credential <PSCredential>
```
Converts Powershell credential to password vault credential.

```powershell
ConvertFrom-VaultCredential -Credential <VaultCredential>
```
Converts password vault credential to Powershell credential.

## Examples
```powershell
Get-VaultCredential "https://github.com/"

(Get-VaultCredential -resource "https://github.com/").Password

Add-VaultCredential "https://login.live.com/" "test@test.com" "P@ssw0rd" -Edge -Hide

Get-Credential | ConvertTo-VaultCredential -Resource "MyApp" | Add-VaultCredential -Application "MyApp"

Remove-VaultCredential -Resource "https://github.com/"

Get-VaultCredential -Resource "https://github.com/" -UserName "logonname" | Remove-VaultCredential
```


