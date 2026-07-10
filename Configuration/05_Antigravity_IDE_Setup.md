# 05 - Antigravity IDE Setup Guide

This document aggregates all configuration steps for the Antigravity IDE, including font setup, JSON configuration, package migration, and the Jupyter Notebook MCP server.

---

## 1. Antigravity IDE Font Configuration Guide (JetBrainsMono Nerd Font)

> [!NOTE]
> **Automated Setup Completed:** `03-software-install.sh` automatically installs `ttf-jetbrains-mono-nerd` system-wide. You only need to configure the IDE settings.

### Configure Antigravity IDE Settings
1. Open Antigravity IDE.
2. Press `Ctrl+Shift+P` and search for **"Preferences: Open User Settings (JSON)"**.
3. Add or update the following font family configurations at the top level of your `settings.json`:
```json
{
    "editor.fontFamily": "'JetBrainsMono Nerd Font', 'MesloLGS Nerd Font', 'monospace'",
    "terminal.integrated.fontFamily": "'JetBrainsMono Nerd Font', 'MesloLGS Nerd Font', 'monospace'",
    "chat.editor.fontFamily": "'JetBrainsMono Nerd Font', 'MesloLGS Nerd Font', 'monospace'"
}
```
*(Make sure to include the single quotes around the font names, as they contain spaces).*
4. Restart the IDE or reload the window (`Ctrl+Shift+P` -> **"Reload Window"**).

---

## 2. Preventing Auto-Formatting in JSON Configs

To prevent the editor from automatically expanding objects into multiple lines in your JSON configurations (like `config.jsonc`) when you save:
1. Open your Settings (`Ctrl+,`).
2. Click the **Open Settings (JSON)** icon.
3. Add the following to disable **Format On Save** specifically for JSON files:
```json
  "[jsonc]": {
      "editor.formatOnSave": false
  },
  "[json]": {
      "editor.formatOnSave": false
  }
```

---

## 3. IDE Migration & Clean Slate Guide

If you ever need to migrate your Antigravity IDE setup or clear out corrupted Webview/Jupyter caches, follow these steps to avoid carrying over bugs.

### Phase 1: The Pre-Update Backup
Secure your current extensions and settings:
```bash
mkdir -p ~/Desktop/Antigravity_Backup
cp -r ~/.config/Antigravity ~/Desktop/Antigravity_Backup/config
cp -r ~/.antigravity ~/Desktop/Antigravity_Backup/extensions
```

### Phase 2: The Package Swap
Remove the old IDE package and install the community fork:
```bash
paru -Rns antigravity
paru -S antigravity-ide
```

### Phase 3: Preemptive Niri Fixes (Keyring)
Ensure the keyring daemon is spawning on login in your `~/.config/niri/config.kdl`:
```kdl
spawn-at-startup "gnome-keyring-daemon" "--start" "--components=secrets"
```

### Phase 4: The Clean Slate Migration
Wipe leftover caches *before* restoring your backups:
1. Wipe Webview and Service Worker caches:
```bash
rm -rf ~/.config/"Antigravity IDE"/Cache
rm -rf ~/.config/"Antigravity IDE"/"Code Cache"
rm -rf ~/.config/"Antigravity IDE"/"Service Worker"
```
2. Wipe the workspace storage (fixes Jupyter paths):
```bash
rm -rf ~/.config/"Antigravity IDE"/workspaceStorage
```
3. Launch the IDE once from the terminal (`antigravity-ide`), **click Cancel on the automatic "Migrate" prompt**, and close it.
4. Map your backups into the new directories:
```bash
cp -r ~/Desktop/Antigravity_Backup/config/* ~/.config/"Antigravity IDE"/
cp -r ~/Desktop/Antigravity_Backup/extensions/* ~/.antigravity-ide/
```

---

## 4. Installation Guide for `antigravity-nb` (Jupyter MCP Server)

### Step 1: Register Your Environment as a Kernel
Ensure your Conda/Miniforge environment has a Jupyter kernel:
```bash
conda activate your_env_name
conda install ipykernel
python -m ipykernel install --user --name your_env_name --display-name "Python (your_env_name)"
```

### Step 2: Install the MCP Server
```bash
pip install git+https://github.com/Ian747-tw/Antigravity-Jupiter-Notebook-MCP.git
```

### Step 3: Find the Absolute Executable Path
```bash
which antigravity-nb
```
*(Note the exact path, e.g., `/home/void/miniforge3/bin/antigravity-nb`)*

### Step 4: Configure the JSON File
Add the server block to `~/.gemini/antigravity/mcp_config.json`, replacing the command with the path from Step 3:
```json
{
  "mcpServers": {
    "antigravity-nb": {
      "command": "/YOUR/EXACT/PATH/antigravity-nb",
      "args": [
        "serve-agent",
        "--workspace-root",
        "${workspaceFolder}"
      ]
    }
  }
}
```

### Step 5: Reload and Verify
1. Open the Command Palette (`Ctrl+Shift+P`) and run **Refresh MCP Servers**.
2. Ask the AI: *"List the tools available from antigravity-nb"*.
3. Create a `test.ipynb`, add a print statement, and ask the AI to run it.
