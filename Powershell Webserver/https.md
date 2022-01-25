# How to enable https encryption
You can also let the **Powershell Webserver** deliver encrypted traffic. This is done using the encryption stack of the operating system.

The following description describes the use of a self-created certificate. This must be accepted or imported on the browser page. If a valid certificate already exists you want to use, steps 1 and 7 are skipped and in step 2 you have to use the thumbprint of your certificate.

## Step 1: Create self-signed certificate
Start an administrative Powershell console. With the following commands you create a certificate:
```powershell
# create self-signed certificate ('localhost', first found IPv4 address, hostname and FQDN is used for it)
$FIRSTIP = (Get-NetIPAddress -AddressFamily IPv4 | Select -First 1).IPAddress
$FQDN = ([System.Net.Dns]::GetHostByName(($ENV:COMPUTERNAME))).Hostname.ToLower()
$DNSNAMES = "localhost", $FIRSTIP, $($ENV:COMPUTERNAME.ToLower()), "$FQDN"
$CERTIFICATE = New-SelfSignedCertificate -DnsName $DNSNAMES -CertStoreLocation CERT:\LocalMachine\My
```

You can view the certificate you just created as follows:
```powershell
# view certificate
$CERTIFICATE
```

## Step 2: Bind certificate to application and port
Now the certificate must be bound to the application **Powershell** and the desired port, in this example we use port 8443\
(the AppID of Powershell.exe is {1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}).

```powershell
# certificate binding to application "Powershell" and port 8443 
netsh http add sslcert ipport=0.0.0.0:8443 certhash=$($CERTIFICATE.Thumbprint) --% appid={1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}
```

You can view the binding you just created as follows:
```powershell
# view binding
netsh http show sslcert
```

## Step 3: Create firewall share
Now we have to create a firewall share so that the web server can be reached from the network\
(this step is not necessary for local use only).

```powershell
# create firewall share
netsh advfirewall firewall add rule name="Powershell Webserver" dir=in action=allow protocol=TCP localport=8443
```

## Step 4: Run web server
Now we have to start the web server with *https* and the port to listen to as parameters.

```powershell
# start web server
Start-Webserver "https://+:8443/"
```

After use, the web server is terminated. The following steps describe how to clean up the configuration.

## Step 5: Remove firewall share
The following command removes the firewall share for the web server.

```powershell
# remove firewall share
netsh advfirewall firewall delete rule name="Powershell Webserver"
```

## Step 6: Remove certificate binding
The following command removes the certificate binding for the web server.

```powershell
# remove certificate binding
netsh http delete sslcert ipport=0.0.0.0:8443
```

## Step 7: Remove certificate
The following command removes the certificate (the command assumes that the used certificate is still in the variable $CERTIFICATE, otherwise determine the thumbprint).

```powershell
# remove certificate
Remove-Item CERT:\LocalMachine\My\$($CERTIFICATE.Thumbprint)
```
