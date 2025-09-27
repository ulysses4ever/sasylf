@echo off
setlocal enabledelayedexpansion

echo SASyLF VS Code Extension Fix for Windows 11
echo ==========================================
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
    
    echo   Setting permissions on logs directory...
    icacls "%%i\logs" /grant %USERNAME%:F >nul 2>&1
    if !errorlevel! equ 0 (
        echo   ^✓ Set full permissions for user: %USERNAME%
        set /a fixedExtensions+=1
    ) else (
        echo   ^⚠ Warning: Could not set permissions
        echo     Try running this script as Administrator
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
    echo Fix completed successfully! Please:
    echo 1. Close VS Code completely
    echo 2. Restart VS Code
    echo 3. Open a .slf file to test the extension
) else (
    echo No extensions were fixed. If issues persist:
    echo 1. Try running this script as Administrator
    echo 2. Check Windows Defender/antivirus settings
    echo 3. Report the issue with full error details
)

echo.
pause