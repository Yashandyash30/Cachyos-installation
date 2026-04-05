Here is a complete, step-by-step guide you can save for future reference or whenever you set up a fresh system with Niri, CachyOS, and Dank Material Shell.

### The Ultimate Guide: Fixing Dolphin (Qt) on Niri & Dank Material Shell

When using Niri (a standalone Wayland compositor) instead of a full desktop environment like KDE Plasma, Qt applications like Dolphin lose their background services and theming variables. This causes unreadable text (black-on-dark) and breaks the "Open With" menu.

Here is how to fix it permanently.

---

#### Phase 1: Install Required Dependencies

You need the KDE-specific Qt configuration tool to allow Dank Material Shell to sync its colors properly.

Open your terminal and install the following packages (using your AUR helper for `qt6ct-kde`):

```bash
sudo pacman -S qt5ct kvantum breeze
paru -S qt6ct-kde

```

*(Note: If paru asks to replace the standard qt6ct package, type Y for yes).*

#### Phase 2: Set the Global Environment Variables (Systemd Method)

Niri doesn't automatically pass environment variables to background services (like D-Bus), which is why Dolphin's theme often breaks after the first launch. You must set the variable at the `systemd` level.

1. Create the systemd environment directory:

```bash
mkdir -p ~/.config/environment.d

```
2. Create the configuration file and add the required Qt variable:

```bash
echo 'QT_QPA_PLATFORMTHEME=qt6ct' > ~/.config/environment.d/qt.conf

```

*(Setting it here guarantees that no matter how Dolphin is launched, it will always look for the correct theme).*

#### Phase 3: Apply the Dank Material Shell Theme

Now that the system knows to look for `qt6ct`, you need to generate the actual color scheme.

1. Open your **Dank Shell Settings**.
2. Navigate to **Theme & Colors**.
3. Scroll down to the **System App Theming** section.
4. Click **Apply Qt Colors**. This runs the built-in script that generates the `qt6ct` configurations to match your current shell theme.

#### Phase 4: Fix the "Open With" Menu Permanently

Dolphin relies on a background cache to know what apps are installed. We need to tell Niri to rebuild this cache every time you log in.

1. Open your Niri configuration file:

```bash
nano ~/.config/niri/config.kdl

```

*(Or use your preferred text editor).*
2. Find the section where you spawn startup processes (or add it anywhere at the top level), and add this exact line:

```code snippet
spawn-at-startup "kbuildsycoca6" "--noincremental"

```
3. Save and exit the file.

#### Phase 5: Clean Up and Reboot

To ensure no broken background instances of Dolphin are lingering in memory, kill the process and reboot your machine.

1. Kill any hidden Dolphin instances:

```bash
killall dolphin

```
2. **Reboot your system.**

Once you log back in, Dolphin will perfectly match your Dank Material Shell theme with readable text, and your "Open With" right-click menu will be fully populated!





That is an excellent point. The browser "Save As" and "Open File" dialogs use the GTK portal (`xdg-desktop-portal-gtk`), and because Niri doesn't have a GNOME/GTK settings daemon running in the background, those dialogs default to a blinding light theme.

Since Dank Material Shell has a built-in button for GTK as well (which we saw right next to the Qt button in your screenshot), we can integrate this perfectly. We just need to ensure the system is explicitly told to prefer dark mode for GTK apps.

Here is the **final, complete master guide**, now including the GTK portal fix for your browser dialogs!

---

### The Ultimate Guide: Fixing Dolphin (Qt) & File Dialogs (GTK) on Niri with Dank Material Shell

When using Niri (a standalone Wayland compositor), Qt apps like Dolphin and GTK file picker portals lose their background services and theming variables. This causes unreadable text, broken right-click menus, and blinding white "Save As" dialogs in browsers.

Here is how to fix all of it permanently.

---

#### Phase 1: Install Required Dependencies

You need the KDE-specific Qt configuration tool, base themes, and the GTK dependencies for the file portals.

Open your terminal and install the following packages:

```bash
sudo pacman -S qt5ct kvantum breeze adw-gtk-theme xdg-desktop-portal-gtk
paru -S qt6ct-kde

```

*(Note: If paru asks to replace the standard qt6ct package, type Y for yes. adw-gtk3 provides a proper base for GTK app theming).*

#### Phase 2: Set the Environment Variables

