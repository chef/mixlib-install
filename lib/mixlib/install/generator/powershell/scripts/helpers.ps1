function New-Uri {
  param ($baseuri, $newuri)

  new-object System.Uri $baseuri, $newuri
}

function Get-WebContent {
  param ($uri, $filepath)
  $proxy = New-Object -TypeName System.Net.WebProxy
  $wc = new-object System.Net.WebClient
  $proxy.Address = $env:http_proxy
  $wc.Proxy = $proxy

  try {
    if ([string]::IsNullOrEmpty($filepath)) {
      $wc.downloadstring($uri)
    }
    else {
      $wc.downloadfile($uri, $filepath)
    }
  }
  catch {
    $exception = $_.Exception
    Write-Host "There was an error: "
    do {
      Write-Host "`t$($exception.message)"
      $exception = $exception.innerexception
    } while ($exception)
    throw "Failed to download from $uri."
  }
}

function Test-ProjectPackage {
  [cmdletbinding()]
  param ($Path, $Algorithm = 'SHA256', $Hash)

  if (-not (get-command get-filehash))   {
    function disposable($o){($o -is [IDisposable]) -and (($o | get-member | foreach-object {$_.name}) -contains 'Dispose')}
    function use($obj, [scriptblock]$sb){try {& $sb} catch [exception]{throw $_} finally {if (disposable $obj) {$obj.Dispose()}} }
    function Get-FileHash ($Path, $Algorithm) {
      $Path = (resolve-path $path).providerpath
      $hash = @{Algorithm = $Algorithm; Path = $Path}
      if ($Algorithm -like 'MD5') {
        use ($c = New-Object -TypeName Security.Cryptography.MD5CryptoServiceProvider) {
          use ($in = (gi $path).OpenRead()) {
            $hash.Hash = ([BitConverter]::ToString($c.ComputeHash($in))).Replace("-", "").ToUpper()
          }
        }
      }
      elseif ($Algorithm -like 'SHA256') {
        use ($c = New-Object -TypeName Security.Cryptography.SHA256CryptoServiceProvider) {
          use ($in = (gi $path).OpenRead()) {
            $hash.Hash = ([BitConverter]::ToString($c.ComputeHash($in))).Replace("-", "").ToUpper()
          }
        }
      }
      new-object PSObject -Property $hash
    }
  }
  Write-Verbose "Testing the $Algorithm hash for $path."
  $ActualHash = (Get-FileHash -Algorithm $Algorithm -Path $Path).Hash.ToLower()
  Write-Verbose "`tDesired Hash - '$hash'"
  Write-Verbose "`tActual Hash  - '$ActualHash'"
  $Valid = $ActualHash -eq $Hash
  if (-not $Valid) {
    Write-Error "Failed to validate the downloaded installer.  The expected $Algorithm hash was '$Hash' and the actual hash was '$ActualHash' for $path"
  }
  return $Valid
}
