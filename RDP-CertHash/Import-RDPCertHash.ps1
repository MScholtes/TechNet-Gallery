<#
.Synopsis
Connects with RDP port of a given system, loads its certificate and writes entries to the registry that no 
"do you trust" messages appear on using rdp to the system anymore.
.Description
Connects with RDP port of a given system, loads its certificate and writes entries to the registry that no 
"do you trust" messages appear on using rdp to the system anymore.
.Parameter SERVERNAME
Name of the remote system
.Example
.\Import-RDPCertHash.ps1 "server1"

Gets certificate of system "server1"
.Notes
Author: Markus Scholtes, 21.10.2016
Uses function Get-PortCertificate by
Author: Caleb Keene
#>
param([Parameter(Position=0, Mandatory=$TRUE, ValueFromPipeline=$TRUE)][STRING]$SERVERNAME)


function HexToBin 
{
<#
.SYNOPSIS
    Converts Hex-String to BYTE array
#>
	param([Parameter(Position=0, Mandatory=$TRUE, ValueFromPipeline=$TRUE)][STRING]$HEXSTRING)

	$BINSTRING = @()
	for ($i = 0; $i -lt $HEXSTRING.Length; $i += 2)
	{ $BINSTRING += [BYTE]::Parse($HEXSTRING.Substring($i, 2), [System.Globalization.NumberStyles]::HexNumber) }
	
	Write-Output $BINSTRING
}

