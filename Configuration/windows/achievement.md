Ran command: `powershell -Command "
Get-Process -Name '*playnite*' -ErrorAction SilentlyContinue | Select-Object ProcessName, Id, Path
Get-ChildItem 'C:\Users\void\AppData\Roaming\Playnite' -ErrorAction SilentlyContinue | Select-Object Name
Get-ChildItem 'C:\Users\void\AppData\Local\Playnite' -ErrorAction SilentlyContinue | Select-Object Name
Get-ChildItem 'C:\Program Files\Playnite' -ErrorAction SilentlyContinue | Select-Object Name
Get-ChildItem 'C:\Program Files (x86)\Playnite' -ErrorAction SilentlyContinue | Select-Object Name
Get-ChildItem 'C:\Users\void\AppData\Roaming\Achievement Watcher' -Recurse -Filter '*Crimson*' -ErrorAction SilentlyContinue | Select-Object FullName
Get-ChildItem 'C:\Users\void\AppData\Roaming\Achievement Watcher' -Recurse -Filter '*3321460*' -ErrorAction SilentlyContinue | Select-Object FullName
"`
Ran command: `powershell -Command "
if (Test-Path 'C:\Users\void\AppData\Roaming\Playnite') { 'Found Roaming Playnite' }
if (Test-Path 'C:\Users\void\AppData\Local\Playnite') { 'Found Local Playnite' }
Get-Command playnite -ErrorAction SilentlyContinue
Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*, HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object { $_.DisplayName -like '*Playnite*' } | Select-Object DisplayName, InstallLocation
"`
Ran command: `powershell -Command 'Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*, HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -match "Playnite" } | Select-Object DisplayName, InstallLocation'`
Ran command: `powershell -Command 'Get-ChildItem "C:\Users\void\AppData\Roaming\Playnite" -ErrorAction SilentlyContinue | Select-Object Name'`
Ran command: `powershell -Command 'Get-ChildItem "C:\Users\void\AppData\Roaming\Playnite\Extensions" -ErrorAction SilentlyContinue | Select-Object Name; Get-ChildItem "C:\Users\void\AppData\Roaming\Playnite\ExtensionsData" -ErrorAction SilentlyContinue | Select-Object Name'`
Ran command: `powershell -Command 'Get-ChildItem "C:\Users\void\AppData\Roaming\Playnite\ExtensionsData" -Recurse -Depth 2 -Filter "*.json" | Select-Object FullName'`
Ran command: `powershell -Command '
Get-Content "C:\Users\void\AppData\Roaming\Playnite\ExtensionsData\00000002-dbd1-46c6-b5d0-b1ba559d10e4\config.json"
Get-Content "C:\Users\void\AppData\Roaming\Playnite\ExtensionsData\aebe8b7c-6dc3-4a66-af31-e7375c6b5e9e\config.json"
Get-Content "C:\Users\void\AppData\Roaming\Playnite\ExtensionsData\cb91dfc9-b977-43bf-8e70-55f46e410fab\config.json"
'`
Ran command: `powershell -Command 'Get-ChildItem "C:\Users\void\AppData\Roaming\Playnite\library\games" -Filter "*.json" | Select-Object -First 10'`
Ran command: `powershell -Command 'Get-ChildItem "C:\Users\void\AppData\Roaming\Playnite\library"'`
Ran command: `powershell -Command 'Select-String -Path "C:\Users\void\AppData\Roaming\Playnite\library\games.db" -Pattern "Crimson|Wukong|Ragnarok|God of War" -AllMatches | ForEach-Object { $_.Matches.Value }'`
Ran command: `powershell -Command 'Get-Process -Name "*playnite*" | Select-Object Id, ProcessName, MainWindowTitle'`
Ran command: `powershell -Command '
$src = "C:\Users\void\AppData\Roaming\Playnite\library\games.db"
$stream = [System.IO.File]::Open($src, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
$reader = New-Object System.IO.StreamReader($stream)
$content = $reader.ReadToEnd()
$reader.Close()
$stream.Close()
$matches = [regex]::Matches($content, "(?i)[a-z0-9 _-]{3,50}(crimson|wukong|god of war|ragnarok)[a-z0-9 _-]{0,50}")
$matches | ForEach-Object { $_.Value } | Select-Object -Unique
'`
Searched web: ""Playnite" "SuccessStory" "Achievement Watcher" OR "Goldberg" OR "RUNE""
Searched web: ""SuccessStory" Playnite "Achievement Watcher" integration"
Ran command: `powershell -Command 'Get-Content "C:\Users\void\AppData\Roaming\Achievement Watcher\logs\notification.log"'`
Ran command: `powershell -Command 'Get-Content "C:\Users\void\AppData\Roaming\Playnite\playnite.log" | Select-String "Crimson|Wukong|God of War|Downloaded" | Select-Object -First 30'`
Ran command: `powershell -Command '
Get-ChildItem "C:\Users\void\AppData\Roaming\Achievement Watcher\Local Storage\leveldb" | Select-Object Name
'`
Ran command: `powershell -Command '
Select-String -Path "C:\Users\void\AppData\Roaming\Achievement Watcher\Local Storage\leveldb\*" -Pattern "Crimson|3321460" -ErrorAction SilentlyContinue
'`
Searched web: ""SuccessStory" Playnite "RUNE" achievements path OR folder"

