param(
  [string]$ExpectedPackage = "it.dallacog.mimir",
  [switch]$Relaxed
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Fail([string]$Message) {
  throw $Message
}

function Get-EnvMap([string]$EnvFilePath) {
  $map = @{}
  Get-Content $EnvFilePath | ForEach-Object {
    $line = $_.Trim()
    if ([string]::IsNullOrWhiteSpace($line)) { return }
    if ($line.StartsWith("#")) { return }
    $parts = $line.Split("=", 2)
    if ($parts.Length -ne 2) { return }
    $map[$parts[0].Trim()] = $parts[1].Trim()
  }
  return $map
}

function Get-Value([hashtable]$Map, [string]$Key) {
  if ($Map.ContainsKey($Key)) { return "$($Map[$Key])".Trim() }
  return ""
}

$root = Split-Path -Parent $PSScriptRoot
$gradleFile = Join-Path $root "android/app/build.gradle.kts"
$pubspecFile = Join-Path $root "pubspec.yaml"
$envFile = Join-Path $root ".env"
$googleServicesFile = Join-Path $root "android/app/google-services.json"
$keystoreRoot = Join-Path $root "keystore.properties"
$keystoreAndroid = Join-Path $root "android/keystore.properties"

if (-not (Test-Path $gradleFile)) { Fail "Missing file: $gradleFile" }
if (-not (Test-Path $pubspecFile)) { Fail "Missing file: $pubspecFile" }
if (-not (Test-Path $googleServicesFile)) { Fail "Missing file: $googleServicesFile" }

$gradleContent = Get-Content $gradleFile -Raw
$namespaceMatch = [regex]::Match($gradleContent, '(?m)^\s*namespace\s*=\s*"([^"]+)"')
$appIdMatch = [regex]::Match($gradleContent, '(?m)^\s*applicationId\s*=\s*"([^"]+)"')
if (-not $namespaceMatch.Success) { Fail "Cannot parse namespace from android/app/build.gradle.kts" }
if (-not $appIdMatch.Success) { Fail "Cannot parse applicationId from android/app/build.gradle.kts" }

$namespace = $namespaceMatch.Groups[1].Value.Trim()
$applicationId = $appIdMatch.Groups[1].Value.Trim()
if ($namespace -ne $ExpectedPackage) {
  Fail "namespace mismatch: expected '$ExpectedPackage', found '$namespace'"
}
if ($applicationId -ne $ExpectedPackage) {
  Fail "applicationId mismatch: expected '$ExpectedPackage', found '$applicationId'"
}

$pubspecContent = Get-Content $pubspecFile -Raw
$versionMatch = [regex]::Match($pubspecContent, '(?m)^version:\s*([0-9]+\.[0-9]+\.[0-9]+\+[0-9]+)\s*$')
if (-not $versionMatch.Success) {
  Fail "Invalid or missing version in pubspec.yaml. Expected format x.y.z+build."
}

if (-not $Relaxed) {
  if (-not (Test-Path $envFile)) { Fail "Missing file: $envFile" }
  $envMap = Get-EnvMap $envFile

  $appEnv = (Get-Value $envMap "APP_ENV").ToLowerInvariant()
  $devBypassAuth = (Get-Value $envMap "DEV_BYPASS_AUTH").ToLowerInvariant()
  $allowClientLlmInProd = (Get-Value $envMap "ALLOW_CLIENT_SIDE_LLM_IN_PRODUCTION").ToLowerInvariant()
  $proxyUrl = Get-Value $envMap "LLM_PROXY_URL"
  $proxyProvider = Get-Value $envMap "LLM_PROXY_PROVIDER"
  $proxyAuthToken = Get-Value $envMap "LLM_PROXY_AUTH_TOKEN"
  $openaiKey = Get-Value $envMap "OPENAI_API_KEY"
  $anthropicKey = Get-Value $envMap "ANTHROPIC_API_KEY"
  $geminiKey = Get-Value $envMap "GEMINI_API_KEY"

  if ($appEnv -ne "production") {
    Fail "APP_ENV must be production for release. Current: '$appEnv'"
  }
  if ($devBypassAuth -ne "false") {
    Fail "DEV_BYPASS_AUTH must be false for release. Current: '$devBypassAuth'"
  }
  if ($allowClientLlmInProd -ne "false") {
    Fail "ALLOW_CLIENT_SIDE_LLM_IN_PRODUCTION must be false for release. Current: '$allowClientLlmInProd'"
  }
  if ([string]::IsNullOrWhiteSpace($proxyUrl)) {
    Fail "LLM_PROXY_URL is required for release."
  }
  if ([string]::IsNullOrWhiteSpace($proxyProvider)) {
    Fail "LLM_PROXY_PROVIDER is required when LLM_PROXY_URL is set."
  }
  if (-not $proxyUrl.StartsWith("https://", [System.StringComparison]::OrdinalIgnoreCase)) {
    Fail "LLM_PROXY_URL must use https:// in release. Current: '$proxyUrl'"
  }
  if ($proxyUrl -match '(?i)(localhost|127\.0\.0\.1|0\.0\.0\.0|10\.0\.2\.2)') {
    Fail "LLM_PROXY_URL cannot point to local host in release. Current: '$proxyUrl'"
  }
  if (-not [string]::IsNullOrWhiteSpace($openaiKey)) {
    Fail "OPENAI_API_KEY must be empty in client .env for release."
  }
  if (-not [string]::IsNullOrWhiteSpace($anthropicKey)) {
    Fail "ANTHROPIC_API_KEY must be empty in client .env for release."
  }
  if (-not [string]::IsNullOrWhiteSpace($geminiKey)) {
    Fail "GEMINI_API_KEY must be empty in client .env for release."
  }
  if ([string]::IsNullOrWhiteSpace($proxyAuthToken)) {
    Write-Warning "LLM_PROXY_AUTH_TOKEN is empty. Keep it empty only if your proxy does not require bearer auth."
  }
  if (-not (Test-Path $keystoreRoot) -and -not (Test-Path $keystoreAndroid)) {
    Fail "Missing keystore.properties. Create it from keystore.properties.example (root or android folder)."
  }
}

Write-Host "Release gate passed. Package=$ExpectedPackage Version=$($versionMatch.Groups[1].Value) Relaxed=$Relaxed"
