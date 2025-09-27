# SASyLF VS Code Extension - Proper Fix for Logging Issue

## Issue Summary

The SASyLF VS Code extension crashes on Windows 11 due to a file access error in the logging utility:

```
Error: ENOENT: no such file or directory, open 'c:\Users\username\.vscode\extensions\sasylf.sasylf-2.0.0\logs\2025-09-09T03:09:37.667Z.log'
    at createLogFile (c:\Users\username\.vscode\extensions\sasylf.sasylf-2.0.0\server\out\utils.js:153:12)
    at logErrorToFile (c:\Users\username\.vscode\extensions\sasylf.sasylf-2.0.0\server\out\utils.js:160:25)
```

## Root Cause

The language server's logging utility in `utils.ts` (compiled to `utils.js`) does not properly handle:
1. Directory creation before file access
2. Permission errors on Windows systems
3. Fallback mechanisms when file system access is restricted

## Source Code Location

The extension source code is available in [boyland/sasylf PR #127](https://github.com/boyland/sasylf/pull/127) in the `lsp-sasylf/server/src/` directory.

## Recommended Fix

Update the logging functions in `utils.ts` with proper error handling:

```typescript
import * as fs from 'fs';
import * as path from 'path';

export function createLogFile(logPath: string): boolean {
    try {
        // Ensure the directory exists
        const logDir = path.dirname(logPath);
        if (!fs.existsSync(logDir)) {
            fs.mkdirSync(logDir, { recursive: true, mode: 0o755 });
        }
        
        // Test write access by creating an empty file
        fs.writeFileSync(logPath, '', { flag: 'w' });
        return true;
    } catch (error) {
        // Log to console as fallback
        console.warn(`Cannot create log file at ${logPath}:`, error.message);
        return false;
    }
}

export function logErrorToFile(message: string, logPath?: string): void {
    if (!logPath) {
        console.error(message);
        return;
    }
    
    try {
        // Try to create/access the log file
        if (createLogFile(logPath)) {
            const timestamp = new Date().toISOString();
            fs.appendFileSync(logPath, `${timestamp}: ${message}\n`);
        } else {
            // Fallback to console logging
            console.error(`[LOG FALLBACK] ${message}`);
        }
    } catch (error) {
        // Ultimate fallback to console
        console.error(`[LOG ERROR] ${message}`);
        console.error(`[LOG ERROR] Failed to write to ${logPath}:`, error.message);
    }
}
```

## Key Improvements

1. **Directory Creation**: Uses `fs.mkdirSync()` with `recursive: true` to ensure parent directories exist
2. **Error Handling**: Wraps all file operations in try-catch blocks
3. **Fallback Logging**: Falls back to console logging when file system access fails
4. **Permission Handling**: Uses appropriate file modes and flags for cross-platform compatibility
5. **Graceful Degradation**: Extension continues to work even if logging fails

## Testing

This fix should be tested on:
- Windows 11 with standard user permissions
- Windows 11 with restricted user permissions
- Windows Defender real-time protection enabled
- Corporate environments with strict file system policies

## Alternative: Disable File Logging

If the above fix still causes issues, consider disabling file logging entirely on Windows:

```typescript
const isWindows = process.platform === 'win32';
const enableFileLogging = !isWindows; // Disable on Windows to avoid permission issues

export function logErrorToFile(message: string, logPath?: string): void {
    if (!enableFileLogging || !logPath) {
        console.error(message);
        return;
    }
    
    // ... rest of logging logic
}
```

## User Workarounds

Until the extension is updated, users can apply the workarounds provided in `VSCODE-EXTENSION-FIX.md` to resolve permission issues manually.