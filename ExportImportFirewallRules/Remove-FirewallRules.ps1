<#
.SYNOPSIS
Removes firewall rules according to a list in a CSV or JSON file.
.DESCRIPTION
Removes firewall rules according to a with Export-FirewallRules.ps1 generated list in a CSV or JSON file.
CSV files have to be separated with semicolons. Only the field Name or - if Name is missing - DisplayName
is used, alle other fields can be omitted
anderen
.PARAMETER CSVFile
Input file
.PARAMETER JSON
Input in JSON instead of CSV format
.NOTES
Author: Markus Scholtes
Version: 1.02
Build date: 2020/02/15
.EXAMPLE
Remove-FirewallRules.ps1
Removes all firewall rules according to a list in the CSV file FirewallRules.csv in the current directory.
.EXAMPLE
Remove-FirewallRules.ps1 WmiRules.json -json
Removes all firewall rules according to the list in the JSON file WmiRules.json.
#>
Param($CSVFile = ".\FirewallRules.csv", [SWITCH]$JSON)

#Requires -Version 4.0


if (!$JSON)
{ # read CSV file
	$FirewallRules = Get-Content $CSVFile | ConvertFrom-CSV -Delimiter ";"
}
else
{ # read JSON file
	$FirewallRules = Get-Content $CSVFile | ConvertFrom-JSON
}

# iterate rules
ForEach ($Rule In $FirewallRules)
{
	$CurrentRule = $NULL
	if (![STRING]::IsNullOrEmpty($Rule.Name))
	{
		$CurrentRule = Get-NetFirewallRule -EA SilentlyContinue -Name $Rule.Name
		if (!$CurrentRule)
		{
			Write-Error "Firewall rule `"$($Rule.Name)`" does not exist"
			continue
		}
	}
	else
	{
		if (![STRING]::IsNullOrEmpty($Rule.DisplayName))
		{
			$CurrentRule = Get-NetFirewallRule -EA SilentlyContinue -DisplayName $Rule.DisplayName
			if (!$CurrentRule)
			{
				Write-Error "Firewall rule `"$($Rule.DisplayName)`" does not exist"
				continue
			}
		}
		else
		{
			Write-Error "Failure in data record"
			continue
		}
	}

	Write-Output "Removing firewall rule `"$($CurrentRule.DisplayName)`" ($($CurrentRule.Name))"
	Get-NetFirewallRule -EA SilentlyContinue -Name $CurrentRule.Name | Remove-NetFirewallRule
}
