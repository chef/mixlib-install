# Stop script execution when a non-terminating error occurs
$ErrorActionPreference = "Stop"
# This will run ruby test on windows platform

Write-Output "--- Bundle install"

# bundle config set --local path vendor/cache
# If ($lastexitcode -ne 0) { Exit $lastexitcode }

bundle install --redownload --no-cache --retry=3
If ($lastexitcode -ne 0) { Exit $lastexitcode }

Write-Output "--- Bundle Execute"

bundle exec rake 
If ($lastexitcode -ne 0) { Exit $lastexitcode }
