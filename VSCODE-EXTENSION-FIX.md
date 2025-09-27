# SASyLF VS Code Extension Windows 11 Fix

## Issue Description

The SASyLF VS Code extension (sasylf.sasylf-2.0.0) crashes on Windows 11 with the following error:

```
Error: ENOENT: no such file or directory, open 'c:\Users\username\.vscode\extensions\sasylf.sasylf-2.0.0\logs\2025-09-09T03:09:37.667Z.log'
```

This occurs because the extension attempts to write log files to a directory that doesn't exist or cannot be accessed properly.

## Solutions

### Solution 1: Manual Directory Creation and Permission Fix

1. **Navigate to your VS Code extensions directory:**
   ```cmd
   cd %USERPROFILE%\.vscode\extensions\sasylf.sasylf-2.0.0
   ```

2. **Create the logs directory if it doesn't exist:**
   ```cmd
   mkdir logs
   ```

3. **Set proper permissions on the logs directory:**
   ```cmd
   icacls logs /grant %USERNAME%:F
   ```

4. **Restart VS Code**

### Solution 2: PowerShell Script (Automated Fix)

Create a file called `fix-sasylf-extension.ps1` with the following content:

```powershell
# SASyLF VS Code Extension Fix for Windows 11
# This script creates the missing logs directory and sets proper permissions

$extensionPath = "$env:USERPROFILE\.vscode\extensions"
$sasylf_extensions = Get-ChildItem -Path $extensionPath -Directory -Name "sasylf.sasylf-*"

if ($sasylf_extensions.Count -eq 0) {
    Write-Host "SASyLF extension not found. Please install the extension first." -ForegroundColor Red
    exit 1
}

foreach ($extension in $sasylf_extensions) {
    $fullPath = Join-Path $extensionPath $extension
    $logsPath = Join-Path $fullPath "logs"
    
    Write-Host "Processing extension: $extension" -ForegroundColor Yellow
    
    if (!(Test-Path $logsPath)) {
        New-Item -ItemType Directory -Path $logsPath -Force
        Write-Host "Created logs directory: $logsPath" -ForegroundColor Green
    } else {
        Write-Host "Logs directory already exists: $logsPath" -ForegroundColor Blue
    }
    
    # Set permissions
    try {
        $acl = Get-Acl $logsPath
        $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($env:USERNAME, "FullControl", "Allow")
        $acl.SetAccessRule($accessRule)
        Set-Acl $logsPath $acl
        Write-Host "Set permissions on logs directory" -ForegroundColor Green
    } catch {
        Write-Host "Warning: Could not set permissions. You may need to run as administrator." -ForegroundColor Yellow
    }
}

Write-Host "`nFix completed. Please restart VS Code." -ForegroundColor Cyan
```

Run the script in PowerShell:
```powershell
PowerShell -ExecutionPolicy Bypass -File fix-sasylf-extension.ps1
```

### Solution 3: Batch Script (Alternative for cmd users)

Create a file called `fix-sasylf-extension.bat`:

```batch
@echo off
echo SASyLF VS Code Extension Fix for Windows 11
echo.

set "extensionPath=%USERPROFILE%\.vscode\extensions"

if not exist "%extensionPath%" (
    echo VS Code extensions directory not found: %extensionPath%
    echo Please make sure VS Code is installed and has been run at least once.
    pause
    exit /b 1
)

echo Looking for SASyLF extensions in: %extensionPath%
echo.

for /d %%i in ("%extensionPath%\sasylf.sasylf-*") do (
    echo Found SASyLF extension: %%~nxi
    
    if not exist "%%i\logs" (
        mkdir "%%i\logs"
        echo Created logs directory: %%i\logs
    ) else (
        echo Logs directory already exists: %%i\logs
    )
    
    echo Setting permissions on logs directory...
    icacls "%%i\logs" /grant %USERNAME%:F >nul 2>&1
    if !errorlevel! equ 0 (
        echo Permissions set successfully
    ) else (
        echo Warning: Could not set permissions. You may need to run as administrator.
    )
    echo.
)

echo Fix completed. Please restart VS Code.
pause
```

## Additional Troubleshooting

### If the issue persists:

1. **Check VS Code version compatibility:**
   - Ensure you're using a compatible version of VS Code
   - Try downgrading to VS Code 1.90.x if using 1.103.x

2. **Reinstall the extension:**
   ```
   code --uninstall-extension sasylf.sasylf
   code --install-extension sasylf.sasylf
   ```

3. **Run VS Code as Administrator:**
   - Right-click on VS Code and select "Run as administrator"
   - This may resolve permission issues

4. **Check Windows Defender/Antivirus:**
   - Add the VS Code extensions folder to your antivirus exclusions
   - Path: `%USERPROFILE%\.vscode\extensions`

5. **Clear VS Code workspace cache:**
   ```cmd
   rmdir /s "%APPDATA%\Code\User\workspaceStorage"
   ```

## Reporting Issues

If none of these solutions work, please report the issue with:
- Your exact Windows version (`winver`)
- VS Code version (`Help > About`)
- Extension version
- Full error log from VS Code Developer Console (`Help > Toggle Developer Tools`)

## Notes

This is a temporary workaround. The root cause is in the extension's logging mechanism not properly checking for directory existence before attempting to write files. The extension source code needs to be updated to create the logs directory if it doesn't exist.