$ErrorActionPreference = 'Stop'
$repo = Split-Path $PSScriptRoot -Parent
$workspace = Split-Path $repo -Parent
$output = Join-Path $workspace 'outputs\android-local'
$sdk = Join-Path $env:LOCALAPPDATA 'Android\Sdk'
$adb = Join-Path $sdk 'platform-tools\adb.exe'
$emulator = Join-Path $sdk 'emulator\emulator.exe'
$device = 'emulator-5556'
$apk = Join-Path $output 'com.companyname.sudoku.mobile-Signed.apk'
if (!(Test-Path -LiteralPath $apk)) { $apk = Join-Path $repo 'apk\Sudoku.Mobile-Signed.apk' }
if (!(Test-Path -LiteralPath $apk)) { throw 'Build the Android Release APK first; see HUONG_DAN_CHAY_SUDOKU_ANDROID_STUDIO.md.' }
New-Item -ItemType Directory -Path $output -Force | Out-Null

if (!(Get-NetTCPConnection -LocalPort 5243 -State Listen -ErrorAction SilentlyContinue)) {
    $env:ASPNETCORE_ENVIRONMENT = 'Development'
    Start-Process -FilePath 'dotnet' -ArgumentList @((Join-Path $repo 'Sudoku.Api\bin\Debug\net10.0\Sudoku.Api.dll'), '--urls', 'http://127.0.0.1:5243') `
        -WorkingDirectory (Join-Path $repo 'Sudoku.Api') -WindowStyle Hidden `
        -RedirectStandardOutput (Join-Path $output 'api.log') -RedirectStandardError (Join-Path $output 'api-error.log')
}
if (!(Get-NetTCPConnection -LocalPort 5000 -State Listen -ErrorAction SilentlyContinue)) {
    Start-Process -FilePath (Join-Path $repo 'Sudoku.Server\bin\Debug\Sudoku.Server.exe') -WorkingDirectory $repo -WindowStyle Hidden
}
& $adb start-server | Out-Null
$devices = (& $adb devices) -join "`n"
if ($devices -notmatch "$device\s+device") {
    Start-Process -FilePath $emulator -ArgumentList '-avd Sudoku_Local -port 5556 -no-audio -no-boot-anim -gpu auto' `
        -RedirectStandardOutput (Join-Path $output 'emulator.log') -RedirectStandardError (Join-Path $output 'emulator-error.log')
}
Write-Output 'Waiting for Sudoku Local to finish booting...'
$deadline = (Get-Date).AddMinutes(4)
do {
    $booted = & $adb -s $device shell getprop sys.boot_completed 2>$null
    if ($booted -eq '1') { break }
    if ((Get-Date) -gt $deadline) { throw 'Android did not finish booting. Check outputs/android-local/emulator-error.log.' }
    Start-Sleep -Seconds 2
} while ($true)
& $adb -s $device install -r $apk
if ($LASTEXITCODE -ne 0) { throw 'Could not install Sudoku APK.' }
& $adb -s $device shell monkey -p com.companyname.sudoku.mobile -c android.intent.category.LAUNCHER 1
if ($LASTEXITCODE -ne 0) { throw 'Could not launch Sudoku.' }
Write-Output 'Sudoku is open. Login: test_player_a / SudokuTest!2026. Use a different account for the second player.'
