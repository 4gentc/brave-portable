@echo off
setlocal
echo Brave Portable Updater v1.1 (Permission-Fixed)
echo ===============================
echo.
(
echo # Brave Updater with Permission Handling
echo $ErrorActionPreference = "Stop"
echo.
echo # Function to check admin privileges
echo function Test-IsAdmin {
echo   $identity = [Security.Principal.WindowsIdentity]::GetCurrent^(^)
echo   $principal = New-Object Security.Principal.WindowsPrincipal $identity
echo   return $principal.IsInRole^([Security.Principal.WindowsBuiltInRole]::Administrator^)
echo }
echo.
echo # Function to retry operations for locked files
echo function Invoke-WithRetry {
echo   param^([ScriptBlock]$ScriptBlock, [int]$MaxRetries = 5, [int]$DelaySeconds = 2^)
echo   $attempt = 0
echo   while ^($attempt -lt $MaxRetries^) {
echo     try {
echo       $attempt++
echo       ^& $ScriptBlock
echo       return $true
echo     } catch {
echo       if ^($attempt -ge $MaxRetries^) {
echo         Write-Host "Failed after $MaxRetries attempts: $_" -ForegroundColor Red
echo         throw
echo       }
echo       Write-Host "Attempt $attempt failed. Retrying in $DelaySeconds seconds..." -ForegroundColor Yellow
echo       Start-Sleep -Seconds $DelaySeconds
echo     }
echo   }
echo   return $false
echo }
echo.
echo # Function to safely remove item with retry
echo function Remove-ItemSafely {
echo   param^([string]$Path^)
echo   if ^(Test-Path $Path^) {
echo     Invoke-WithRetry -ScriptBlock {
echo       Remove-Item $Path -Force -Recurse -ErrorAction Stop
echo     } -MaxRetries 5 -DelaySeconds 2
echo   }
echo }
echo.
echo # Check for admin privileges
echo if ^(-not ^(Test-IsAdmin^)^) {
echo   Write-Host "WARNING: Running without administrator privileges." -ForegroundColor Yellow
echo   Write-Host "Some operations may fail. Consider running as administrator." -ForegroundColor Yellow
echo   Write-Host
echo   $continue = Read-Host "Continue anyway? (y/N)"
echo   if ^($continue -ne 'y' -and $continue -ne 'Y'^) { exit }
echo }
echo.
echo $bravePath = Join-Path "%~dp0" "brave.exe"
echo $apiUrl = "https://api.github.com/repos/4gentc/brave-portable/releases"
echo $tempDir = Join-Path $env:TEMP "BraveUpdate"
echo.
echo try {
echo   # Get version information
echo   $currentVersion = if ^(Test-Path $bravePath^) { ^(Get-Item $bravePath^).VersionInfo.ProductVersion } else { "Not installed" }
echo   Write-Host "Fetching latest release information..." -ForegroundColor Cyan
echo   $allReleases = Invoke-RestMethod -Uri $apiUrl
echo   $channelReleases = $allReleases ^| Where-Object { $_.tag_name -like "brave-portable-x64_*" }
echo   $latestRelease = $channelReleases ^| Sort-Object { if ^($_.tag_name -match "([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)"^) { [System.Version]$matches[1] } else { [System.Version]"0.0.0.0" } } -Descending ^| Select-Object -First 1
echo   $latestVersion = ^($latestRelease.tag_name -split "_"^)^[1^]
echo   $downloadUrl = $latestRelease.assets^[0^].browser_download_url
echo.
echo   Write-Host "Current version: $currentVersion" -ForegroundColor Yellow
echo   Write-Host "Latest version: $latestVersion" -ForegroundColor Yellow
echo   Write-Host
echo.
echo   if ^($currentVersion -eq $latestVersion^) {
echo     Write-Host "Already up to date!" -ForegroundColor Green
echo     Read-Host "Press Enter to exit"
echo     exit
echo   }
echo.
echo   $confirm = Read-Host "Do you want to update? (y/N)"
echo   if ^($confirm -ne 'y' -and $confirm -ne 'Y'^) { exit }
echo.
echo   # Stop processes with retry
echo   if ^(Test-Path $bravePath^) {
echo     Write-Host "Stopping Brave processes..." -ForegroundColor Cyan
echo     $processNames = @^('brave', 'BraveUpdate', 'BraveCrashHandler'^)
echo     foreach ^($procName in $processNames^) {
echo       try {
echo         $processes = Get-Process -Name $procName -ErrorAction SilentlyContinue
echo         if ^($processes^) {
echo           $processes ^| Stop-Process -Force -ErrorAction SilentlyContinue
echo         }
echo       } catch {
echo         Write-Host "Note: Could not stop process $procName" -ForegroundColor Yellow
echo       }
echo     }
echo     Write-Host "Waiting for processes to close..." -ForegroundColor Cyan
echo     Start-Sleep -Seconds 3
echo   }
echo.
echo   # Clean temp directory
echo   Remove-ItemSafely -Path $tempDir
echo   New-Item -ItemType Directory -Path $tempDir -Force ^| Out-Null
echo   $zipFile = Join-Path $tempDir "update.zip"
echo.
echo   # Download with error handling
echo   Write-Host "Downloading from: $downloadUrl" -ForegroundColor Cyan
echo   Invoke-WithRetry -ScriptBlock {
echo     ^(New-Object System.Net.WebClient^).DownloadFile^($downloadUrl, $zipFile^)
echo   } -MaxRetries 3 -DelaySeconds 3
echo.
echo   # Extract
echo   Write-Host "Extracting..." -ForegroundColor Cyan
echo   Expand-Archive -Path $zipFile -DestinationPath $tempDir -Force
echo.
echo   $extractedDir = Get-ChildItem $tempDir -Recurse -Directory ^| Where-Object { $_.Name -eq "Brave" } ^| Select-Object -First 1
echo   $currentDir = "%~dp0"
echo.
echo   # Update files with retry logic
echo   Write-Host "Updating files..." -ForegroundColor Cyan
echo   $filesToRemove = @^("brave.exe", "browser.exe", "version.dll"^)
echo   foreach ^($file in $filesToRemove^) {
echo     $filePath = Join-Path $currentDir $file
echo     if ^(Test-Path $filePath^) {
echo       Write-Host "Removing $file..." -ForegroundColor Gray
echo       Remove-ItemSafely -Path $filePath
echo     }
echo   }
echo.
echo   # Remove old version directory
echo   if ^($currentVersion -ne "Not installed"^) {
echo     $oldVersionPath = Join-Path $currentDir $currentVersion
echo     if ^(Test-Path $oldVersionPath^) {
echo       Write-Host "Removing old version directory..." -ForegroundColor Gray
echo       Remove-ItemSafely -Path $oldVersionPath
echo     }
echo   }
echo.
echo   # Copy new files
echo   Write-Host "Copying new files..." -ForegroundColor Cyan
echo   Get-ChildItem $extractedDir.FullName -Recurse ^| ForEach-Object {
echo     $relativePath = $_.FullName.Substring^($extractedDir.FullName.Length + 1^)
echo     $destPath = Join-Path $currentDir $relativePath
echo     if ^($_.PSIsContainer^) {
echo       if ^(-not ^(Test-Path $destPath^)^) {
echo         New-Item -ItemType Directory -Path $destPath -Force ^| Out-Null
echo       }
echo     } else {
echo       $protectedFiles = @^("chrome++.ini","debloat.reg","update.bat"^)
echo       if ^($_.Name -in $protectedFiles -and ^(Test-Path $destPath^)^) {
echo         Write-Host "  Skipping protected file: $^($_.Name^)" -ForegroundColor Gray
echo       } else {
echo         $destFolder = Split-Path $destPath -Parent
echo         if ^(-not ^(Test-Path $destFolder^)^) {
echo           New-Item -ItemType Directory -Path $destFolder -Force ^| Out-Null
echo         }
echo         Invoke-WithRetry -ScriptBlock {
echo           Copy-Item $_.FullName -Destination $destPath -Force -ErrorAction Stop
echo         } -MaxRetries 3 -DelaySeconds 1
echo       }
echo     }
echo   }
echo.
echo   # Verify update
echo   $newCurrentVersion = if ^(Test-Path $bravePath^) { ^(Get-Item $bravePath^).VersionInfo.ProductVersion } else { "Not installed" }
echo   if ^($newCurrentVersion -eq $latestVersion^) {
echo     Write-Host
echo     Write-Host "========================================" -ForegroundColor Green
echo     Write-Host "Update completed successfully!" -ForegroundColor Green
echo     Write-Host "Version: $newCurrentVersion" -ForegroundColor Green
echo     Write-Host "========================================" -ForegroundColor Green
echo   } else {
echo     Write-Host
echo     Write-Host "Update may not be complete." -ForegroundColor Yellow
echo     Write-Host "Expected: $latestVersion" -ForegroundColor Yellow
echo     Write-Host "Actual: $newCurrentVersion" -ForegroundColor Yellow
echo   }
echo.
echo } catch {
echo   Write-Host
echo   Write-Host "========================================" -ForegroundColor Red
echo   Write-Host "Error occurred during update:" -ForegroundColor Red
echo   Write-Host $_.Exception.Message -ForegroundColor Red
echo   Write-Host "========================================" -ForegroundColor Red
echo   Write-Host
echo   if ^($_.Exception.Message -match "denied"^) {
echo     Write-Host "TIP: Try running this script as Administrator" -ForegroundColor Yellow
echo   }
echo } finally {
echo   # Cleanup temp directory
echo   if ^(Test-Path $tempDir^) {
echo     try {
echo       Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
echo     } catch {
echo       Write-Host "Note: Could not remove temp directory" -ForegroundColor Gray
echo     }
echo   }
echo }
echo.
echo Read-Host "Press Enter to exit"
) > "%TEMP%\brave_update.ps1"
powershell -NoProfile -ExecutionPolicy Bypass -File "%TEMP%\brave_update.ps1"
del "%TEMP%\brave_update.ps1" 2>nul
