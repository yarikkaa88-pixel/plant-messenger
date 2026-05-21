$ErrorActionPreference = "Stop"

Write-Host "=== PLANT local launcher ===" -ForegroundColor Green

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
  Write-Host "Flutter не найден в PATH. Установите Flutter SDK и откройте новый терминал." -ForegroundColor Red
  exit 1
}

$npmCommand = Get-Command npm -ErrorAction SilentlyContinue
if (-not $npmCommand) {
  $npmCommand = Get-Command npm.cmd -ErrorAction SilentlyContinue
}
if (-not $npmCommand) {
  Write-Host "npm не найден. Установите Node.js LTS и откройте новый терминал." -ForegroundColor Red
  exit 1
}

$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$backendDir = Join-Path $repoRoot "backend"
$backendEnv = Join-Path $backendDir ".env"

if (-not (Test-Path $backendDir)) {
  Write-Host "Папка backend не найдена: $backendDir" -ForegroundColor Red
  exit 1
}

if (-not (Test-Path $backendEnv)) {
  Write-Host "Не найден backend/.env. Скопируйте backend/.env.example в backend/.env и заполните DATABASE_URL." -ForegroundColor Red
  exit 1
}

Write-Host "[1/5] Установка backend зависимостей..."
Push-Location $backendDir
& $npmCommand.Source install

Write-Host "[2/5] Подготовка Prisma..."
& $npmCommand.Source run prisma:generate
& $npmCommand.Source run prisma:migrate
& $npmCommand.Source run prisma:seed
Pop-Location

Write-Host "[3/5] Запуск backend в отдельном окне..."
$backendCommand = "cd /d `"$backendDir`" && npm.cmd start"
Start-Process -FilePath "cmd.exe" -ArgumentList "/k", $backendCommand | Out-Null

Write-Host "[4/5] Установка flutter зависимостей..."
Push-Location $repoRoot
flutter pub get

Write-Host "[5/5] Запуск Flutter..."
flutter run
Pop-Location