function Get-PortCertificate {
<#
.SYNOPSIS
    Returns certificate information from a listening TLS/SSL service port.
.DESCRIPTION
    Gets the associated certificate from a TLS/SSL application service port.
.PARAMETER  Computername
    Hostname or IP address of the target system (Default: localhost).  The function uses the supplied computername to validate with the certificate's subject name(s).
.PARAMETER  Port
    Port to retrieve SSL certificate (Default: 443).
.PARAMETER  Path
    Directory path to save SSL certificate(s).
.PARAMETER  DownloadChain
    Save all chain certificates to file.  A certificate chain folder will be created under the specfied -path directory.  -DownloadChain is dependent on the path parameter.
.NOTES
    Name: Get-PortCertificate
    Author: Caleb Keene
    Updated: 08-30-2016
    Version: 1.2
		V1.3 - 23.9.2016 by Markus Scholtes
		Works in Powershell V2 now too (but sorting is different, no setting of the default display properties)
.EXAMPLE
    Get-PortCertificate -Computername Server1 -Port 3389 -Path C:\temp -verbose
.EXAMPLE
    "server1","server2","server3" | Get-PortCertificate
#>
[CmdletBinding()]
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true, Position = 0)]
        [Alias('IPAddress','Server','Computer')]
        [string]$ComputerName =  $ENV:COMPUTERNAME,
        [Parameter(Mandatory = $false,Position = 1)]
        [ValidateRange(1,65535)]
        [int]$Port = 443,
        [Parameter(Mandatory = $false)]
        [ValidateNotNullorEmpty()]
        [string]$Path

    )
    #use a dynamic parameter to prevent -downloadchain without -path.
    DynamicParam {
        #Need some sort of conditional check before allowing Dynamic Parameter
        If ($PSBoundParameters.ContainsKey('Path')) {
            #Same as [Parameter()]
            $attribute = new-object System.Management.Automation.ParameterAttribute
            $attribute.Mandatory = $false
            $AttributeCollection = new-object -Type System.Collections.ObjectModel.Collection[System.Attribute]
            $AttributeCollection.Add($attribute)

            #Build out the Dynamic Parameter
            # Need the Parameter Name, Type and Attribute Collection (Built already)
            $DynamicParam = new-object -Type System.Management.Automation.RuntimeDefinedParameter("DownloadChain", [switch], $AttributeCollection)

            $ParamDictionary = new-object -Type System.Management.Automation.RuntimeDefinedParameterDictionary
            $ParamDictionary.Add("DownloadChain", $DynamicParam)
            return $ParamDictionary
        }
    }

    Begin{
        #make sure the version is supported
        if ($PSVersionTable.PSVersion.Major -le 2)
        {
          Write-Warning "Property sorting and default property selection requires PowerShell version 3 or later."
        }
        else
        {
        	#add a custom type name to control our objects default display properties
        	try{ Update-TypeData -TypeName 'Get.PortCertificate' -DefaultDisplayPropertySet Subject,Issuer,NotAfter,NotBefore,ExpiresIn,CertificateValidNames,TargetName,TargetNameStatus,TargetNameStatusDetails,TargetNameIsValid,ChainPath,ChainStatus,ChainStatusDetails,CertificateIsValid -ErrorAction stop}
        	catch{}
        }

        #validate that the path is a filesystem directory
        if ($path) {

            if(-not(test-path -PathType Container FileSystem::$path)){
                Write-warning "The supplied directory path is not valid: $path"
                break
            }

        }

    }

    Process {

        #make sure we are able to establish a port connection

        #Set our connection timeout
        $timeout = 5000

        #Create object to test the port connection
        $tcpobject = New-Object System.Net.Sockets.TcpClient

        #Connect to remote port
        $connect = $tcpobject.BeginConnect($ComputerName,$Port,$null,$null)

        #Configure connection timeout
        $wait = $connect.AsyncWaitHandle.WaitOne($timeout,$false)
        If (-NOT $Wait) {
            Write-Warning "[$($ComputerName)] Connection to port $($Port) timed out after $($timeout) milliseconds"
            return
        } Else {
            Try {
                [void]$tcpobject.EndConnect($connect)
                Write-Verbose "[$($ComputerName)] Successfully connected to port $($Port). Good!"
            } Catch {
                Write-Warning "[$($ComputerName)] $_"
                return
            }
        }

        #Note: This also works for validating the port connection, but the default timeout when unable to connect is a bit long.
        <#
        try {
            (New-Object system.net.sockets.tcpclient -ArgumentList $computername,$port -ErrorAction stop).Connected
        }
        catch{
            Write-Warning ("Unable to connect to {0} on port {1}"-f$ComputerName,$Port)
            return
        }
        #>


        Write-Verbose "[$($ComputerName)] Getting SSL certificate from port $($Port)."

        #create our webrequest object for the ssl connection
        $sslrequest = [Net.WebRequest]::Create("https://$ComputerName`:$port")

        #make the connection and store the response (if any).
        try{$Response = $sslrequest.GetResponse()}
        catch{}

        #load the returned SSL certificate using x509certificate2 class
        if ($certificate = [Security.Cryptography.X509Certificates.X509Certificate2]$sslrequest.ServicePoint.Certificate.Handle){

            Write-Verbose "[$($ComputerName)] Certificate found!  Building certificate chain information and object data."

            #build our certificate chain object
            $chain = [Security.Cryptography.X509Certificates.X509Chain]::create()
            $isValid = $chain.Build($certificate)

            #get certificate subject names from our certificate extensions
            $validnames = @()
            try{[array]$validnames += @(($certificate.Extensions | ? {$_.Oid.Value -eq "2.5.29.17"}).Format($true).split("`n") | ? {$_} | % {$_.split("=")[1].trim()})}catch{}
            try{[array]$validnames += @($certificate.subject.split(",")[0].split("=")[1].trim())}catch{}

            #validate the target name
            for($i=0;$i -le $validnames.count - 1;$i++){
                if ($validnames[$i] -match '^\*'){
                    $wildcard = $validnames[$i] -replace '^\*\.'
                    if($computername -match "$wildcard$"){
                        $TargetNameIsValid = $true
                        break
                    }
                    $TargetNameIsValid = $false
                }
                else{
                    if($validnames[$i] -match "^$ComputerName$"){
                        $TargetNameIsValid = $true
                        break
                    }
                    $TargetNameIsValid = $false
                }
            }

            #create custom object to later convert to PSobject (required in order to use the custom type name's default display properties)
            $customized = $certificate | select *,
                @{n="ExtensionData";e={$_.Extensions | % {@{$_.oid.friendlyname.trim()=$_.format($true).trim()}}}},
                @{n="ResponseUri";e={if ($Response.ResponseUri){$Response.ResponseUri}else{$false}}},
                @{n="ExpiresIn";e={if((get-date) -gt $_.NotAfter){"Certificate has expired!"}else{$timespan = New-TimeSpan -end $_.notafter;"{0} Days - {1} Hours - {2} Minutes" -f $timespan.days,$timespan.hours,$timespan.minutes}}},
                @{n="TargetName";e={$ComputerName}},
                @{n="CertificateValidNames";e={$validnames}},
                @{n="ChainPath";e={$count=0;$chaincerts = @($chain.ChainElements.certificate.subject);$($chaincerts[($chaincerts.length -1) .. 0] | % {"{0,$(5+$count)}{1}" -f "---",$_;$count+=3}) -join "`n"}},
                @{n="ChainCertificates";e={@{"Certificates"=$chain.ChainElements.certificate}}},
                @{n="ChainStatus";e={if($isvalid -and !$_.chainstatus){"Good"}else{$chain.chainstatus.Status}}},
                @{n="ChainStatusDetails";e={if($isvalid -and !$_.chainstatus){"The certificate chain is valid."}else{$chain.chainstatus.StatusInformation.trim()}}},
                @{n="CertificateIsValid";e={$isValid}},
                @{n="TargetNameIsValid";e={$TargetNameIsValid}},
                @{n="TargetNameStatus";e={if($TargetNameIsValid){"Good"}else{"Invalid"}}},
                @{n="TargetNameStatusDetails";e={if($TargetNameIsValid){"The target name appears to be valid: $computername"}else{"TargetName $computername does not match any certificate subject name."}}}


            #get object properties for our PSObject
						if ($PSVersionTable.PSVersion.Major -gt 2)
						{
            	$objecthash = [Ordered]@{}
            	($customized | Get-Member -MemberType Properties).name | % {$objecthash+=@{$_=$customized.$_}}
            }
            else
            {
       				$objecthash = New-Object System.Collections.Specialized.OrderedDictionary
            	$customized | Get-Member -MemberType Properties | %{$_.name} | % {$objecthash+=@{$_=$customized.$_}}
            }

            #create the PSObject
            $psobject = New-Object psobject -Property $objecthash

            #add the custom type name to the PSObject
            $psobject.PSObject.TypeNames.Insert(0,'Get.PortCertificate')

            #save our certificate(s) to file if applicable
            if ($path){

                write-verbose "Saving certificate(s) to file."

                try {
                    $psobject.RawData | Set-Content -Encoding Byte -Path "$path\Cert`_$ComputerName`_$port`.cer" -ErrorAction stop
                    write-verbose "Certificate saved to $path\Cert`_$ComputerName`_$port`.cer."
                }
                catch{write-warning ("Unable to save certificate to {0}: {1}" -f "$path\Cert`_$ComputerName`_$port`.cer",$_.exception.message)}

                if($PSBoundParameters.ContainsKey('DownloadChain')){

                    New-Item -ItemType directory -path "$path\ChainCerts`_$ComputerName`_$port" -ErrorAction SilentlyContinue > $null

                    $psobject.chaincertificates.certificates | % {
                        try {
                            Set-Content $_.RawData -Encoding Byte -Path "$path\ChainCerts`_$ComputerName`_$port\$($_.thumbprint)`.cer" -ErrorAction stop
                            write-verbose "Certificate chain certificate saved to $path\ChainCerts`_$ComputerName`_$port\$($_.thumbprint)`.cer."
                        }
                        catch{
                            write-warning ("Unable to save certificate chain certificate to {0}: {1}" -f "$path\ChainCerts`_$ComputerName`_$port",$_.exception.message)
                        }
                    }
                }
            }

            #abort any connections
            $sslrequest.abort()

            #return the object
            $psobject

        }

        else{
            #we were able to connect to the port but no ssl certificate was returned
            write-warning ("[{0}] No certificate returned on port {1}."-f $ComputerName,$Port)

            #abort any connections
            $sslrequest.abort()

            return
        }
    }
}


