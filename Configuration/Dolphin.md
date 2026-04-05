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










You are absolutely right, it is much better to have all the options and failsafes documented in one place. Having the KDE daemon option is especially useful if you install new apps frequently.

Here is the fully updated, comprehensive guide including both the Niri environment variables and the dynamic background daemon options.

### The Ultimate Guide: Fixing Dolphin (Qt) on Niri & Dank Material Shell

When using Niri (a standalone Wayland compositor) instead of a full desktop environment like KDE Plasma, Qt applications like Dolphin lose their background services and theming variables. This causes unreadable text (black-on-dark) and breaks the "Open With" menu.

Here is how to fix it permanently.

---

#### Phase 1: Install Required Dependencies

You need the KDE-specific Qt configuration tool to allow Dank Material Shell to sync its colors properly, along with base themes.

Open your terminal and install the following packages:

```bash
sudo pacman -S qt5ct kvantum breeze
paru -S qt6ct-kde

```

*(Note: If paru asks to replace the standard qt6ct package, type Y for yes).*

#### Phase 2: Set the Environment Variables

You need to tell your system to use `qt6ct` for theming. For maximum reliability, it is best to set this in both your Niri config and at the systemd level (so background services don't drop the theme).

**1. Niri Configuration (~/.config/niri/config.kdl):**
Add the following `environment` block to your config file (or add the variables to your existing block):

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

#### Phase 3: Apply the Dank Material Shell Theme

Now that the system knows to look for `qt6ct`, you need to generate the actual color scheme.

1. Open your **Dank Shell Settings**.
2. Navigate to **Theme & Colors**.
3. Scroll down to the **System App Theming** section.
4. Click **Apply Qt Colors**. This runs the built-in script that generates the `qt6ct` configurations to match your current shell theme.

#### Phase 4: Fix the "Open With" Menu Permanently

Dolphin relies on a background cache to know what apps are installed. Niri needs to rebuild or manage this cache at startup. Add **ONE** of the following lines to your `~/.config/niri/config.kdl` file under your startup processes:

- **Option 1: The Lightweight Method (Rebuilds on Login)**
This runs a one-shot command to rebuild the cache when you log in. If you install a new app while using the computer, it won't show up in Dolphin's menu until your next login (or until you run the command manually).

```code snippet
spawn-at-startup "kbuildsycoca6" "--noincremental"

```
- **Option 2: The True "KDE Experience" (Updates Dynamically)**
This runs the KDE background daemon. It uses slightly more background memory, but it actively watches your system. If you install a new app, it will instantly appear in Dolphin's "Open With" menu without needing a reboot.

```code snippet
spawn-at-startup "kded6"

```

#### Phase 5: Clean Up and Reboot

To ensure no broken background instances of Dolphin are lingering in memory, kill the process and reboot your machine to apply the systemd variables and Niri startup commands.

1. Kill any hidden Dolphin instances:

```bash
killall dolphin

```
2. **Reboot your system.**

Once you log back in, Dolphin will perfectly match your Dank Material Shell theme, the text will be readable, and your right-click "Open With" menu will work exactly as intended!
