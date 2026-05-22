Master guide to setting up the dual `fastfetch` system. By following these steps, you will have your minimal layout load automatically, and your massive, detailed layout available on demand with the `fetchfull` command.

Since I can see from your screenshots that you are using the **fish** shell, the alias instructions below are tailored specifically for you.

---

### Step 1: Create the Minimal Default Config

This is the compact layout that will run automatically when you open a new terminal or type `fastfetch`.

1. Open your default config file:
```bash
nano ~/.config/fastfetch/config.jsonc

```


2. Delete everything inside, paste this exact code, and save (`Ctrl+O`, `Enter`, `Ctrl+X`):
```json
{
    "$schema": "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json",
    "logo": {
        "type": "none"
    },
    "display": {
        "separator": " ➜ ",
        "color": {
            "separator": "90"
        }
    },
    "modules": [
        { "type": "title", "format": "{user-name}@{host-name}" },
        { "type": "custom", "format": "─────────────", "outputColor": "90" },
        { "type": "os", "key": "OS ", "keyColor": "31" },
        { "type": "kernel", "key": "KRN", "keyColor": "32" },
        { "type": "wm", "key": "WM ", "keyColor": "33" },
        { "type": "shell", "key": "SHL", "keyColor": "34" },
        { "type": "cpu", "key": "CPU", "keyColor": "35" },
        { "type": "memory", "key": "RAM", "keyColor": "36" },
        { "type": "uptime", "key": "UP ", "keyColor": "31" },
        { "type": "custom", "format": "\u001b[31m● \u001b[32m● \u001b[33m● \u001b[34m● \u001b[35m● \u001b[36m●" }
    ]
}

```



### Step 2: Create the Full Detailed Config

This is your massive layout with the Hyprland logo and the complete pacman/flatpak package breakdown we just built.

1. Create a second config file named `full.jsonc`:
```bash
nano ~/.config/fastfetch/full.jsonc

```


2. Paste this exact code and save (`Ctrl+O`, `Enter`, `Ctrl+X`):
```json
{
  "$schema": "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json",
  "logo": {
    "height": 10,
    "padding": {
      "top": 7
    }
  },
  "display": {
    "separator": " ➜ "
  },
  "modules": [
    "break",
    "break",
    { "type": "custom", "format": "\u001b[90m●  \u001b[31m●  \u001b[32m●  \u001b[33m●  \u001b[34m●  \u001b[35m●  \u001b[36m●  \u001b[37m● " },
    "break",
    { "type": "title", "keyWidth": 8 },
    { "type": "custom", "format": "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" },
    "break",
    { "type": "os", "key": " OS   ", "keyColor": "31" },
    { "type": "kernel", "key": " ├ KRN", "keyColor": "31" },
    { "type": "command", "key": " ├ PKG", "keyColor": "31", "text": "echo \"$(pacman -Qq | wc -l) (Total)\"" },
    { "type": "command", "key": " ├ USR", "keyColor": "31", "text": "echo \"$(pacman -Qqe | wc -l) (Explicit)\"" },
    { "type": "command", "key": " ├ SYS", "keyColor": "31", "text": "echo \"$(pacman -Qqd | wc -l) (Dependencies)\"" },
    { "type": "command", "key": " ├ AUR", "keyColor": "31", "text": "echo \"$(pacman -Qqm | wc -l) (Foreign)\"" },
    { "type": "command", "key": " ├ FLT", "keyColor": "31", "text": "echo \"$(flatpak list --app 2>/dev/null | wc -l || echo 0) (Flatpaks)\"" },
    { "type": "shell", "key": " └ SHL", "keyColor": "31" },
    "break",
    { "type": "wm", "key": " WM   ", "keyColor": "32" },
    { "type": "wmtheme", "key": " ├ THM", "keyColor": "32" },
    { "type": "icons", "key": " ├ ICN", "keyColor": "32" },
    { "type": "cursor", "key": " ├ CUR", "keyColor": "32" },
    { "type": "terminal", "key": " ├ TRM", "keyColor": "32" },
    { "type": "terminalfont", "key": " └ FNT", "keyColor": "32" },
    "break",
    { "type": "host", "format": "{5} {1} ({2})", "key": " PC   ", "keyColor": "33" },
    { "type": "cpu", "format": "{1} ({3}) @ {7}", "key": " ├ CPU", "keyColor": "33" },
    { "type": "gpu", "format": "{1} {2} @ {12}", "key": " ├ GPU", "keyColor": "33" },
    { "type": "memory", "key": " ├ RAM", "keyColor": "33" },
    { "type": "swap", "key": " ├ SWP", "keyColor": "33" },
    { "type": "disk", "key": " ├ DSK", "keyColor": "33" },
    { "type": "monitor", "key": " └ MON", "keyColor": "33" },
    "break",
    { "type": "uptime", "key": " UP   ", "keyColor": "34" },
    { "type": "datetime", "format": "{1}-{3}-{11}", "key": " ├ DAT", "keyColor": "34" },
    { "type": "command", "key": " └ DAY", "keyColor": "34", "text": "birth_install=$(stat -c %W /); current=$(date +%s); time_progression=$((current - birth_install)); days_difference=$((time_progression / 86400)); echo $days_difference days" },
    "break",
    { "type": "command", "key": " SH   ", "keyColor": "34", "text": "splash=$(hyprctl splash);echo $splash" },
    { "type": "custom", "format": "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" },
    "break",
    { "type": "custom", "format": "\u001b[90m●  \u001b[31m●  \u001b[32m●  \u001b[33m●  \u001b[34m●  \u001b[35m●  \u001b[36m●  \u001b[37m● " },
    "break",
    "break"
  ]
}

```


*(Note: I removed the local image path from the logo block so it will default to the standard OS logo. If you want your custom image back, just add `"source": "~/.config/fastfetch/fast-images/hypr.png",` and `"type": "kitty",` back into the logo block).*

### Step 3: Set up the Fish Alias

Now we link the command `fetchfull` to that second file we just created.

1. Open your fish configuration file:
```bash
nano ~/.config/fish/config.fish

```


2. Scroll to the bottom and add this exact line:
```bash
alias fetchfull="fastfetch -c full"

```


3. Save and exit (`Ctrl+O`, `Enter`, `Ctrl+X`).
4. Reload your shell to apply the changes:
```bash
source ~/.config/fish/config.fish

```



### Step 4: Test It Out!

You are completely finished. Try them both:

* Run **`fastfetch`** ➜ You should see your tiny, 10-line minimal layout.
* Run **`fetchfull`** ➜ You should see your massive, highly-detailed tree layout.