You need to tell your system to use `qt6ct` for theming. It is best to set this in both your Niri config and at the systemd level so background services don't drop the theme.

**1. Niri Configuration (~/.config/niri/config.kdl):**
Add the following `environment` block to your config file:

```code snippet
environment {
    QT_QPA_PLATFORMTHEME "qt6ct"
    QT_STYLE_OVERRIDE "kvantum" // Optional: if you prefer Kvantum over Breeze
}

```

**2. Systemd Configuration (Prevents theme breaking on 2nd launch):**
Run these commands in your terminal to create a persistent environment variable for background services like D-Bus:

```bash
mkdir -p ~/.config/environment.d
echo 'QT_QPA_PLATFORMTHEME=qt6ct' > ~/.config/environment.d/qt.conf

```

#### Phase 3: Force GTK Portals to Use Dark Mode

To fix the blinding white "Save As" and "Upload" dialogs in browsers, you must tell the GNOME/GTK backend that your system prefers dark mode. Run this command in your terminal:

```bash
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'

```

#### Phase 4: Apply the Dank Material Shell Themes

Now that the system knows where to look for themes and prefers dark mode, let DMS generate the actual color schemes.

1. Open your **Dank Shell Settings**.
2. Navigate to **Theme & Colors**.
3. Scroll down to the **System App Theming** section.
4. Click **Apply GTK Colors** (This fixes standard GTK apps and the `xdg-desktop-portal-gtk` dialogs).
5. Click **Apply Qt Colors** (This fixes Dolphin and other Qt apps).

#### Phase 5: Fix the "Open With" Menu Permanently

Dolphin relies on a background cache to know what apps are installed. Add **ONE** of the following lines to your `~/.config/niri/config.kdl` file under your startup processes:

- **Option 1: The True "KDE Experience" (Recommended)**
This runs the KDE background daemon. It actively watches your system, so if you install a new app, it will instantly appear in Dolphin's "Open With" menu without needing a reboot.

```code snippet
spawn-at-startup "kded6"

```
- **Option 2: The Lightweight Method**
This rebuilds the cache only when you log in. If you install a new app, it won't show up in Dolphin's menu until your next login (or until you run `kbuildsycoca6 --noincremental` manually).

```code snippet
spawn-at-startup "kbuildsycoca6" "--noincremental"

```

#### Phase 6: Clean Up and Reboot

To ensure no broken background instances of Dolphin or the GTK portals are lingering in memory, kill the processes and reboot your machine.

1. Kill hidden instances:

```bash
killall dolphin
killall xdg-desktop-portal-gtk

```
2. **Reboot your system.**

Once you log back in, Dolphin will be perfectly themed with readable text, your right-click "Open With" menu will work dynamically, and your browser's "Save As" dialogs will finally respect your dark system theme!

Yes, you can absolutely make Dolphin the default file manager for the entire system. Because you are on a standalone compositor like Niri, you will need to set this using the standard Linux `xdg-mime` tool, which tells the system how to handle different types of files and directories.

Here is how to route all "Open Folder" or "Show in File Manager" requests (like from your web browser or terminal) to Dolphin.

### 1. Set Dolphin as the Default Directory Handler

The system identifies folders as a MIME type called `inode/directory`. You need to tell the system that Dolphin's `.desktop` file is the master handler for this type.

Run this command in your terminal:

```bash
xdg-mime default org.kde.dolphin.desktop inode/directory

```

### 2. Verify the Change

To make sure the system registered the change correctly, run the query command:

```bash
xdg-mime query default inode/directory

```

*If it returns org.kde.dolphin.desktop, you are good to go.*

### 3. Set the Environment Variable (For Stubborn Terminal Apps)

While `xdg-mime` handles 95% of graphical applications (like browsers and Discord), some command-line tools or older scripts look for a specific environment variable to decide which file manager to launch.

To cover all your bases, add the `FILEMANAGER` variable to your Niri configuration so it is applied globally at startup.

Open your `~/.config/niri/config.kdl` and add it to your existing `environment` block so it looks like this:

```code snippet
environment {
    QT_QPA_PLATFORMTHEME "qt6ct"
    QT_STYLE_OVERRIDE "kvantum" 
    FILEMANAGER "dolphin"
}

```

Save the file. The next time you log in, absolutely everything on your system will default to Dolphin!
