# SASyLF VS Code Extension Windows 11 Fix

## Issue Description

The SASyLF VS Code extension (sasylf.sasylf-2.0.0) crashes on Windows 11 with the following error:

```
Error: ENOENT: no such file or directory, open 'c:\Users\username\.vscode\extensions\sasylf.sasylf-2.0.0\logs\2025-09-09T03:09:37.667Z.log'
```

This occurs even when the `logs` directory exists. The issue is that the extension cannot create or write to the specific log file within the directory. 

## Root Cause Analysis

**The VS Code extension source code is available in [boyland/sasylf PR #127](https://github.com/boyland/sasylf/pull/127).** The issue is in the language server's `utils.js` file (compiled from TypeScript) where the `createLogFile` function attempts to create log files without properly checking directory existence or handling permission errors.

The error occurs at:
- `createLogFile (c:\Users\username\.vscode\extensions\sasylf.sasylf-2.0.0\server\out\utils.js:153:12)`
- `logErrorToFile (c:\Users\username\.vscode\extensions\sasylf.sasylf-2.0.0\server\out\utils.js:160:25)`

Common causes include:

- **File permissions**: Directory exists but lacks write permissions for individual files
- **Windows security restrictions**: Windows Defender or security software blocking file creation
- **Electron/Node.js file access issues**: VS Code's Electron runtime having restricted file system access  
- **Path length or character encoding issues**: Windows file system limitations with certain characters or long paths

## Proper Fix for Extension Developers

**For developers with access to the extension source code ([PR #127](https://github.com/boyland/sasylf/pull/127)):**

The root issue is in the `utils.ts` file (compiled to `utils.js`) where logging functions don't properly handle directory creation. The fix should include:

```typescript
import * as fs from 'fs';
import * as path from 'path';

function createLogFile(logPath: string): void {
    try {
        // Ensure the directory exists
        const logDir = path.dirname(logPath);
        if (!fs.existsSync(logDir)) {
            fs.mkdirSync(logDir, { recursive: true });
        }
        
        // Test write access
        fs.writeFileSync(logPath, '');
    } catch (error) {
        // Fallback to console logging if file system is restricted
        console.error('Failed to create log file:', error);
        // Disable file logging for this session
        return;
    }
}

function logErrorToFile(error: any, logPath: string): void {
    try {
        createLogFile(logPath);
        fs.appendFileSync(logPath, `${new Date().toISOString()}: ${error}\n`);
    } catch (fsError) {
        // Fallback to console if file logging fails
        console.error('Logging error:', error);
        console.error('File system error:', fsError);
    }
}
```

This approach:
1. Creates directories recursively with proper error handling
2. Tests write access before attempting to log
3. Falls back to console logging if file system access fails
4. Handles Windows-specific permission issues gracefully

## Workarounds for Users

Since the extension cannot be immediately updated, users can apply these workarounds:

### User Solution 1: File Permissions and Security Fix

1. **Navigate to your VS Code extensions directory:**
   ```cmd
   cd %USERPROFILE%\.vscode\extensions\sasylf.sasylf-2.0.0
   ```

2. **Verify the logs directory exists:**
   ```cmd
   dir logs
   ```

3. **Set comprehensive permissions on the logs directory:**
   ```cmd
   icacls logs /grant %USERNAME%:F /T
   takeown /f logs /r /d y
   icacls logs /reset /T
   icacls logs /grant %USERNAME%:F /T
   ```

4. **Test file creation permissions:**
   ```cmd
   echo test > logs\test.log
   del logs\test.log
   ```

5. **Add VS Code extensions directory to Windows Defender exclusions:**
   - Open Windows Security → Virus & threat protection → Manage settings
   - Add exclusion for folder: `%USERPROFILE%\.vscode\extensions`

6. **Restart VS Code as Administrator** (temporarily to test):
   - Right-click VS Code → "Run as administrator"

### User Solution 2: PowerShell Script (Automated Fix)

Create a file called `fix-sasylf-extension.ps1` with the following content:

```powershell
# SASyLF VS Code Extension Fix for Windows 11
# This script fixes file permissions and security issues preventing log file creation

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
    
    # Ensure logs directory exists
    if (!(Test-Path $logsPath)) {
        New-Item -ItemType Directory -Path $logsPath -Force
        Write-Host "Created logs directory: $logsPath" -ForegroundColor Green
    } else {
        Write-Host "Logs directory exists: $logsPath" -ForegroundColor Blue
    }
    
    # Take ownership and reset permissions
    try {
        takeown /f "$logsPath" /r /d y 2>$null
        icacls "$logsPath" /reset /T 2>$null
        icacls "$logsPath" /grant "${env:USERNAME}:F" /T 2>$null
        Write-Host "Fixed permissions on logs directory" -ForegroundColor Green
        
        # Test file creation
        $testFile = Join-Path $logsPath "test.log"
        "test" | Out-File $testFile
        Remove-Item $testFile
        Write-Host "File creation test successful" -ForegroundColor Green
        
    } catch {
        Write-Host "Warning: Permission fix failed. Try running as Administrator." -ForegroundColor Yellow
    }
    
    # Add to Windows Defender exclusions (requires admin)
    try {
        Add-MpPreference -ExclusionPath $extensionPath -ErrorAction Stop
        Write-Host "Added to Windows Defender exclusions" -ForegroundColor Green
    } catch {
        Write-Host "Note: Could not add Windows Defender exclusion. Add manually: $extensionPath" -ForegroundColor Yellow
    }
}

Write-Host "`nFix completed. Please restart VS Code." -ForegroundColor Cyan
```

Run the script in PowerShell:
```powershell
PowerShell -ExecutionPolicy Bypass -File fix-sasylf-extension.ps1
```

### User Solution 3: Batch Script (Alternative for cmd users)

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
        echo Logs directory exists: %%i\logs
    )
    
    echo Fixing permissions and ownership...
    takeown /f "%%i\logs" /r /d y >nul 2>&1
    icacls "%%i\logs" /reset /T >nul 2>&1
    icacls "%%i\logs" /grant %USERNAME%:F /T >nul 2>&1
    
    echo Testing file creation...
    echo test > "%%i\logs\test.log" 2>nul
    if exist "%%i\logs\test.log" (
        del "%%i\logs\test.log"
        echo File creation test successful
    ) else (
        echo Warning: File creation test failed
    )
    echo.
)

echo Fix completed. Please restart VS Code.
echo.
echo Note: If issues persist, try:
echo 1. Run this script as Administrator
echo 2. Add VS Code extensions folder to Windows Defender exclusions
echo 3. Restart VS Code as Administrator temporarily to test
pause
```

## Additional Troubleshooting

### If the issue persists even with existing logs directory:

1. **Windows Defender/Antivirus Exclusions:**
   - Open Windows Security → Virus & threat protection → Manage settings → Add or remove exclusions
   - Add folder exclusion: `%USERPROFILE%\.vscode\extensions`
   - This prevents real-time scanning from blocking file operations

2. **Run VS Code as Administrator (temporary test):**
   ```
   Right-click VS Code → "Run as administrator"
   ```
   If this fixes the issue, the problem is definitely permissions-related.

3. **Check Windows Event Viewer:**
   - Open Event Viewer → Windows Logs → Application
   - Look for errors related to VS Code or file access around the time of the crash
   - This may provide more specific error details

4. **Alternative VS Code Installation:**
   - Try the "System" installer instead of "User" installer
   - System installer has broader file system access permissions

5. **Clear VS Code Extension Host Cache:**
   - Close VS Code completely
   - Delete: `%APPDATA%\Code\User\workspaceStorage`
   - Delete: `%APPDATA%\Code\CachedExtensions`
   - Restart VS Code

6. **File System Permissions Debug:**
   ```cmd
   whoami /groups
   icacls "%USERPROFILE%\.vscode\extensions\sasylf.sasylf-2.0.0\logs" /T
   ```
   This shows your user groups and detailed permissions on the logs directory.

7. **Windows Long Path Support:**
   - Enable long path support in Windows (may help with path-related issues):
   ```cmd
   reg add HKLM\SYSTEM\CurrentControlSet\Control\FileSystem /v LongPathsEnabled /t REG_DWORD /d 1
   ```
   Requires restart.

## Reporting Issues

If none of these solutions work, please report the issue with:
- Your exact Windows version (`winver`)
- VS Code version (`Help > About`)
- Extension version
- Full error log from VS Code Developer Console (`Help > Toggle Developer Tools`)

## Notes

**Important**: This fix addresses the scenario where the logs directory exists but individual log files cannot be created within it. The original error `ENOENT: no such file or directory` refers to the specific log file, not the logs directory itself.

**For Extension Developers**: The proper solution is to update the extension source code (available in [boyland/sasylf PR #127](https://github.com/boyland/sasylf/pull/127)) to include proper directory creation and error handling in the logging utilities.

**For Users**: The workarounds above address permission and security issues that prevent file creation, providing immediate relief until the extension is updated.

The root cause is in the extension's `utils.js` logging mechanism which should:
1. Check directory existence before attempting file operations
2. Handle permission errors gracefully with fallback logging  
3. Create directories recursively when needed
4. Provide fallback mechanisms when file system access is restricted