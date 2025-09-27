@echo off
setlocal enabledelayedexpansion

echo SASyLF VS Code Extension Fix for Windows 11
echo ==========================================
echo Issue: Extension crashes due to logging utility file access problems
echo Source: https://github.com/boyland/sasylf/pull/127 (utils.js logging functions)
echo.

set "extensionPath=%USERPROFILE%\.vscode\extensions"

if not exist "%extensionPath%" (
    echo ERROR: VS Code extensions directory not found: %extensionPath%
    echo Please make sure VS Code is installed and has been run at least once.
    echo.
    pause
    exit /b 1
)

echo Scanning for SASyLF extensions in: %extensionPath%
echo.

set "foundExtensions=0"
set "fixedExtensions=0"

for /d %%i in ("%extensionPath%\sasylf.sasylf-*") do (
    set /a foundExtensions+=1
    echo Found SASyLF extension: %%~nxi
    echo   Path: %%i
    
    if not exist "%%i\logs" (
        mkdir "%%i\logs" 2>nul
        if !errorlevel! equ 0 (
            echo   ^✓ Created logs directory
        ) else (
            echo   ^✗ Failed to create logs directory
            goto :continue
        )
    ) else (
        echo   ^✓ Logs directory already exists
    )
    
    echo   ^→ Taking ownership and fixing permissions...
    takeown /f "%%i\logs" /r /d y >nul 2>&1
    if !errorlevel! equ 0 (
        echo   ^✓ Took ownership of logs directory
    ) else (
        echo   ^⚠ Could not take ownership
    )
    
    icacls "%%i\logs" /reset /T >nul 2>&1
    icacls "%%i\logs" /grant %USERNAME%:F /T >nul 2>&1
    if !errorlevel! equ 0 (
        echo   ^✓ Set comprehensive file permissions
    ) else (
        echo   ^⚠ Could not set permissions fully
    )
    
    echo   ^→ Testing file creation...
    echo test > "%%i\logs\sasylf-test.log" 2>nul
    if exist "%%i\logs\sasylf-test.log" (
        del "%%i\logs\sasylf-test.log" 2>nul
        echo   ^✓ File creation test successful
        set /a fixedExtensions+=1
    ) else (
        echo   ^⚠ File creation test failed - directory exists but file creation blocked
    )
    
    :continue
    echo.
)

if %foundExtensions% equ 0 (
    echo No SASyLF extensions found. Please install the extension first:
    echo 1. Open VS Code
    echo 2. Go to Extensions (Ctrl+Shift+X^)
    echo 3. Search for 'SASyLF'
    echo 4. Install the extension
    echo 5. Run this script again
    echo.
    pause
    exit /b 1
)

echo Summary:
echo   Extensions found: %foundExtensions%
echo   Successfully fixed: %fixedExtensions%
echo.

if %fixedExtensions% gtr 0 (
    echo Fix completed! Next steps:
    echo 1. Close VS Code completely
    echo 2. Restart VS Code
    echo 3. Open a .slf file to test the extension
) else (
    echo No extensions were successfully fixed. Additional steps:
    echo 1. Run this script as Administrator
    echo 2. Add VS Code extensions folder to Windows Defender exclusions:
    echo    %extensionPath%
    echo 3. Try running VS Code as Administrator temporarily
    echo 4. Check Windows Event Viewer for detailed error information
)

echo.
pause