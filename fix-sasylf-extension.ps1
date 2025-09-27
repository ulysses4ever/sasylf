# SASyLF VS Code Extension Fix for Windows 11
# This script creates the missing logs directory and sets proper permissions

Write-Host "SASyLF VS Code Extension Fix for Windows 11" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
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
    
    # Check if logs directory exists
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
    
    # Set permissions
    try {
        $acl = Get-Acl $logsPath
        $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($env:USERNAME, "FullControl", "Allow")
        $acl.SetAccessRule($accessRule)
        Set-Acl $logsPath $acl
        Write-Host "  ✓ Set full permissions for user: $env:USERNAME" -ForegroundColor Green
        $fixedCount++
    } catch {
        Write-Host "  ⚠ Warning: Could not set permissions: $($_.Exception.Message)" -ForegroundColor Yellow
        Write-Host "    Try running PowerShell as Administrator" -ForegroundColor Yellow
    }
    
    Write-Host ""
}

Write-Host "Summary:" -ForegroundColor Cyan
Write-Host "  Extensions processed: $($sasylf_extensions.Count)" -ForegroundColor White
Write-Host "  Successfully fixed: $fixedCount" -ForegroundColor Green

if ($fixedCount -gt 0) {
    Write-Host ""
    Write-Host "Fix completed successfully! Please:" -ForegroundColor Green
    Write-Host "1. Close VS Code completely" -ForegroundColor Yellow
    Write-Host "2. Restart VS Code" -ForegroundColor Yellow
    Write-Host "3. Open a .slf file to test the extension" -ForegroundColor Yellow
} else {
    Write-Host ""
    Write-Host "No extensions were fixed. If issues persist:" -ForegroundColor Red
    Write-Host "1. Try running PowerShell as Administrator" -ForegroundColor Yellow
    Write-Host "2. Check Windows Defender/antivirus settings" -ForegroundColor Yellow
    Write-Host "3. Report the issue with full error details" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Press any key to continue..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")