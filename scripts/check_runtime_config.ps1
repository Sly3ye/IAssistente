Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$envFile = Join-Path $root ".env"

if (-not (Test-Path $envFile)) {
  Write-Error "Config file missing: $envFile"
}

$kv = @{}
Get-Content $envFile | ForEach-Object {
  $line = $_.Trim()
  if ([string]::IsNullOrWhiteSpace($line)) { return }
  if ($line.StartsWith("#")) { return }
  $parts = $line.Split("=", 2)
  if ($parts.Length -ne 2) { return }
  $kv[$parts[0].Trim()] = $parts[1].Trim()
}

$appEnv = if ($kv.ContainsKey("APP_ENV")) { $kv["APP_ENV"] } else { "" }
$appEnv = $appEnv.Trim().ToLowerInvariant()
if ([string]::IsNullOrWhiteSpace($appEnv)) {
  Write-Error "Missing key in .env: APP_ENV"
}

$proxyUrl = if ($kv.ContainsKey("LLM_PROXY_URL")) { $kv["LLM_PROXY_URL"] } else { "" }
$proxyProvider = if ($kv.ContainsKey("LLM_PROXY_PROVIDER")) { $kv["LLM_PROXY_PROVIDER"] } else { "" }
$openaiKey = if ($kv.ContainsKey("OPENAI_API_KEY")) { $kv["OPENAI_API_KEY"] } else { "" }
$anthropicKey = if ($kv.ContainsKey("ANTHROPIC_API_KEY")) { $kv["ANTHROPIC_API_KEY"] } else { "" }
$geminiKey = if ($kv.ContainsKey("GEMINI_API_KEY")) { $kv["GEMINI_API_KEY"] } else { "" }

$proxyUrl = $proxyUrl.Trim()
$proxyProvider = $proxyProvider.Trim()
$openaiKey = $openaiKey.Trim()
$anthropicKey = $anthropicKey.Trim()
$geminiKey = $geminiKey.Trim()

$hasProxy = -not [string]::IsNullOrWhiteSpace($proxyUrl)
$hasDirect = (
  -not [string]::IsNullOrWhiteSpace($openaiKey) -or
  -not [string]::IsNullOrWhiteSpace($anthropicKey) -or
  -not [string]::IsNullOrWhiteSpace($geminiKey)
)

if ($hasProxy -and [string]::IsNullOrWhiteSpace($proxyProvider)) {
  Write-Error "LLM_PROXY_URL is set but LLM_PROXY_PROVIDER is empty."
}

if (-not $hasProxy -and -not $hasDirect) {
  if ($appEnv -eq "production") {
    Write-Error "Missing production LLM config: set LLM_PROXY_URL or at least one direct provider API key."
  }
  Write-Host "Warning: no remote LLM config found. Development can still run with local Ollama."
}

Write-Host "Runtime config check passed for APP_ENV=$appEnv."
