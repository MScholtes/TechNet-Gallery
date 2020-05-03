# Markus Scholtes, 2016
# Retrieves latest reboot time(s)

<#
.Synopsis
Retrieves latest reboot time
.Description
Retrieves latest reboot time(s) of a system by event log entries
.Parameter Computer
Name of the computer to analyze
.Parameter Latest
Count of boot times to retrieve
.Inputs
None
.Outputs
None
.Example
Get-RebootTime

Retrieves latest reboot time of the local system
.Example
Get-RebootTime REMOTECOMPUTER 3

Retrieves 3 latest reboot times of the system REMOTECOMPUTER
#>
function Get-RebootTime([STRING][Parameter(ValueFromPipeline=$TRUE)]$Computer = "$ENV:COMPUTERNAME", [INT32][ValidateScript({$_ -gt 0})]$Latest = 1)
{
	# search latest reboot events in the system log
	try {
		$EVENTS = Get-EventLog -LogName System -ComputerName $Computer -Source Microsoft-Windows-Kernel-General -InstanceId 12 -Newest $Latest
		$SCRIPT:TIMESPAN = $NULL
	
		# loop through found events
		foreach ($EVENT in $EVENTS)
		{
			# get time stamp
			$BOOTTIME = $EVENT.TimeGenerated
			if (!$SCRIPT:TIMESPAN)
			{
		  	"Last boot time of computer $Computer`: $BOOTTIME"
				$SCRIPT:TIMESPAN = New-TimeSpan -Start $BOOTTIME
				if ($($SCRIPT:TIMESPAN.Days) -lt 1)
				{
					"Computer $Computer is active for less than a day."
				}
				else
				{
					"Computer $Computer is active for over $($SCRIPT:TIMESPAN.Days) days."
				}
			}
			else
			{
				"Boot time of computer $Computer`: $BOOTTIME"
			}
		}
	}
	catch {
		Write-Error "Cannot connect to computer $Computer"
	}
}
