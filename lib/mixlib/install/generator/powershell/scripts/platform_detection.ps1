################ platform_detection.ps1
$platform_version = Get-PlatformVersion
$architecture = Get-PlatformArchitecture

Write-Host "windows $platform_version $architecture"
