function Get-PlatformVersion {
  switch -regex ((Get-WMIQuery win32_operatingsystem).version) {
    '10\.0\.\d+' {$platform_version = '2016'}
    '6\.3\.\d+'  {$platform_version = '2012r2'}
    '6\.2\.\d+'  {$platform_version = '2012'}
    '6\.1\.\d+'  {$platform_version = '2008r2'}
    '6\.0\.\d+'  {$platform_version = '2008'}
  }

  if(Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Server\ServerLevels') {
    $levels = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Server\ServerLevels'
    if($levels.NanoServer -eq 1) { $platform_version += 'nano' }
  }

  return $platform_version
}

function Get-PlatformArchitecture {
  if ((Get-WMIQuery win32_operatingsystem).osarchitecture -like '64-bit') {
    $architecture = 'x86_64'
  } else {
    $architecture = 'i386'
  }
  return $architecture
}

function New-Uri {
  param ($baseuri, $newuri)

  try {
    $base = new-object System.Uri $baseuri
    new-object System.Uri $base, $newuri
  }
  catch [System.Management.Automation.MethodInvocationException]{
    Write-Error "$($_.exception.message)"
    throw $_.exception
  }
}

function Get-WebContent {
  param ($uri, $filepath)

  try {
    if($PSVersionTable.PSEdition -eq 'Core') {
      Get-WebContentOnCore $uri $filepath
    }
    else {
      Get-WebContentOnFullNet $uri $filepath
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

function Get-WebContentOnFullNet {
  param ($uri, $filepath)

  $proxy = New-Object -TypeName System.Net.WebProxy
  $wc = new-object System.Net.WebClient
  $proxy.Address = $env:http_proxy
  $wc.Proxy = $proxy

  if ([string]::IsNullOrEmpty($filepath)) {
    $wc.downloadstring($uri)
  }
  else {
    $wc.downloadfile($uri, $filepath)
  }
}

function Get-WebContentOnCore {
  param ($uri, $filepath)

  $handler = New-Object System.Net.Http.HttpClientHandler
  $client = New-Object System.Net.Http.HttpClient($handler)
  $client.Timeout = New-Object System.TimeSpan(0, 30, 0)
  $cancelTokenSource = [System.Threading.CancellationTokenSource]::new()
  $responseMsg = $client.GetAsync([System.Uri]::new($uri), $cancelTokenSource.Token)
  $responseMsg.Wait()
  if (!$responseMsg.IsCanceled) {
    $response = $responseMsg.Result
    if ($response.IsSuccessStatusCode) {
      if ([string]::IsNullOrEmpty($filepath)) {
        $response.Content.ReadAsStringAsync().Result
      }
      else {
        $downloadedFileStream = [System.IO.FileStream]::new($filepath, [System.IO.FileMode]::Create, [System.IO.FileAccess]::Write)
        $copyStreamOp = $response.Content.CopyToAsync($downloadedFileStream)
        $copyStreamOp.Wait()
        $downloadedFileStream.Close()
        if ($copyStreamOp.Exception -ne $null) {
          throw $copyStreamOp.Exception
        }
      }
    }
  }
}

function Test-ProjectPackage {
  [cmdletbinding()]
  param ($Path, $Algorithm = 'SHA256', $Hash)

  if (-not (get-command get-filehash -ErrorAction 'SilentlyContinue')) {
    function disposable($o){($o -is [IDisposable]) -and (($o | get-member | foreach-object {$_.name}) -contains 'Dispose')}
    function use($obj, [scriptblock]$sb){try {& $sb} catch [exception]{throw $_} finally {if (disposable $obj) {$obj.Dispose()}} }
    function Get-FileHash ($Path, $Algorithm) {
      $Path = (resolve-path $path).providerpath
      $hash = @{Algorithm = $Algorithm; Path = $Path}
      use ($c = Get-SHA256Converter) {
        use ($in = (gi $path).OpenRead()) {
          $hash.Hash = ([BitConverter]::ToString($c.ComputeHash($in))).Replace("-", "").ToUpper()
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

function Get-SHA256Converter {
  if($PSVersionTable.PSEdition -eq 'Core') {
    [System.Security.Cryptography.SHA256]::Create()
  }
  else {
    New-Object -TypeName Security.Cryptography.SHA256Managed
  }
}

function Get-WMIQuery {
  param ($class)

  if(Get-Command -Name Get-CimInstance -ErrorAction SilentlyContinue) {
    Get-CimInstance $class
  }
  else {
    Get-WmiObject $class
  }
}
