function Install-Project {
  <#
    .SYNOPSIS
    Install a Chef Software, Inc. product
    .DESCRIPTION
    Install a Chef Software, Inc. product
    .EXAMPLE
    iex (new-object net.webclient).downloadstring('https://omnitruck.chef.io/install.ps1'); Install-Project -project chef -channel stable

    Installs the latest stable version of Chef.
    .EXAMPLE
    iex (irm 'https://omnitruck.chef.io/install.ps1'); Install-Project -project chefdk -channel current

    Installs the latest integration build of the Chef Development Kit
  #>
  [cmdletbinding(SupportsShouldProcess=$true)]
  param (
    # Project to install
    [string]
    $project = 'chef',
    # Release channel to install from
    [validateset('current', 'stable', 'unstable')]
    [string]
    $channel = 'stable',
    # Version of the application to install
    # This parameter is optional, if not supplied it will provide the latest version,
    # and if an iteration number is not specified, it will grab the latest available iteration.
    # Partial version numbers are also acceptable (using v=11
    # will grab the latest 11.x client which matches the other flags).
    [string]
    $version,
    # Full path for the downloaded installer.
    [string]
    $filename,
    # Full path to the location to download the installer
    [string]
    $download_directory = $env:temp,
    # The following legacy switches are just aliases for the current channel
    [switch]
    $prerelease,
    [switch]
    $nightlies,
    [validateset('auto', 'i386', 'x86_64')]
    [string]
    $architecture = 'auto',
    [validateset('auto', 'service', 'task')]
    [string]
    $daemon = 'auto',
    [string]
    $http_proxy,
    # Specify an alternate download url
    [string]
    $download_url_override,
    # SHA256 checksum to verify cached files (optional)
    [string]
    $checksum,
    # Set to 'once' to skip install if project is detected
    [string]
    $install_strategy
  )

  if ((Test-Path "$env:systemdrive\opscode\$project\embedded") -and ($install_strategy -eq 'once')) {
    Write-Host "$project installation detected"
    Write-Host "install_strategy set to 'once'"
    Write-Host "Nothing to install"
    exit
  }

  # Set http_proxy as env var
  if(-not [string]::IsNullOrEmpty($http_proxy)) {
    $env:http_proxy = $http_proxy
  }

  $cached_installer_available = $false
  $verify_checksum = $true
  
  if (-not [string]::IsNullOrEmpty($download_url_override)) {
    $download_url = $download_url_override
    $sha256 = $checksum
  } else {
    $package_metadata = Get-ProjectMetadata -project $project -channel $channel -version $version -prerelease:$prerelease -nightlies:$nightlies -architecture $architecture
    $download_url = $package_metadata.url
    $sha256 = $package_metadata.sha256
  }

  if (-not [string]::IsNullOrEmpty($filename)) {
    $download_directory = split-path $filename
    $filename = split-path $filename -leaf
    if ([string]::IsNullOrEmpty($download_directory)) {
      $download_directory = $pwd
    }
  }
  else {
    $filename = ($download_url -split '/')[-1]
  }
  Write-Verbose "Download directory: $download_directory"
  Write-Verbose "Filename: $filename"

  if (-not (test-path $download_directory)) {
    mkdir $download_directory
  }

  $download_directory = (resolve-path $download_directory).providerpath
  $download_destination = join-path $download_directory $filename

  if ((test-path $download_destination)) {
    Write-Verbose "Found existing installer at $download_destination."
    if (-not [string]::IsNullOrEmpty($sha256)) {
      Write-Verbose "Checksum specified"
      $valid_checksum = Test-ProjectPackage -Path $download_destination -Algorithm 'SHA256' -Hash $sha256
      if ($valid_checksum -eq $true) {
        Write-Verbose "Checksum verified, using existing installer."
        $cached_installer_available=$true # local file OK
        $verify_checksum = $false # no need to re-verify checksums
      }
      else {
        Write-Verbose "Checksum mismatch, ignoring existing installer."
        $cached_installer_available=$false # bad local file
        $verify_checksum = $false # re-verify checksums
      }
    }
    else {
      Write-Verbose "Checksum not specified, existing installer ignored."
      $cached_installer_available=$false # ignore local file
      $verify_checksum = $false # no checksum to compare
    }
  }

  if (-not ($cached_installer_available)) {
    if ($pscmdlet.ShouldProcess("$($download_url)", "Download $project")) {
      Write-Verbose "Downloading $project from $($download_url) to $download_destination."
      Get-WebContent $download_url -filepath $download_destination
    }
  }

  if ($pscmdlet.ShouldProcess("$download_destination", "Installing")) {
    if (($verify_checksum) -and (-not (Test-ProjectPackage -Path $download_destination -Algorithm 'SHA256' -Hash $sha256))) {
      throw "Failed to validate the downloaded installer for $project."
    }

    Write-Host "Installing $project from $download_destination"
    $installingProject = $True
    $installAttempts = 0
    while ($installingProject) {
      $installAttempts++
      $result = $false
      if($download_destination.EndsWith(".appx")) {
        $result = Install-ChefAppx $download_destination $project
      }
      else {
        $result = Install-ChefMsi $download_destination $daemon
      }
      if(!$result) { continue }
      $installingProject = $False
    }
  }
}
set-alias install -value Install-Project

Function Install-ChefMsi($msi, $addlocal) {
  if ($addlocal -eq "service") {
    $p = Start-Process -FilePath "msiexec.exe" -ArgumentList "/qn /i $msi ADDLOCAL=`"ChefClientFeature,ChefServiceFeature`"" -Passthru -Wait -NoNewWindow
  }
  ElseIf ($addlocal -eq "task") {
    $p = Start-Process -FilePath "msiexec.exe" -ArgumentList "/qn /i $msi ADDLOCAL=`"ChefClientFeature,ChefSchTaskFeature`"" -Passthru -Wait -NoNewWindow
  }
  ElseIf ($addlocal -eq "auto") {
    $p = Start-Process -FilePath "msiexec.exe" -ArgumentList "/qn /i $msi" -Passthru -Wait -NoNewWindow
  }

  $p.WaitForExit()
  if ($p.ExitCode -eq 1618) {
    Write-Host "$((Get-Date).ToString()) - Another msi install is in progress (exit code 1618), retrying ($($installAttempts))..."
    return $false
  } elseif ($p.ExitCode -ne 0) {
    throw "msiexec was not successful. Received exit code $($p.ExitCode)"
  }
  return $true
}

Function Install-ChefAppx($appx, $project) {
  Add-AppxPackage -Path $appx -ErrorAction Stop
  $package = (Get-AppxPackage -Name $project).InstallLocation
  $installRoot = "$env:SystemDrive/opscode"
  $omnibusRoot = Join-Path $installRoot $project

  if(!(Test-Path $installRoot)) {
    New-Item -ItemType Directory -Path $installRoot
  }

  # Remove old version of chef if it is here
  if(Test-Path $omnibusRoot) {
    Remove-Item -Path $omnibusRoot -Recurse -Force
  }

  # copy the appx install to the omnibus root. There are serious
  # ACL related issues with running chef from the appx InstallLocation
  # Hoping this is temporary and we can eventually just symlink
  Copy-Item $package $omnibusRoot -Recurse

  return $true
}

export-modulemember -function 'Install-Project','Get-ProjectMetadata' -alias 'install'
