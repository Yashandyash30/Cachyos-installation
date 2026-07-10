Step-by-step migration guide for the second machine so you don't hit any of those Webview or Jupyter workspace bugs again.

### Phase 1: The Pre-Update Backup

Before you update your system or touch the AUR, secure your current extensions and settings.

1. Open your terminal on the second machine.
2. Run this backup command:
```bash
mkdir -p ~/Desktop/Antigravity_Backup
cp -r ~/.config/Antigravity ~/Desktop/Antigravity_Backup/config
cp -r ~/.antigravity ~/Desktop/Antigravity_Backup/extensions

```



### Phase 2: The Package Swap

Now you can safely swap the binaries.

1. Remove the 2.0 agent version (if it updated automatically) or the old IDE package:
```bash
paru -Rns antigravity

```


2. Install the community-maintained IDE fork:
```bash
paru -S antigravity-ide

```



### Phase 3: Preemptive Niri Fixes

If your second machine is also running your Niri Wayland setup, you can kill the keyring error before it even pops up.

1. Ensure the keyring packages are installed:
```bash
paru -S gnome-keyring libsecret seahorse

```


2. Double-check your `~/.config/niri/config.kdl` to make sure the daemon is spawning on login:
```kdl
spawn-at-startup "gnome-keyring-daemon" "--start" "--components=secrets"

```



### Phase 4: The Clean Slate Migration

This is where we bypass the bugs you hit today. Instead of letting the IDE try to read old caches, we are going to wipe the slate clean *before* we launch it.

1. Wipe any leftover Webview and Service Worker caches:
```bash
rm -rf ~/.config/"Antigravity IDE"/Cache
rm -rf ~/.config/"Antigravity IDE"/"Code Cache"
rm -rf ~/.config/"Antigravity IDE"/"Service Worker"

```


2. Wipe the old workspace storage so your Jupyter notebooks don't fail to load their paths:
```bash
rm -rf ~/.config/"Antigravity IDE"/workspaceStorage

```


3. Run the IDE once from the terminal to initialize it, then close it:
```bash
antigravity-ide

```
> Note You should skip (click Cancel) on the automatic "Migrate" prompt.

> Here is why: That built-in migration script only does half the job. It copies your User settings and extensions, but it completely ignores the hidden caches.

> If you let the script run automatically, you risk dragging over the exact same stale workspaceStorage database (which broke your Jupyter paths) and the incompatible Service Worker cache (which broke your notebook webviews).

> By clicking Cancel and running the manual "Clean Slate Migration" commands from Phase 4 instead, you guarantee those problematic caches are wiped out before your settings are copied over. It gives you complete control and ensures you bypass the bugs we just spent time fixing.

4. Finally, map your backups into the new directories:
```bash
cp -r ~/Desktop/Antigravity_Backup/config/* ~/.config/"Antigravity IDE"/
cp -r ~/Desktop/Antigravity_Backup/extensions/* ~/.antigravity-ide/

```



When you launch it again, it will be exactly as you left it, with all your extensions loaded, Jupyter server paths resolving correctly, and the GitHub sync tied securely to your keyring.
