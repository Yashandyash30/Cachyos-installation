# Antigravity IDE Font Configuration Guide

This guide will walk you through installing the Nerd Font we configured and setting it up in Antigravity IDE on your other device, ensuring all icons render correctly.

## Step 1: Download and Install the Font

We used the **JetBrainsMono Nerd Font**.

### Download
1. Go to the [Nerd Fonts Releases page on GitHub](https://github.com/ryanoasis/nerd-fonts/releases).
2. Download the `JetBrainsMono.zip` file from the latest release assets.

### Installation

**Linux:**
1. Extract the `.zip` file.
2. Move the `.ttf` files to your user fonts directory: `~/.local/share/fonts/` (create the directory if it doesn't exist).
3. Run the following command in your terminal to update the font cache:
   ```bash
   fc-cache -fv
   ```

**Windows:**
1. Extract the `.zip` file.
2. Select all the extracted `.ttf` files, right-click, and select **"Install"** or **"Install for all users"**.

**macOS:**
1. Extract the `.zip` file.
2. Double-click the `.ttf` files and click **"Install Font"** in the Font Book window.

---

## Step 2: Configure Antigravity IDE

Once the font is installed on the system, you need to tell Antigravity IDE to use it for the editor, terminal, and the chat interface.

1. Open Antigravity IDE.
2. Open the Settings file (`settings.json`). You can usually find the configuration file in:
   - **Linux:** `~/.config/Antigravity IDE/User/settings.json`
   - **Windows:** `%APPDATA%\Antigravity IDE\User\settings.json`
   - **macOS:** `~/Library/Application Support/Antigravity IDE/User/settings.json`
   *(Alternatively, in the IDE, press `Ctrl+Shift+P` (or `Cmd+Shift+P` on Mac) and search for **"Preferences: Open User Settings (JSON)"**).*

3. Add or update the following font family configurations at the top level of your `settings.json`:

```json
{
    "editor.fontFamily": "'JetBrainsMono Nerd Font', 'MesloLGS Nerd Font', 'monospace'",
    "terminal.integrated.fontFamily": "'JetBrainsMono Nerd Font', 'MesloLGS Nerd Font', 'monospace'",
    "chat.editor.fontFamily": "'JetBrainsMono Nerd Font', 'MesloLGS Nerd Font', 'monospace'"
}
```

> [!NOTE]
> Make sure to include the single quotes around the font names, as they contain spaces. If you already have other settings in this file, just add these three lines separated by commas where appropriate.

## Step 3: Restart the IDE

After saving the `settings.json` file, the editor and terminal might update immediately. However, for UI panels like the Chat/Agent panel, it's best to restart the IDE. 

- Press `Ctrl+Shift+P` and type **"Reload Window"** to refresh, or simply close and reopen the IDE.

Your icons should now render perfectly across the entire editor, terminal, and chat!
