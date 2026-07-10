# Fixing btop on CachyOS (Missing UTF-8 Locale)

`btop` uses braille and block characters to draw its CPU and RAM graphs. If your system hasn't explicitly declared UTF-8 support, `btop` refuses to run rather than render a garbled mess.

On CachyOS with an `en_IN` locale, the most common cause is that `.UTF-8` is missing from your locale variables — so the system falls back to a legacy encoding that doesn't support those characters.

---

## Quick Fix (Run btop Right Now)

If you just need to check your system immediately and your terminal (Alacritty, Kitty, etc.) already handles UTF-8 natively, use the force flag:

```bash
btop --force-utf
```

This bypasses the check for this session only. Follow the steps below to fix it permanently.

---

## Permanent Fix

### Step 1 — Uncomment the locale in `/etc/locale.gen`

Open the locale generator file:

```bash
sudo nano /etc/locale.gen
```

Find this line and remove the leading `#` to uncomment it:

```
# Before
#en_IN.UTF-8 UTF-8

# After
en_IN.UTF-8 UTF-8
```

Save with **Ctrl+O → Enter**, then exit with **Ctrl+X**.

### Step 2 — Generate the locale

Compile the locale you just uncommented:

```bash
sudo locale-gen
```

### Step 3 — Fix `/etc/locale.conf`

Your locale config likely has `en_IN` entries without the `.UTF-8` suffix, which is the root cause. Replace the entire file contents with this clean block:

```bash
sudo nano /etc/locale.conf
```

Delete everything currently in the file and paste in:

```
LANG=en_IN.UTF-8
LC_ADDRESS=en_IN.UTF-8
LC_IDENTIFICATION=en_IN.UTF-8
LC_MEASUREMENT=en_IN.UTF-8
LC_MONETARY=en_IN.UTF-8
LC_NAME=en_IN.UTF-8
LC_NUMERIC=en_IN.UTF-8
LC_PAPER=en_IN.UTF-8
LC_TELEPHONE=en_IN.UTF-8
LC_TIME=en_IN.UTF-8
```

Save and exit (**Ctrl+O → Enter**, then **Ctrl+X**).

> **KDE Plasma note:** If the fix doesn't stick after a reboot, Plasma may be overriding locale settings from its own config file. Check and apply the same format there:
> ```bash
> nano ~/.config/plasma-localerc
> ```

> Put this line there also
> ```bash
>LANG=en_IN.UTF-8
> ```

---

## Apply Without Rebooting

To pick up the new locale in your current terminal session immediately:

```bash
export LANG=en_IN.UTF-8
export LC_ALL=en_IN.UTF-8
```
Then launch `btop` normally — no flags needed.

For all other apps and your full desktop environment, **log out and back in** (or reboot) to flush the old variables system-wide.

Reload Your Session

The easiest way to flush out the old, broken variables and apply the new UTF-8 ones across your entire desktop environment (including CachyOS, Niri, and your terminal) is to just log out and log back in, or reboot your laptop.

Once you are back in, pop open your terminal, type btop, and it will instantly load up those crisp resource graphs.
