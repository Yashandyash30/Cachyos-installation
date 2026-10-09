# Fixing Dolphin & File Dialogs on Niri with Dank Material Shell

When using Niri as a standalone Wayland compositor (instead of a full desktop environment like KDE Plasma), Qt apps like Dolphin and GTK file picker portals lose their background services and theming. This causes:

- Unreadable text (black-on-dark) in Dolphin
- A broken "Open With" right-click menu
- Blinding white "Save As" / "Upload" dialogs in browsers

This guide fixes all three issues permanently.

---

## Step 1 — Install Dependencies

Install required packages for KDE/Qt theming, GTK theming, and file portals. Using `plasma-integration` provides the native KDE platform theme (`KDEPlasmaPlatformTheme6.so`), which stays in sync with official Qt updates and avoids the ABI plugin version mismatch issues common with AUR `qt6ct-kde`.

```bash
sudo pacman -S plasma-integration breeze adw-gtk-theme xdg-desktop-portal-gtk
```

---

## Step 2 — Set Environment Variables

Tell Qt applications to use the native `kde` platform theme. Set this in **both** places below — the Niri config handles your graphical session, and the systemd config ensures background services (like D-Bus and portals) don't lose the theme.

### 2a. Niri config (`~/.config/niri/config.kdl`)

Open the file in your editor:

```bash
nano ~/.config/niri/config.kdl
```

Add (or update) this `environment` block at the top level:

```kdl
environment {
  XDG_CURRENT_DESKTOP "niri"
  XDG_MENU_PREFIX "plasma-"
  QT_QPA_PLATFORMTHEME "kde"
  FILEMANAGER "dolphin"
}
```

> **Why `kde` instead of `qt6ct`?**  
> Dolphin is a native KDE application. Out-of-tree plugins like `qt6ct-kde` break whenever `qt6-base` receives a minor update (giving `Ignoring QPA plugin due to mismatching Qt versions`, which causes unstyled black text). Using `kde` ensures the theme never breaks across Qt updates.

### 2b. Systemd config (ensures consistency across launches)

Run these two commands in your terminal:

```bash
mkdir -p ~/.config/environment.d
echo 'QT_QPA_PLATFORMTHEME=kde' > ~/.config/environment.d/qt.conf
```

---

## Step 3 — Force GTK Portals to Dark Mode

This fixes the blinding white "Save As" and "Upload" dialogs in browsers. Run this command to tell the GTK backend that your system prefers dark mode:

```bash
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
```

---

## Step 4 — Apply Themes via Dank Material Shell & KDE

Now apply the Matugen-generated colors to both GTK and KDE/Qt:

### 4a. Apply to KDE / Dolphin
Run this command to sync the generated Dank Shell colors to KDE's `kdeglobals`:

```bash
plasma-apply-colorscheme DankMatugen
```
*(If you prefer the dedicated dark variant, you can use `plasma-apply-colorscheme DankMatugenDark`).*

### 4b. Apply in Dank Shell Settings
1. Open **Dank Shell Settings**
2. Go to **Theme & Colors**
3. Scroll to the **System App Theming** section
4. Click **Apply GTK Colors** — fixes browser dialogs and standard GTK apps
5. Click **Apply Qt Colors**

---

## Step 5 — Fix the "Open With" Menu

Dolphin relies on a background cache to know which apps are installed. Choose **one** of the options below and add it to the startup section of your `~/.config/niri/config.kdl`.

| Option | Command | Behaviour |
|---|---|---|
| **Recommended** — Full KDE daemon | `spawn-at-startup "kded6"` | Watches for new apps in real time; "Open With" updates instantly after installing an app |
| Lightweight | `spawn-at-startup "kbuildsycoca6" "--noincremental"` | Rebuilds the cache once at login; new apps won't appear until next reboot |

Add your chosen line inside `~/.config/niri/config.kdl`:

```
spawn-at-startup "kded6"
```

---

## Step 6 — Set Dolphin as the Default File Manager

This routes all "Open Folder" and "Show in File Manager" requests (from browsers, Discord, terminals, etc.) to Dolphin.

### 6a. Register Dolphin as the default directory handler

```bash
xdg-mime default org.kde.dolphin.desktop inode/directory
```

### 6b. Verify the change took effect

```bash
xdg-mime query default inode/directory
```

Expected output: `org.kde.dolphin.desktop`

> The `FILEMANAGER "dolphin"` line you added in Step 2a covers the remaining ~5% of CLI tools that don't use `xdg-mime`.

---

## Step 7 — Clean Up and Reboot

Kill any lingering background instances before rebooting so nothing stale carries over:

```bash
killall dolphin
killall xdg-desktop-portal-gtk
```

Then **reboot your system.**

---

## What You Get After Rebooting

| Issue | Fixed by |
|---|---|
| Black-on-dark unreadable text in Dolphin | Steps 2, 4 |
| "Open With" menu empty or broken | Step 5 |
| White "Save As" dialogs in browsers | Steps 3, 4 |
| Dolphin not opening when clicking folders | Step 6 |
| Dolphin not showing open with | `kbuildsycoca6 --noincremental`|
