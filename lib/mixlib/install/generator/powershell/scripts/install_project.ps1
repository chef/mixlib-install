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
    $architecture = 'auto'
  )

  $package_metadata = Get-ProjectMetadata -project $project -channel $channel -version $version -prerelease:$prerelease -nightlies:$nightlies -architecture $architecture

  if (-not [string]::IsNullOrEmpty($filename)) {
    $download_directory = split-path $filename
    $filename = split-path $filename -leaf
    if ([string]::IsNullOrEmpty($download_directory)) {
      $download_directory = $pwd
    }
  }
  else {
    $filename = ($package_metadata.url -split '/')[-1]
  }
  Write-Verbose "Download directory: $download_directory"
  Write-Verbose "Filename: $filename"

  if (-not (test-path $download_directory)) {
    mkdir $download_directory
  }
  $download_directory = (resolve-path $download_directory).providerpath
  $download_destination = join-path $download_directory $filename

  if ((test-path $download_destination) -and
    (Test-ProjectPackage -Path $download_destination -Algorithm 'SHA256' -Hash $package_metadata.sha256 -ea SilentlyContinue)){
    Write-Verbose "Found existing valid installer at $download_destination."
  }
  else {
    if ($pscmdlet.ShouldProcess("$($package_metadata.url)", "Download $project")) {
      Write-Verbose "Downloading $project from $($package_metadata.url) to $download_destination."
      Get-WebContent $package_metadata.url -filepath $download_destination
    }
  }

  if ($pscmdlet.ShouldProcess("$download_destination", "Installing")){
    if (Test-ProjectPackage -Path $download_destination -Algorithm 'SHA256' -Hash $package_metadata.sha256) {
      Write-Host "Installing $project from $download_destination"
      $installingProject = $True
      $installAttempts = 0
      while ($installingProject) {
        $p = Start-Process -FilePath "msiexec" -ArgumentList "/qn /i $download_destination" -Passthru -Wait
        $p.WaitForExit()
        if ($p.ExitCode -eq 1618) {
          Write-Host "Another msi install is in progress (exit code 1618), retrying ($($installAttempts))..."
          continue
        } elseif ($p.ExitCode -ne 0) {
          throw "msiexec was not successful. Received exit code $($p.ExitCode)"
        }
        $installingProject = $False
      }
    }
    else {
      throw "Failed to validate the downloaded installer for $project."
    }
  }
}
set-alias install -value Install-Project
export-modulemember -function 'Install-Project','Get-ProjectMetadata' -alias 'install'
