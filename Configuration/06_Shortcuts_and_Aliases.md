# 06 - Shortcuts, Aliases, and Keybinds Guide

This document is your master reference for keyboard shortcuts, terminal aliases, and custom right-click menus.

---

## 1. Global Niri Keybind Reference

> `Mod` = your compositor modifier key &nbsp;·&nbsp; `Super` = Win/Logo key

### Launch & Apps
| Keys | Action |
|------|--------|
| `Super` + `Enter` | Open terminal (Ghostty) |
| `Super` + `B` | Open Zen Browser |
| `Super` + `E` | Open Dolphin (file manager) |
| `Super` + `T` | Open Zed editor |
| `Super` + `Space` | Application launcher (Spotlight) |
| `Alt` + `Space` | Walker launcher |
| `Alt` + `F` | FSearch (file search) |
| `Mod` + `Ctrl` + `Space` | Fuzzy file search (plocate → xdg-open) |
| `Mod` + `Shift` + `N` | Toggle notepad |

### System & Shell
| Keys | Action |
|------|--------|
| `Alt` + `F4` | Power menu toggle |
| `Mod` + `Alt` + `L` | Lock screen |
| `Mod` + `,` | Settings |
| `Ctrl` + `Alt` + `Del` / `Mod` + `M` | Task manager |
| `Mod` + `N` | Notification center |
| `Mod` + `V` | Clipboard manager |
| `Mod` + `Y` | Browse wallpapers |
| `Mod` + `Shift` + `W` | Create window rule |

### Media & Hardware
| Keys | Action |
|------|--------|
| `Vol↑` / `Vol↓` | Volume +3 / -3 |
| `Ctrl` + `Vol↑/↓` | Media (MPRIS) volume +3 / -3 |
| `Mute` / `Mic Mute` | Toggle mute / mic mute |
| `Play/Pause` | Play / pause |
| `Next` / `Prev` | Next track / Previous track |
| `Bright↑` / `Bright↓` | Brightness +5 / -5 |

### Workspace Management
| Keys | Action |
|------|--------|
| `Mod` + `1`–`9` | Focus workspace 1–9 |
| `Mod` + `PgDn` / `Super` + `↓` | Focus workspace below |
| `Mod` + `PgUp` / `Super` + `↑` | Focus workspace above |
| `Mod` + `Shift` + `PgDn` / `U` | Move workspace down |
| `Mod` + `Shift` + `PgUp` / `I` | Move workspace up |
| `Ctrl` + `Shift` + `R` | Rename workspace |
| `Mod` + `Shift` + `1`–`9` | Move column to workspace 1–9 |

### Monitor Management
| Keys | Action |
|------|--------|
| `Mod` + `Ctrl` + `H/L` (or `←/→`) | Focus monitor left / right |
| `Mod` + `Ctrl` + `K/J` (or `Super` + `Ctrl` + `↑/↓`) | Focus monitor up / down |
| `Mod` + `Shift` + `Ctrl` + `H/L/K/J` | Move column to monitor left/right/up/down |
| `Mod` + `Shift` + `P` | Power off all monitors |

### Column & Window Management
| Keys | Action |
|------|--------|
| `Mod` + `H/L` | Focus column left/right |
| `Mod` + `Shift` + `H/L` | Move column left/right |
| `Mod` + `C` | Center column |
| `Mod` + `F` | Maximize column |
| `Mod` + `W` | Toggle column tabbed display |
| `Mod` + `K/J` | Focus window up/down |
| `Mod` + `Q` | Close window |
| `Mod` + `Shift` + `F` | Fullscreen window |
| `Mod` + `Shift` + `T` | Toggle floating |

### Screenshots & Misc
| Keys | Action |
|------|--------|
| `Print` | Screenshot (region select) |
| `Ctrl` + `Print` | Screenshot whole screen |
| `Alt` + `Print` | Screenshot focused window |
| `Mod` + `Tab` / `Super` + `O` | Toggle overview |
| `Mod` + `Shift` + `?` | Show hotkey overlay |
| `Mod` + `Esc` | Toggle keyboard shortcuts inhibit |
| `Mod` + `Shift` + `E` | Quit / exit WM |

---

## 2. Dolphin Context Menu Shortcuts

Every custom right-click option requires a `.desktop` file placed in `~/.local/share/kio/servicemenus/`.

### The Universal Blueprint
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

### Scenario A: Standard GUI Editors (VS Code, Zed, Sublime)
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

### Scenario B: Terminal-Based Editors (Neovim, Micro, Helix)
You must tell the `Exec` line to launch your Terminal Emulator first:
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
*(If you use a different terminal, like Alacritty: `Exec=alacritty --working-directory "%f" -e nvim .`)*

### The Final Activation Steps
1. Make the file executable: `chmod +x ~/.local/share/kio/servicemenus/your-file-name.desktop`
2. Restart the file manager: `killall dolphin`

---

## 3. The Ultimate Alias Guide (Bash & Fish)

### Conda Environment Aliases (Fish)
Stacking lets you activate a new Conda environment on top of the current one instead of replacing it. Add these abbreviations to `~/.config/fish/config.fish`:
```fish
abbr -a cstack "conda activate --stack"
abbr -a cdeact "conda deactivate"
abbr -a clist  "conda env list"
abbr -a cact   "conda activate"
```

### Safety Aliases (Bash)
```bash
alias cp='cp -i'
alias mv='mv -i'
alias rm='rm -i'
```

### System & Pacman
```bash
alias update='sudo pacman -Syu'
alias install='sudo pacman -S'
alias remove='sudo pacman -Rns'
alias search='pacman -Ss'
alias orphans='sudo pacman -Rns $(pacman -Qdtq)'
```

### General Shortcuts
```bash
alias ll='ls -la'
alias la='ls -A'
alias df='df -h'
alias free='free -h'
alias ports='ss -tuln'
```

### Managing Aliases
| Task | Bash | Fish |
|---|---|---|
| Check what an alias does | `alias name` | `alias name` |
| Remove an alias (session) | `unalias name` | `functions -e name` |
| Reload config | `source ~/.bashrc` | `source ~/.config/fish/config.fish` |
