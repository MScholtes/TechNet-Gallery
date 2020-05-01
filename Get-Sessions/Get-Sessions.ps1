<#
.SYNOPSIS
Gets information about interactive logins.
.DESCRIPTION
Gets information about interactive logins to a system. If no further parameters are specified, the local system is
examined and the logins of the last week are displayed in short format. An attempt is made to logically summarize
the times of logon sessions, this means for a new connection after a disconnect a new record is displayed.
.PARAMETER UserName
Match filter for the username of the sessions to be displayed. Default: empty.
.PARAMETER ComputerName
Computer to be examined. Standard: local system.
.PARAMETER After
Start time of the events to be examined. Default: a week ago.
.PARAMETER Before
End time of the events to be examined. Default: now.
.PARAMETER Detailed
Expanded output with session id and name or IP of the remote host. Default: $FALSE.
.EXAMPLE
Get-Sessions | Format-Table

Lists sessions of the local computer of the last week.
.EXAMPLE
Get-Sessions -User Markus -After 12/01/2018 -Before 12/02/2018 -ComputerName OtherServer -Detailed

Detailed list of sessions of the day 12/01/2018 from System "OtherServer".
.NOTES
Name: Get-Sessions
Author: Markus Scholtes
Version: 1.01 - Improved error handling and englisch output
Date: 2019-01-28
Based upon the script Get-ULogged.ps1 from VGSandz: https://gallery.technet.microsoft.com/scriptcenter/Find-Users-who-Logged-in-07dbe5f6/
#>
function Get-Sessions([STRING]$UserName = "", [STRING]$ComputerName = "$ENV:COMPUTERNAME", [STRING]$After = "", [STRING]$Before = "", [SWITCH]$Detailed)
{
	Begin
	{
		# Array für Anmeldeeinträge initialisieren
		$SCRIPT:AnmeldeListe = @()

		# Eintrag ausgeben
		function PrintEntry([INT]$Index)
		{
			if (![STRING]::IsNullOrEmpty($SCRIPT:AnmeldeListe[$Index].Account))
			{
				if ($Detailed)
				{
					$SCRIPT:AnmeldeListe[$Index]
				} else {
					$SCRIPT:AnmeldeListe[$Index] | Select-Object -Property * -ExcludeProperty SessionId, RemoteHost
				}
			}
		}

		# Alle Einträge ausgeben
		function PrintAll
		{
			for ($i; $i -lt $AnmeldeListe.Length; $i++) { PrintEntry -Index $i }
		}

		# Eintrag zu Benutzernamen suchen, Rückgabe Index (wenn gefunden) oder Arraylänge (wenn nicht gefunden)
		function FindEntry([STRING]$Account)
		{
			$Zaehler = 0
			foreach ($Eintrag in $SCRIPT:AnmeldeListe)
			{
				if ($Eintrag.Account -eq $Account) { break; }
				$Zaehler ++;
			}
			return $Zaehler
		}

		# Eintrag um Ereignis ergänzen oder - falls noch nicht da - neuen Eintrag erstellen
		# bei Bedarf wird ein vorhandener Eintrag zum Benutzer oder der aktuelle Eintrag (wenn beendet) ausgegeben
		function AddEntry([STRING]$Account, $SessionId = $NULL, $RemoteHost = $NULL, $LogonTime = $NULL, $ConnectTime = $NULL, $LogoffTime = $NULL, $DisconnectTime = $NULL)
		{
			# gibt es einen Eintrag zum Benutzer
			$Index = FindEntry -Account $Account
			if ($Index -eq ($SCRIPT:AnmeldeListe).Length)
			{ # nein, neuen Eintrag erstellen
				$NeuerEintrag = New-Object PSCustomObject
				$NeuerEintrag | Add-Member -MemberType NoteProperty -Name Account -Value $Account
				$NeuerEintrag | Add-Member -MemberType NoteProperty -Name SessionId -Value $SessionId
				$NeuerEintrag | Add-Member -MemberType NoteProperty -Name RemoteHost -Value $RemoteHost
				$NeuerEintrag | Add-Member -MemberType NoteProperty -Name LogonTime -Value $LogonTime
				$NeuerEintrag | Add-Member -MemberType NoteProperty -Name ConnectTime -Value $ConnectTime
				$NeuerEintrag | Add-Member -MemberType NoteProperty -Name LogoffTime -Value $LogoffTime
				$NeuerEintrag | Add-Member -MemberType NoteProperty -Name DisconnectTime -Value $DisconnectTime

				$SCRIPT:AnmeldeListe += $NeuerEintrag
			} else {
				# prüfen, ob ein bestehender Eintrag zum Benutzer vorhanden ist, der beendet, also ausgegeben werden muss
				$Flush = $FALSE
				if ($LogonTime) { $Flush = $TRUE }
				if ($ConnectTime) { $Flush = $TRUE }
				if ($LogoffTime -And $SCRIPT:AnmeldeListe[$Index].LogoffTime) { $Flush = $TRUE }
				if ($DisconnectTime -And $SCRIPT:AnmeldeListe[$Index].DisconnectTime) { $Flush = $TRUE }
				if ($SessionId -ne $SCRIPT:AnmeldeListe[$Index].SessionId) { $Flush = $TRUE }
				if (!$LogoffTime -And $SCRIPT:AnmeldeListe[$Index].RemoteHost -And ($RemoteHost -ne $SCRIPT:AnmeldeListe[$Index].RemoteHost)) { $Flush = $TRUE }

				if ($Flush)
				{ # es muss ein bestehender Eintrag zum Benutzer ausgegeben werden
					PrintEntry -Index $Index
					# neuer Eintrag überschreibt den bestehenden Datensatz
					$SCRIPT:AnmeldeListe[$Index].SessionId = $SessionId
					$SCRIPT:AnmeldeListe[$Index].RemoteHost = $RemoteHost
					$SCRIPT:AnmeldeListe[$Index].LogonTime = $LogonTime
					$SCRIPT:AnmeldeListe[$Index].DisconnectTime = $DisconnectTime
					$SCRIPT:AnmeldeListe[$Index].ConnectTime = $ConnectTime
					$SCRIPT:AnmeldeListe[$Index].LogoffTime = $LogoffTime
				} else {
					# bestehender Eintrag wird ergänzt
					if (!$SCRIPT:AnmeldeListe[$Index].RemoteHost) { $SCRIPT:AnmeldeListe[$Index].RemoteHost = $RemoteHost }
					if ($DisconnectTime) { $SCRIPT:AnmeldeListe[$Index].DisconnectTime = $DisconnectTime }
					if ($LogoffTime) { $SCRIPT:AnmeldeListe[$Index].LogoffTime = $LogoffTime }
				}
			}

			if ($SCRIPT:AnmeldeListe[$Index].DisconnectTime -And $SCRIPT:AnmeldeListe[$Index].LogoffTime)
			{ # ist der Eintrag beendet? Ja -> Eintrag ausgeben und löschen
				PrintEntry -Index $Index
				$SCRIPT:AnmeldeListe[$Index].Account = ""
			}
		}

		# Parameter interpretieren
		if ([STRING]::IsNullOrEmpty($Before))
		{ $BeforeLog = Get-Date } else { $BeforeLog = Get-Date $Before }
		if ([STRING]::IsNullOrEmpty($After))
		{ $AfterLog = (Get-Date).AddDays(-7) } else { $AfterLog = Get-Date $After }
	}

	Process
	{
		try
		{ # An- und Abmeldeereignisse auslesen. Wegen Beschleunigung alle Filter in Hashtable übergeben
			$EventDataCollector = Get-Winevent -FilterHashTable @{ LogName = "Microsoft-Windows-TerminalServices-LocalSessionManager/Operational"; Id = 21,23,24,25; StartTime = $AfterLog; EndTime = $BeforeLog } -ComputerName $ComputerName -Oldest -EA "SilentlyContinue"
			foreach ($DataCollected in $EventDataCollector)
			{ # Ereignisse durchlaufen
				# Nachricht lesen
				$MessageSplit = $DataCollected.Message.Split("`n")
				# Benutzernamen extrahieren
				$UserLogged = ($MessageSplit[2].Split(":"))[1].Trim()
				# Session-ID extrahieren
				$IdLogged = ($MessageSplit[3].Split(":"))[1].Trim().TrimEnd(".")
				if ($DataCollected.Id -ne "23")
				{	# Remotehost extrahieren
					$SourceLogged = ($MessageSplit[4].Split(":"))[1].Trim().TrimEnd(".")
				} else { # Information nicht vorhanden bei Abmeldenachricht
					$SourceLogged = $NULL
				}

				if ($UserLogged -match $UserName)
				{ # wenn Ereignis zu gesuchter Benutzernamensmaske
					switch ($DataCollected.Id)
					{ # Anmeldeereignis
						"21" { AddEntry -Account $UserLogged -SessionId $IdLogged -RemoteHost $SourceLogged -LogonTime $DataCollected.TimeCreated }
						# Abmeldeereignis
						"23" { AddEntry -Account $UserLogged -SessionId $IdLogged -RemoteHost $SourceLogged -LogoffTime $DataCollected.TimeCreated }
						# Trennungsereignis
						"24" { AddEntry -Account $UserLogged -SessionId $IdLogged -RemoteHost $SourceLogged -DisconnectTime $DataCollected.TimeCreated }
						# Verbidungsereignis
						"25" { AddEntry -Account $UserLogged -SessionId $IdLogged -RemoteHost $SourceLogged -ConnectTime $DataCollected.TimeCreated }
					}
				}
			}
			if ($SCRIPT:AnmeldeListe.Length -eq 0)
			{ # kein Eintrag gefunden
				if ([STRING]::IsNullOrEmpty($UserName))
				{ # passende Meldung erzeugen
					Write-Output "No logon events between $AfterLog and $BeforeLog on computer $ComputerName"
				} else {
					Write-Output "No logon events of users with partial name '$UserName' between $AfterLog and $BeforeLog on computer $ComputerName"
				}
			}
		}
		catch
		{ # Fehler beim Ermitteln der Ereignisse
			Write-Error "Error processing event log from computer $ComputerName`: $($_.Exception.Message)"
		}
	}

	End
	{ # noch nicht ausgegebene Datensätze ausgeben
		PrintAll
	}
}
