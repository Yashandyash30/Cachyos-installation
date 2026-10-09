# Secondary Account Setup & App Sharing Guide (`void` & `void-pvt`)

This guide details how applications, browser profiles, and search environments are configured between the primary administrative account (**`void`**) and the secondary standard account (**`void-pvt`**).

---

## 1. Antigravity IDE

### Architecture & Paths
* **Shared Install Location:** [C:\Program Files\Antigravity IDE](file:///C:/Program%20Files/Antigravity%20IDE)
* **Start Menu Shortcut:** [C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Antigravity IDE.lnk](file:///C:/ProgramData/Microsoft/Windows/Start%20Menu/Programs/Antigravity%20IDE.lnk)
* **CLI Path:** `C:\Program Files\Antigravity IDE\bin`
* **User Data:** Each account maintains separate settings, extensions, and cache under its own `%UserProfile%\AppData\Roaming\Antigravity IDE` and `%UserProfile%\.gemini`.

### Disk Space Optimization (Reclaim ~1 GB Duplicate)
Because the IDE was originally installed in `void`'s personal AppData folder, you can delete the duplicate files and replace them with an **NTFS Directory Junction** (`mklink /J`). This takes **0 MB** of additional space while maintaining full compatibility.

Run this in **Administrator PowerShell** when Antigravity IDE is closed:
```powershell
# 1. Close running IDE instances
Stop-Process -Name "Antigravity IDE" -Force -ErrorAction SilentlyContinue

# 2. Delete duplicate ~1 GB folder in user profile
$oldDir = "C:\Users\void\AppData\Local\Programs\Antigravity IDE"
if (Test-Path $oldDir) {
    Remove-Item -Path $oldDir -Recurse -Force
}

# 3. Create 0-byte NTFS Directory Junction
cmd /c mklink /J "C:\Users\void\AppData\Local\Programs\Antigravity IDE" "C:\Program Files\Antigravity IDE"

Write-Host "Reclaimed ~1 GB! Both accounts now share a single physical installation."
```

### Explorer Context Menu Fix ("Open in Antigravity IDE")
* **Cause of Failure:** The right-click menu was registered to execute `C:\Users\void\Documents\Launch-Antigravity.ps1`, which pointed to `void`'s personal `AppData` executable. Because `C:\Users\void` is private, `void-pvt` received "Access is denied" when trying to launch the script.
* **Fix:** Move the launcher script to `C:\Program Files\Antigravity IDE\Launch-Antigravity.ps1` and update the system registry to point to the shared path.

Run this in **Administrator PowerShell**:
```powershell
# 1. Update launcher script in shared Program Files location
$scriptContent = @'
param([string]$path)

$exePath = "C:\Program Files\Antigravity IDE\Antigravity IDE.exe"

# If the path is on Z: or Y:, map to remote Linux path
if ($path -match "^Z:") {
    $linuxPath = $path -replace '^Z:', '/home/void' -replace '\\', '/'
    $remoteUri = "vscode-remote://ssh-remote+void@100.117.73.75$linuxPath"
    Start-Process -FilePath $exePath -ArgumentList "--folder-uri", "`"$remoteUri`""
}
elseif ($path -match "^Y:") {
    $linuxPath = $path -replace '^Y:', '/mnt/Storage' -replace '\\', '/'
    $remoteUri = "vscode-remote://ssh-remote+void@100.117.73.75$linuxPath"
    Start-Process -FilePath $exePath -ArgumentList "--folder-uri", "`"$remoteUri`""
}
else {
    Start-Process -FilePath $exePath -ArgumentList "`"$path`""
}
'@

$sharedScript = "C:\Program Files\Antigravity IDE\Launch-Antigravity.ps1"
Set-Content -Path $sharedScript -Value $scriptContent -Force
icacls $sharedScript /grant "Users:(OI)(CI)RX"

# 2. Update Registry entries for Directory and Background context menus
$iconPath = '"C:\Program Files\Antigravity IDE\Antigravity IDE.exe"'
$cmdDir = 'powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -File "C:\Program Files\Antigravity IDE\Launch-Antigravity.ps1" "%1"'
$cmdBg = 'powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -File "C:\Program Files\Antigravity IDE\Launch-Antigravity.ps1" "%V"'

# Directory
Set-ItemProperty -Path "HKLM:\SOFTWARE\Classes\Directory\shell\AntigravityIDE" -Name "Icon" -Value $iconPath
Set-ItemProperty -Path "HKLM:\SOFTWARE\Classes\Directory\shell\AntigravityIDE\command" -Name "(Default)" -Value $cmdDir

# Directory Background
Set-ItemProperty -Path "HKLM:\SOFTWARE\Classes\Directory\Background\shell\AntigravityIDE" -Name "Icon" -Value $iconPath
Set-ItemProperty -Path "HKLM:\SOFTWARE\Classes\Directory\Background\shell\AntigravityIDE\command" -Name "(Default)" -Value $cmdBg

Write-Host "Context menu updated! 'Open in Antigravity IDE' now works for both accounts."
```

---

## 2. Brave Browser

### Machine-Wide Installation
To make Brave available across both user accounts without requiring dual installations:
```powershell
winget install --id Brave.Brave --scope machine
```
* **Install Path:** [C:\Program Files\BraveSoftware\Brave-Browser\Application\brave.exe](file:///C:/Program%20Files/BraveSoftware/Brave-Browser/Application/brave.exe)
* **Shared Shortcut:** [C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Brave.lnk](file:///C:/ProgramData/Microsoft/Windows/Start%20Menu/Programs/Brave.lnk)

### Sharing Passwords, History & Bookmarks (Brave Sync)
> **Why not copy the profile folder?**
> Chromium uses **Windows DPAPI** (`CryptProtectData`) tied to the user account SID to encrypt passwords and cookies. Copying the raw profile folder will cause passwords to fail to decrypt on another account.

**Setup Steps:**
1. In the **`void`** account, open Brave and navigate to `brave://settings/sync`.
2. Click **Start a new sync chain** $\rightarrow$ select **Computer** $\rightarrow$ copy the 24-word phrase.
3. In the **`void-pvt`** account, open Brave and navigate to `brave://settings/sync`.
4. Click **I have a sync code** and paste the 24 words.
5. Under **Sync data**, choose **Sync everything** (Passwords, History, Bookmarks, Extensions, Tabs).

---

## 3. Zen Browser

### Architecture & Permissions
* **Install Path:** [C:\Program Files\Zen Browser\zen.exe](file:///C:/Program%20Files/Zen%20Browser/zen.exe)
* **Shared Shortcut:** [C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Zen.lnk](file:///C:/ProgramData/Microsoft/Windows/Start%20Menu/Programs/Zen.lnk)
* **Permissions:** `BUILTIN\Users` has Read & Execute permissions (`RX`).

### Sharing Passwords & History
Zen uses Mozilla NSS (`key4.db` / `logins.json`) rather than Windows DPAPI:
* **Option A (Zen / Firefox Sync - Recommended):** Sign into the same Zen/Firefox account on both profiles. Allows simultaneous usage without profile lock errors.
* **Option B (Shared Disk Profile):** Launch Zen on both accounts with a shared profile path:
  ```powershell
  "C:\Program Files\Zen Browser\zen.exe" --profile "C:\Users\Public\ZenProfile"
  ```
  *(Note: Option B only permits one account to run Zen at a time due to file locking).*

---

## 4. Flow Launcher

### Recommended Setup: Install Per-User (Separate for Each Account)
> [!IMPORTANT]
> **Why Flow Launcher should NOT be shared via Program Files:**
> Flow Launcher is built as a per-user Squirrel application. It installs and updates core plugins (Program, Web Searches, Calculator, Explorer, etc.) directly inside its application directory. If installed in `C:\Program Files`, standard users (`void-pvt`) only have Read/Execute permissions, causing all plugin updates and auto-updates to fail with **"Error updating plugin"**.
> 
> Because Flow Launcher is only ~90 MB, the cleanest and most stable approach is to install it independently on each account:

1. **On `void-pvt`**, open PowerShell and run:
   ```powershell
   winget install Flow-Launcher.Flow-Launcher
   ```
   *(Or download and run the standard installer from flowlauncher.com while logged into `void-pvt`)*.
2. Inside Flow Launcher settings, turn on **"Start Flow Launcher on system startup"**. It will launch silently into the system tray without popping up on the screen.

### File Isolation (Preventing Cross-Account File Leakage)
1. **NTFS Permissions Hardening:**
   Ensure non-administrative accounts cannot read into private user directories:
   ```powershell
   icacls "C:\Users\void-pvt\Troubleshooting" /remove "BUILTIN\Users" /T /C
   icacls "C:\Users\void-pvt" /remove "BUILTIN\Users" /T /C
   ```
2. **Flow Launcher Exclusion:**
   To guarantee that Flow Launcher on the `void` account ignores files under `void-pvt`:
   * Open Flow Launcher $\rightarrow$ `Settings` $\rightarrow$ **Plugins** $\rightarrow$ **Explorer**.
   * Under **Index Search Excluded Subdirectory Paths**, add:
     ```
     C:\Users\void-pvt
     ```

---

## 5. AB Download Manager

### Architecture & Startup Configuration
* **Install Location:** [C:\Program Files\ABDownloadManager](file:///C:/Program%20Files/ABDownloadManager) (or per-user)
* **Silent Startup (Avoid Popups):**
  Do **not** place a raw shortcut inside `C:\ProgramData\...\Startup`. A raw shortcut causes:
  1. **Duplicate startup items** in Task Manager.
  2. The full GUI window to pop up on the screen rather than starting minimized in the system tray.
* **Proper Autostart:**
  Inside AB Download Manager $\rightarrow$ **Settings** $\rightarrow$ check **"Launch on system startup"**. This registers the official `--background` flag so it starts silently in the system tray.

```powershell
# 1. Close running AB Download Manager instances
Stop-Process -Name "ABDownloadManager" -Force -ErrorAction SilentlyContinue

# 2. Copy binaries to Program Files
$source = "C:\Users\void\AppData\Local\ABDownloadManager"
$destination = "C:\Program Files\ABDownloadManager"

if (-not (Test-Path $destination)) {
    New-Item -ItemType Directory -Path $destination -Force
}
Copy-Item -Path "$source\*" -Destination $destination -Recurse -Force

# 3. Grant Read & Execute permissions to all users
icacls "$destination" /grant "Users:(OI)(CI)RX" /T

# 4. Create shared Start Menu shortcut for all users
$WshShell = New-Object -ComObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut("C:\ProgramData\Microsoft\Windows\Start Menu\Programs\AB Download Manager.lnk")
$Shortcut.TargetPath = "$destination\ABDownloadManager.exe"
$Shortcut.Save()

# 5. (Optional) Auto-launch on startup for all users
Copy-Item "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\AB Download Manager.lnk" "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup" -Force

# 6. Reclaim AppData disk space using 0-byte NTFS Directory Junction
Remove-Item -Path $source -Recurse -Force
cmd /c mklink /J "$source" "$destination"

Write-Host "AB Download Manager is now configured and shared across all accounts!"
```

### Browser Integration for `void-pvt`
When logged into the **`void-pvt`** account:
1. Launch **AB Download Manager** from the Start Menu.
2. Open **Brave** or **Zen Browser** and install the **AB Download Manager Extension** (from the Chrome Web Store or Firefox Add-ons).
3. The extension connects to the local application instance, routing downloads directly into `C:\Users\void-pvt\Downloads`.

---

## 6. ComfyUI (Shared Environment & Model Permissions)

### Architecture & Paths
* **ComfyUI Base Directory:** [C:\Drive_E\Comfyui\comfyui-rocm-091926](file:///C:/Drive_E/Comfyui/comfyui-rocm-091926)
* **Models Directory:** [C:\Drive_E\Comfyui\comfyui-rocm-091926\models](file:///C:/Drive_E/Comfyui/comfyui-rocm-091926/models)
* **Python Executable:** `C:\Drive_E\Comfyui\comfyui-rocm-091926\python_env\python.exe`
* **Shared Storage:** All checkpoints, VAEs, LoRAs, and custom nodes are shared on drive `E:` so neither account duplicates multi-gigabyte models.

### Troubleshooting: "ModelMMAP allocation failed / OS Error: 5"
* **Symptom:** When running a workflow on `void-pvt`, model loading nodes (e.g. `VAELoader`, `UNETLoader`) fail with:
  ```
  RuntimeError: ModelMMAP allocation failed for ...\models\vae\ae.safetensors
  aimdo: model_mmap_allocate: could not open file. OS Error: 5
  ```
* **Cause:** Windows OS Error `5` is `ERROR_ACCESS_DENIED`. When models (`.safetensors`, `.gguf`, `.pth`) are downloaded via browser/hf-cli or moved across folders, Windows preserves the creator's explicit ACL and blocks NTFS inheritance (`InheritanceBlocked = True`), making them inaccessible to other standard accounts.
* **Fix (Reset Inheritance):**
  Run this command in PowerShell whenever new models are added:
  ```powershell
  icacls "C:\Drive_E\Comfyui\comfyui-rocm-091926\models" /reset /T /C
  ```

### Full ComfyUI Directory Permissions Reset
To ensure both accounts have full read, write, and execute permissions across all inputs, outputs, custom nodes, and user configs:
```powershell
# 1. Reset broken inheritance across the entire ComfyUI installation
icacls "C:\Drive_E\Comfyui" /reset /T /C

# 2. Grant Full Control to Users
icacls "C:\Drive_E\Comfyui" /grant "Users:(OI)(CI)F" /T /C
```
