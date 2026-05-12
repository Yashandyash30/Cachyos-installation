# Fixing Dolphin & File Dialogs on Niri with Dank Material Shell

When using Niri as a standalone Wayland compositor (instead of a full desktop environment like KDE Plasma), Qt apps like Dolphin and GTK file picker portals lose their background services and theming. This causes:

- Unreadable text (black-on-dark) in Dolphin
- A broken "Open With" right-click menu
- Blinding white "Save As" / "Upload" dialogs in browsers

This guide fixes all three issues permanently.

---

## Step 1 — Install Dependencies

Install all required packages in one go. This covers Qt theming, GTK theming, and the file portal backend.

```bash
sudo pacman -S qt5ct kvantum breeze adw-gtk-theme xdg-desktop-portal-gtk
paru -S qt6ct-kde
```

> **Note:** If `paru` asks to replace the standard `qt6ct` package, type `Y` to confirm.

---

## Step 2 — Set Environment Variables

Qt needs to be told to use `qt6ct` for theming. Set this in **both** places below — the Niri config handles your session, and the systemd config ensures background services (like D-Bus) don't lose the theme after the first launch.

### 2a. Niri config (`~/.config/niri/config.kdl`)

Open the file in your editor:

```bash
nano ~/.config/niri/config.kdl
```

Add this `environment` block at the top level:

```
environment {
  XDG_CURRENT_DESKTOP "niri"
  XDG_MENU_PREFIX "plasma-"
  QT_QPA_PLATFORMTHEME "qt6ct"
  FILEMANAGER "dolphin"
}
```

> `QT_STYLE_OVERRIDE "kvantum"` is optional — include it only if you prefer Kvantum over Breeze.  
> `FILEMANAGER "dolphin"` is needed for some CLI tools and older scripts that check this variable.

### 2b. Systemd config (prevents theme breaking on second launch)

Run these two commands in your terminal:

```bash
mkdir -p ~/.config/environment.d
echo 'QT_QPA_PLATFORMTHEME=qt6ct' > ~/.config/environment.d/qt.conf
```

---

## Step 3 — Force GTK Portals to Dark Mode

This fixes the blinding white "Save As" and "Upload" dialogs in browsers. Run this command to tell the GTK backend that your system prefers dark mode:

```bash
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
```

---

## Step 4 — Apply Themes via Dank Material Shell

Now that the system knows where to look for themes, generate the actual color schemes from within DMS:

1. Open **Dank Shell Settings**
2. Go to **Theme & Colors**
3. Scroll to the **System App Theming** section
4. Click **Apply GTK Colors** — fixes browser dialogs and standard GTK apps
5. Click **Apply Qt Colors** — fixes Dolphin and other Qt apps

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