# get certificate that ist delivered by rdp connect
$ZERTIFIKAT = Get-PortCertificate -ComputerName $SERVERNAME -Port 3389
# Result for example: $ZERTIFIKAT.Thumbprint = "4CEEEDC9E054B70102EE81608412D2A537719EE2"

# alternative: WMI query
# but: administrative rights on target system are necessary and the RPC ports have to be accessible through a firewall
#$THUMBPRINT = (Get-WmiObject -ComputerName $SERVERNAME -Namespace root\CIMV2\TerminalServices -Class Win32_TSGeneralSetting).SSLCertificateSHA1Hash

# got certificate?
if ($ZERTIFIKAT)
{ # yes
	if (!(Test-Path -Path "HKCU:\Software\Microsoft\Terminal Server Client\Servers\$SERVERNAME"))
	{ # if not existing create registry key for target system
		New-Item -Path "HKCU:\Software\Microsoft\Terminal Server Client\Servers\$SERVERNAME"
	}	

	# write binary hash to registry
	New-ItemProperty -Path "HKCU:\Software\Microsoft\Terminal Server Client\Servers\$SERVERNAME" -Name "CertHash" -PropertyType "BINARY" -Value (HexToBin($ZERTIFIKAT.Thumbprint)) -Force
	
	# prevent message for unknown publisher of the certificate
	New-ItemProperty -Path "HKCU:\Software\Microsoft\Terminal Server Client\LocalDevices" -Name "$SERVERNAME" -PropertyType "DWORD" -Value 127 -Force
}
else
{ # no certifiacte received
	"Cannot retrieve certificate for RDP connection to $SERVERNAME"
}