**Yes, you can track achievements directly in Playnite**, but with an important distinction between **Playtime** vs **Achievements**:

---

### What was happening earlier with Crimson Desert

In your Playnite logs, Playnite was tracking **Playtime** for Crimson Desert (logging ~54 minutes of gameplay). 

- **Playtime**: Playnite tracks playtime natively for any game added to it.
- **Achievements**: Neither Steam nor the emulator has achievements for Crimson Desert because it is an unreleased build and no official Steam achievement list exists for it yet.

---

### How to use Playnite to track Achievements (for God of War, Wukong, etc.)

Playnite does not track achievements out of the box—it uses a popular extension called **SuccessStory**.

#### Step 1: Install SuccessStory in Playnite
1. In Playnite, press **`F9`** (or click the **Playnite Controller Icon** in the top-left → **Add-ons...**).
2. Go to the **Browse** tab on the left.
3. Select **Generic**, locate **SuccessStory** (by Lacro59 or eFMann), and click **Install**.
4. Click **Save** in the bottom-right and allow Playnite to **restart**.

---

#### Step 2: Configure SuccessStory for Emulators (RUNE & Goldberg)
1. Open Playnite → click the top-left **Controller Icon** → **Add-ons...**
2. On the left side, go to **Extension Settings** → **Generic** → **SuccessStory**.
3. Look for the **Local** or **Steam Emulators** section and enable **Local Achievement Tracking**.
4. Ensure the emulator directories are enabled:
   - **RUNE**: `C:\Users\Public\Documents\Steam\RUNE` *(where God of War Ragnarök is saved)*
   - **Goldberg**: `%APPDATA%\Goldberg SteamEmu Saves`
5. Click **Save**.

---

#### Step 3: Link the Steam AppID to your games in Playnite
Because these are non-Steam/installed games, Playnite needs the Steam AppID to download the achievement names and icons:

1. In your Playnite library, right-click **God of War Ragnarök**.
2. Select **SuccessStory** → **Force Steam AppID** (or right-click → **Edit** → under Links/Advanced, set the Steam link or ID).
3. Enter the AppID for God of War Ragnarök:
   ```text
   2322010
   ```
4. Right-click the game again → **SuccessStory** → **Refresh Data**.

Your 3 unlocked achievements will now show up directly on the game page in Playnite.

---

### Summary: Playnite vs Achievement Watcher

| Feature | Playnite (SuccessStory) | Achievement Watcher |
| :--- | :--- | :--- |
| **Purpose** | Library launcher & collection showcase | Real-time in-game pop-ups |
| **Notifications** | Shows progress inside Playnite UI | Banners/toasts with sounds **while playing** |
| **Best Workflow** | View achievements & track playtime in your library | Run in background for on-screen unlock alerts |

You can use both together: **Achievement Watcher** will pop up when you unlock an achievement during gameplay, and **Playnite** will display your overall achievement progress in your game library.