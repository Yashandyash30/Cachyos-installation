I ran a scan across your entire drive. Your system has **930 GB** total storage, with **726 GB used** and **204 GB free**.

Here is the exact breakdown of what is occupying your space and how much you can reclaim:

---

### Storage Breakdown at a Glance

```
Total Used: ~726 GB
├── C:\Drive_D\Games\Downloaded   ── 529.6 GB  (73% of your entire used disk!)
├── C:\Drive_E (AI & Models)      ──  50.7 GB  (ComfyUI: 40.6 GB, Old SD: 10.0 GB)
├── C:\Users\void\AppData         ──  21.5 GB  (AMD Cache: 5 GB, Pip: 3.2 GB, etc.)
├── C:\Windows                    ──  24.3 GB  (OS Core)
├── C:\Program Files (x86 + x64)  ──  31.5 GB  (Installed Software)
└── Photos & Study Stuff          ──  12.2 GB
```

---

### 1. The Biggest Space Hog: Downloaded Games (~530 GB)

By far the largest space consumer is [C:\Drive_D\Games\Downloaded](file:///C:/Drive_D/Games/Downloaded):

| Folder                          | Size               | Status / Notes                            |
| :------------------------------ | :----------------- | :---------------------------------------- |
| **`GOW`** (God of War)  | **178.3 GB** | Ready to delete if completed or backed up |
| **`Black_Myth_wukong`** | **139.8 GB** | Ready to delete if completed or backed up |
| **`Crimson_Desert`**    | **130.4 GB** | Large download folder                     |
| **`The_last_of_us_1`**  | **81.1 GB**  | Complete pre-installed/repack folder      |

> [!TIP]
> Deleting or archiving even **one** of these games will immediately reclaim **80 GB to 180 GB**.

---

### 2. Standalone / Older Stable Diffusion Models (~10 GB)

In addition to your ComfyUI models, you have a separate folder at [C:\Drive_E\Stable Diffusion](<file:///C:/Drive_E/Stable%20Diffusion>) occupying **10.04 GB**:

* Contains older SD 1.5 checkpoints (`epicphotogasm`, `epicrealism`, `juggernaut_reborn`, `realisticVision` — ~2 GB each) + Loras and VAEs.
* If you primarily use SDXL and Flux inside ComfyUI, you can safely delete or move these to buy back **~10 GB**.

---

### 3. Immediate "Quick Wins" (~9 to 10 GB Safe to Purge)

You can safely reclaim ~9–10 GB right now without losing any personal files or games:

#### A. Purge Python Pip Download Cache (**~3.25 GB**)

Pip caches every `.whl` package downloaded during ComfyUI/Python setups:

```powershell
pip cache purge
```

#### B. Clean AMD Installer Leftovers & Shader Cache (**~4.99 GB**)

AMD keeps old driver installer extractions and shader caches in `%LOCALAPPDATA%\AMD`:

```powershell
Remove-Item "$env:LOCALAPPDATA\AMD\DxCache\*" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "$env:LOCALAPPDATA\AMD\OglCache\*" -Recurse -Force -ErrorAction SilentlyContinue
```

#### C. Remove the Duplicate Antigravity IDE Folder (**~1.05 GB**)

Because you copied Antigravity IDE to `C:\Program Files\Antigravity IDE`, replace the old duplicate with a 0-byte NTFS junction (close the IDE first):

```powershell
Remove-Item "C:\Users\void\AppData\Local\Programs\Antigravity IDE" -Recurse -Force
cmd /c mklink /J "C:\Users\void\AppData\Local\Programs\Antigravity IDE" "C:\Program Files\Antigravity IDE"
```

---

### Summary of What You Can Reclaim

| Target                                                    | Potential Space Reclaimed                    |
| :-------------------------------------------------------- | :------------------------------------------- |
| **Caches & Duplicates (Pip, AMD, Antigravity IDE)** | **~9 – 10 GB** (100% safe, no impact) |
| **Old Stable Diffusion 1.5 models**                 | **~10 GB**                             |
| **Any 1 Downloaded Game**                           | **+80 GB to 178 GB**                   |
| **All Completed Games**                             | **+530 GB**                            |
