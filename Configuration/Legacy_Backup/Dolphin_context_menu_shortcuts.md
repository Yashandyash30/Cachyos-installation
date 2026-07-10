Universal guide to building Dolphin context menu shortcuts for any application.

### The Universal Blueprint

Every custom right-click option requires a `.desktop` file placed in `~/.local/share/kio/servicemenus/`.

To create a new one, you always run:

```bash
nano ~/.local/share/kio/servicemenus/choose-a-name.desktop

```

Inside that file, you use this exact master template. You only ever need to change the **`Name`**, the **`Icon`**, and the **`Exec`** lines:

```ini
[Desktop Entry]
Type=Service
MimeType=inode/directory;
Actions=LaunchMySelectedApp;

[Desktop Action LaunchMySelectedApp]
Name=Open in [App Name]
Icon=[system-icon-name]
Path=%f
Exec=[app-launch-command] "%f"

```

---

### Scenario A: Standard GUI Editors (VS Code, Zed, Sublime)

For graphical editors, the setup is identical to what we just did for Antigravity IDE. You just need to know the command you usually type in the terminal to launch the app (e.g., `code` for VS Code, `zed` for Zed).

**Example: VS Code (`code`)**
Create the file: `nano ~/.local/share/kio/servicemenus/vscode.desktop`

```ini
[Desktop Entry]
Type=Service
MimeType=inode/directory;
Actions=OpenVSCode;

[Desktop Action OpenVSCode]
Name=Open in VS Code
Icon=vscode
Path=%f
Exec=code "%f"

```

---

### Scenario B: Terminal-Based Editors (Neovim, Micro, Helix)

This is where most people get stuck. If you try to launch a terminal app (like `nvim`) directly from a background service menu, it will immediately crash because it has no graphical window to draw itself inside.

To fix this, you must tell the `Exec` line to launch your **Terminal Emulator** first, set the working directory, and *then* run the editor inside it.

Assuming you are using KDE's default terminal (`konsole`), here is how you build a Neovim shortcut.

**Example: Neovim (`nvim`)**
Create the file: `nano ~/.local/share/kio/servicemenus/neovim.desktop`

```ini
[Desktop Entry]
Type=Service
MimeType=inode/directory;
Actions=OpenNeovim;

[Desktop Action OpenNeovim]
Name=Open in Neovim
Icon=nvim
Path=%f
# Launch Konsole, set the path, and execute nvim
Exec=konsole --workdir "%f" -e nvim .

```

*(If you use a different terminal in your Niri setup, like Alacritty, the line would be: `Exec=alacritty --working-directory "%f" -e nvim .`)*

---

### The Final Activation Steps

No matter what app you are adding, you must always perform these two steps after saving the `.desktop` file so the system trusts it and reloads the menu.

**1. Make the file executable:**

```bash
chmod +x ~/.local/share/kio/servicemenus/your-file-name.desktop

```

**2. Restart the file manager:**

```bash
killall dolphin

```

Whenever you install a new tool that you want quick access to, just copy that blueprint, swap out the execution command, run the permissions check, and it will permanently live in your right-click menu!
