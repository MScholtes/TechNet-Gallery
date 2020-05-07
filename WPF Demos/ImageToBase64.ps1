Param([String]$path)

[CONVERT]::ToBase64String((Get-Content $path -Encoding BYTE))
