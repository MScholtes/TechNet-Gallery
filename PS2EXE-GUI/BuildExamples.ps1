# Markus Scholtes 2017
# Create examples in subdir "Examples"

$SCRIPTPATH = Split-Path $SCRIPT:MyInvocation.MyCommand.Path -parent
ls "$SCRIPTPATH\Examples\*.ps1" | %{
	."$SCRIPTPATH\ps2exe.ps1" "$($_.Fullname)" "$($_.Fullname -replace '.ps1','.exe')" -verbose
	."$SCRIPTPATH\ps2exe.ps1" "$($_.Fullname)" "$($_.Fullname -replace '.ps1','-GUI.exe')" -verbose -noConsole
}

Remove-Item "$SCRIPTPATH\Examples\Progress.exe*"
Remove-Item "$SCRIPTPATH\Examples\ScreenBuffer-GUI.exe*"

$NULL = Read-Host "Press enter to exit"
