Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

if (-not (Test-Path ".env")) {
  Copy-Item ".env.example" ".env"
}

# Keep localhost websocket/protocol traffic out of corporate proxies.
Remove-Item Env:HTTP_PROXY -ErrorAction SilentlyContinue
Remove-Item Env:HTTPS_PROXY -ErrorAction SilentlyContinue
Remove-Item Env:http_proxy -ErrorAction SilentlyContinue
Remove-Item Env:https_proxy -ErrorAction SilentlyContinue
$env:NO_PROXY = "localhost,127.0.0.1,::1"

& "$PSScriptRoot\\check_runtime_config.ps1"
& "$PSScriptRoot\\release_gate.ps1" -ExpectedPackage "it.dallacog.mimir" -Relaxed
flutter pub get
flutter analyze
flutter test -r compact

Set-Location "$root\\proxy-server"
node --check server.mjs

Write-Host "Local smoke checks passed."
