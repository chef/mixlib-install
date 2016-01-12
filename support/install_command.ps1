Function Check-UpdateChef($root, $version) {
  if (-Not (Test-Path $root)) { return $true }
  elseif ("$version" -eq "true") { return $false }
  elseif ("$version" -eq "latest") { return $true }

  Try { $chef_version = (Get-Content $root\version-manifest.txt | select-object -first 1) }
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
  return @($md.url, $md.md5)
}

Function Get-MD5Sum($src) {
  Try {
    $c = New-Object -TypeName System.Security.Cryptography.MD5CryptoServiceProvider
    $bytes = $c.ComputeHash(($in = (Get-Item $src).OpenRead()))
    return ([System.BitConverter]::ToString($bytes)).Replace("-", "").ToLower()
  } Finally { if (($c -ne $null) -and ($c.GetType().GetMethod("Dispose") -ne $null)) { $c.Dispose() }; if ($in -ne $null) { $in.Dispose() } }
}

Function Download-Chef($url, $md5, $dst) {
  Try {
    Log "Downloading package from $url"
    ($c = Make-WebClient).DownloadFile($url, $dst)
    Log "Download complete."
  } Finally { if ($c -ne $null) { $c.Dispose() } }

  if ($md5 -eq $null) { Log "Skipping md5 verification" }
  elseif (($dmd5 = Get-MD5Sum $dst) -eq $md5) { Log "Successfully verified $dst" }
  else { throw "MD5 for $dst $dmd5 does not match $md5" }
}

Function Install-Chef($msi) {
  Log "Installing Chef Omnibus package $msi"
  $p = Start-Process -FilePath "msiexec.exe" -ArgumentList "/qn /i $msi" -Passthru -Wait

  if ($p.ExitCode -ne 0) { throw "msiexec was not successful. Received exit code $($p.ExitCode)" }

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
    $url, $md5 = Get-ChefMetadata "$chef_metadata_url"
  } else {
    $url = $chef_msi_url
    $md5 = $null
  }
  Download-Chef "$url" $md5 $msi
  Install-Chef $msi
} else {
  Write-Host "-----> Chef Omnibus installation detected ($pretty_version)`n"
}
