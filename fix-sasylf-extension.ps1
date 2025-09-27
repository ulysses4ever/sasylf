# SASyLF VS Code Extension Fix for Windows 11
# This script fixes file permissions and security issues preventing log file creation

Write-Host "SASyLF VS Code Extension Fix for Windows 11" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Addresses file permission and security issues even when logs directory exists" -ForegroundColor Yellow
Write-Host ""

$extensionPath = "$env:USERPROFILE\.vscode\extensions"

if (!(Test-Path $extensionPath)) {
    Write-Host "VS Code extensions directory not found: $extensionPath" -ForegroundColor Red
    Write-Host "Please make sure VS Code is installed and has been run at least once." -ForegroundColor Yellow
    exit 1
}

Write-Host "Scanning for SASyLF extensions in: $extensionPath" -ForegroundColor Blue

$sasylf_extensions = Get-ChildItem -Path $extensionPath -Directory -Name "sasylf.sasylf-*"

if ($sasylf_extensions.Count -eq 0) {
    Write-Host "No SASyLF extensions found. Please install the extension first:" -ForegroundColor Red
    Write-Host "1. Open VS Code" -ForegroundColor Yellow
    Write-Host "2. Go to Extensions (Ctrl+Shift+X)" -ForegroundColor Yellow
    Write-Host "3. Search for 'SASyLF'" -ForegroundColor Yellow
    Write-Host "4. Install the extension" -ForegroundColor Yellow
    Write-Host "5. Run this script again" -ForegroundColor Yellow
    exit 1
}

Write-Host "Found $($sasylf_extensions.Count) SASyLF extension(s)" -ForegroundColor Green
Write-Host ""

$fixedCount = 0

foreach ($extension in $sasylf_extensions) {
    $fullPath = Join-Path $extensionPath $extension
    $logsPath = Join-Path $fullPath "logs"
    
    Write-Host "Processing extension: $extension" -ForegroundColor Yellow
    Write-Host "  Path: $fullPath"
    
    # Ensure logs directory exists
    if (!(Test-Path $logsPath)) {
        try {
            New-Item -ItemType Directory -Path $logsPath -Force | Out-Null
            Write-Host "  ✓ Created logs directory" -ForegroundColor Green
        } catch {
            Write-Host "  ✗ Failed to create logs directory: $($_.Exception.Message)" -ForegroundColor Red
            continue
        }
    } else {
        Write-Host "  ✓ Logs directory already exists" -ForegroundColor Blue
    }
    
    # Take ownership and reset permissions (more thorough than just setting ACL)
    try {
        Write-Host "  → Taking ownership and resetting permissions..." -ForegroundColor Cyan
        
        # Take ownership
        & takeown /f "$logsPath" /r /d y 2>&1 | Out-Null
        
        # Reset permissions to defaults
        & icacls "$logsPath" /reset /T 2>&1 | Out-Null
        
        # Grant full control to current user
        & icacls "$logsPath" /grant "${env:USERNAME}:F" /T 2>&1 | Out-Null
        
        Write-Host "  ✓ Fixed ownership and permissions" -ForegroundColor Green
        
        # Test file creation to verify fix
        $testFile = Join-Path $logsPath "sasylf-test.log"
        try {
            "Test log entry $(Get-Date)" | Out-File $testFile -ErrorAction Stop
            Remove-Item $testFile -ErrorAction Stop
            Write-Host "  ✓ File creation test successful" -ForegroundColor Green
            $fixedCount++
        } catch {
            Write-Host "  ⚠ File creation test failed: $($_.Exception.Message)" -ForegroundColor Yellow
            Write-Host "    The directory exists but file creation is still blocked" -ForegroundColor Yellow
        }
        
    } catch {
        Write-Host "  ✗ Permission fix failed: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "    Try running PowerShell as Administrator" -ForegroundColor Yellow
    }
    
    # Attempt to add Windows Defender exclusion (requires admin privileges)
    try {
        Add-MpPreference -ExclusionPath $extensionPath -ErrorAction Stop 2>&1 | Out-Null
        Write-Host "  ✓ Added Windows Defender exclusion" -ForegroundColor Green
    } catch {
        Write-Host "  ⚠ Could not add Windows Defender exclusion automatically" -ForegroundColor Yellow
        Write-Host "    Manually add exclusion for: $extensionPath" -ForegroundColor Yellow
    }
    
    Write-Host ""
}

Write-Host "Summary:" -ForegroundColor Cyan
Write-Host "  Extensions processed: $($sasylf_extensions.Count)" -ForegroundColor White
Write-Host "  Successfully fixed: $fixedCount" -ForegroundColor Green

if ($fixedCount -gt 0) {
    Write-Host ""
    Write-Host "Fix completed! Next steps:" -ForegroundColor Green
    Write-Host "1. Close VS Code completely" -ForegroundColor Yellow
    Write-Host "2. Restart VS Code" -ForegroundColor Yellow
    Write-Host "3. Open a .slf file to test the extension" -ForegroundColor Yellow
} else {
    Write-Host ""
    Write-Host "No extensions were successfully fixed. Additional steps:" -ForegroundColor Red
    Write-Host "1. Run PowerShell as Administrator and try again" -ForegroundColor Yellow
    Write-Host "2. Manually add Windows Defender exclusion: $extensionPath" -ForegroundColor Yellow
    Write-Host "3. Try running VS Code as Administrator temporarily" -ForegroundColor Yellow
    Write-Host "4. Check Windows Event Viewer for detailed error logs" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Press any key to continue..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")