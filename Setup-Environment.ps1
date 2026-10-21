$ErrorActionPreference = "Stop"

$environmentPath = Join-Path $PSScriptRoot ".env"
$examplePath = Join-Path $PSScriptRoot ".env.example"

if (-not (Test-Path $environmentPath)) {
    if (-not (Test-Path $examplePath)) {
        Write-Error ".env.example is missing."
        exit 1
    }
    Copy-Item $examplePath $environmentPath
}

$existingLines = [System.IO.File]::ReadAllLines($environmentPath)
$values = @{}
foreach ($line in $existingLines) {
    $trimmed = $line.Trim()
    if ([string]::IsNullOrWhiteSpace($trimmed) -or $trimmed.StartsWith("#")) {
        continue
    }
    if ($trimmed -match "^([^=]+?)\s*=\s*(.*)$") {
        $key = $Matches[1].Trim()
        $value = $Matches[2].Trim()
        $values[$key] = $value
    }
}

function Get-PreferredLocalHost {
    return "localhost"
}

$preferredHost = Get-PreferredLocalHost
$expectedAdminEmail = "admin@nexux.local"
$expectedAdminPassword = "ChangeMeNow123!"
$expectedApiBase = "http://localhost:8000"
$originList = @(
    "http://localhost:3000",
    "http://127.0.0.1:3000",
    "http://localhost:8000",
    "http://127.0.0.1:8000"
)
$originList = @($originList | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | ForEach-Object { $_.Trim() } | Select-Object -Unique)
$expectedOrigins = ($originList -join ",")

$secret = $values["SESSION_SECRET"]
if ([string]::IsNullOrWhiteSpace($secret)) {
    $bytes = New-Object byte[] 48
    $random = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    try {
        $random.GetBytes($bytes)
    }
    finally {
        $random.Dispose()
    }
    $secret = [Convert]::ToBase64String($bytes)
}

$chatDefaultProvider = $values["CHAT_DEFAULT_PROVIDER"]
if ([string]::IsNullOrWhiteSpace($chatDefaultProvider)) {
    $chatDefaultProvider = "openai_compatible"
}

$ollamaModels = $values["OLLAMA_CHAT_MODELS"]
if ([string]::IsNullOrWhiteSpace($ollamaModels)) {
    $ollamaModels = "qwen2.5vl:3b"
}

$openaiBaseUrl = $values["OPENAI_BASE_URL"]
if ([string]::IsNullOrWhiteSpace($openaiBaseUrl)) {
    $openaiBaseUrl = "https://api.openai.com/v1"
}

$openaiApiKey = $values["OPENAI_API_KEY"]
if ([string]::IsNullOrWhiteSpace($openaiApiKey)) {
    $openaiApiKey = ""
}

$openaiChatModels = $values["OPENAI_CHAT_MODELS"]
if ([string]::IsNullOrWhiteSpace($openaiChatModels)) {
    $openaiChatModels = "gemini-3.5-flash-lite"
}

$sanitized = @(
    "SESSION_SECRET=$secret",
    "ADMIN_EMAIL=$expectedAdminEmail",
    "ADMIN_PASSWORD=$expectedAdminPassword",
    "NEXT_PUBLIC_API_BASE_URL=$expectedApiBase",
    "FRONTEND_ORIGINS=$expectedOrigins",
    "COOKIE_SECURE=false",
    "CHAT_DEFAULT_PROVIDER=$chatDefaultProvider",
    "OLLAMA_CHAT_MODELS=$ollamaModels",
    "OPENAI_BASE_URL=$openaiBaseUrl",
    "OPENAI_API_KEY=$openaiApiKey",
    "OPENAI_CHAT_MODELS=$openaiChatModels"
)

$before = [System.IO.File]::ReadAllText($environmentPath)
$finalText = ($sanitized -join [Environment]::NewLine) + [Environment]::NewLine
if ($before -ne $finalText) {
    [System.IO.File]::WriteAllText($environmentPath, $finalText, (New-Object System.Text.UTF8Encoding($false)))
    Write-Output "Local environment prepared"
}
else {
    Write-Output "Using existing local environment settings"
}
