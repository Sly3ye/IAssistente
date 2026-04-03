param(
  [string]$DeviceId = "emulator-5554"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

# Keep localhost websocket/protocol traffic out of corporate proxies.
Remove-Item Env:HTTP_PROXY -ErrorAction SilentlyContinue
Remove-Item Env:HTTPS_PROXY -ErrorAction SilentlyContinue
Remove-Item Env:http_proxy -ErrorAction SilentlyContinue
Remove-Item Env:https_proxy -ErrorAction SilentlyContinue
$env:NO_PROXY = "localhost,127.0.0.1,::1"

flutter run -d $DeviceId --no-dds
