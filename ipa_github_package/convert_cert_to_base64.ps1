# Конвертация сертификата Apple в Base64 для GitHub Secrets
# Запуск: правой кнопкой → "Выполнить с PowerShell"
# или: .\convert_cert_to_base64.ps1

Write-Host ""
Write-Host "=== PLANT: конвертация в Base64 для GitHub ===" -ForegroundColor Green
Write-Host ""

$p12Path = Read-Host "Путь к файлу .p12 (сертификат)"
$profilePath = Read-Host "Путь к файлу .mobileprovision (профиль)"

if (-not (Test-Path $p12Path)) {
    Write-Host "Файл не найден: $p12Path" -ForegroundColor Red
    exit 1
}
if (-not (Test-Path $profilePath)) {
    Write-Host "Файл не найден: $profilePath" -ForegroundColor Red
    exit 1
}

$certBase64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes($p12Path))
$profileBase64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes($profilePath))

$outDir = Join-Path $PSScriptRoot "secrets_output"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

$certBase64 | Out-File -FilePath (Join-Path $outDir "BUILD_CERTIFICATE_BASE64.txt") -Encoding utf8 -NoNewline
$profileBase64 | Out-File -FilePath (Join-Path $outDir "BUILD_PROVISION_PROFILE_BASE64.txt") -Encoding utf8 -NoNewline

Write-Host ""
Write-Host "Готово! Файлы сохранены в:" -ForegroundColor Green
Write-Host "  $outDir"
Write-Host ""
Write-Host "Скопируйте содержимое в GitHub Secrets:" -ForegroundColor Yellow
Write-Host "  BUILD_CERTIFICATE_BASE64      <- BUILD_CERTIFICATE_BASE64.txt"
Write-Host "  BUILD_PROVISION_PROFILE_BASE64 <- BUILD_PROVISION_PROFILE_BASE64.txt"
Write-Host "  P12_PASSWORD                  <- пароль от .p12 (вручную)"
Write-Host "  KEYCHAIN_PASSWORD             <- любой пароль (вручную)"
Write-Host ""
Write-Host "НЕ заливайте папку secrets_output на GitHub!" -ForegroundColor Red
Write-Host ""
