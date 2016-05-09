Function Check-UpdateChef($root, $version) {
  if (-Not (Test-Path $root)) { return $true }
  elseif ("$version" -eq "true") { return $false }
  elseif ("$version" -eq "latest") { return $true }

  Try { $chef_version = (Get-Content $root\version-manifest.txt  -ErrorAction stop | select-object -first 1) }
  Catch {
    Try { $chef_version = (& $root\bin\chef-solo.bat -v) }
    Catch { $chef_version = " " }
  }

  if ($chef_version.split(" ", 2)[1].StartsWith($version)) { return $false }
  else { return $true }
}

Function Get-ChefMetadata($url) {
  Try { $response = ($c = Make-WebClient).DownloadString($url) }
  Finally { if ($c -ne $null) { $c.Dispose() } }

  $md = ConvertFrom-StringData $response.Replace("`t", "=")
  return @($md.url, $md.sha256)
}

Function Get-SHA256($src) {
  Try {
    $c = New-Object -TypeName System.Security.Cryptography.SHA256Managed
    $bytes = $c.ComputeHash(($in = (Get-Item $src).OpenRead()))
    return ([System.BitConverter]::ToString($bytes)).Replace("-", "").ToLower()
  } Finally { if (($c -ne $null) -and ($c.GetType().GetMethod("Dispose") -ne $null)) { $c.Dispose() }; if ($in -ne $null) { $in.Dispose() } }
}

Function Download-Chef($url, $sha256, $dst) {
  Try {
    Log "Downloading package from $url"
    ($c = Make-WebClient).DownloadFile($url, $dst)
    Log "Download complete."
  } Finally { if ($c -ne $null) { $c.Dispose() } }

  if ($sha256 -eq $null) { Log "Skipping sha256 verification" }
  elseif (($dsha256 = Get-SHA256 $dst) -eq $sha256) { Log "Successfully verified $dst" }
  else { throw "SHA256 for $dst $dsha256 does not match $sha256" }
}

Function Install-Chef($msi) {
  Log "Installing Chef Omnibus package $msi"
  $installingChef = $True
  $installAttempts = 0
  while ($installingChef) {
    $installAttempts++
    $p = Start-Process -FilePath "msiexec.exe" -ArgumentList "/qn /i $msi" -Passthru -Wait
    $p.WaitForExit()
    if ($p.ExitCode -eq 1618) {
      Log "Another msi install is in progress (exit code 1618), retrying ($($installAttempts))..."
      continue
    } elseif ($p.ExitCode -ne 0) {
      throw "msiexec was not successful. Received exit code $($p.ExitCode)"
    }
    $installingChef = $False
  }
  Remove-Item $msi -Force
  Log "Installation complete"
}

Function Log($m) { Write-Host "       $m`n" }

Function Make-WebClient {
  $proxy = New-Object -TypeName System.Net.WebProxy
  $proxy.Address = $env:http_proxy
  $client = New-Object -TypeName System.Net.WebClient
  $client.Proxy = $proxy
  return $client
}

Function Unresolve-Path($p) {
  if ($p -eq $null) { return $null }
  else { return $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($p) }
}

$chef_omnibus_root = Unresolve-Path $chef_omnibus_root
$msi = Unresolve-Path $msi

if (Check-UpdateChef $chef_omnibus_root $version) {
  Write-Host "-----> Installing Chef Omnibus ($pretty_version)`n"
  if ($chef_metadata_url -ne $null) {
    $url, $sha256 = Get-ChefMetadata "$chef_metadata_url"
  } else {
    $url = $chef_msi_url
    $sha256 = $null
  }
  Download-Chef "$url" $sha256 $msi
  Install-Chef $msi
} else {
  Write-Host "-----> Chef Omnibus installation detected ($pretty_version)`n"
}
