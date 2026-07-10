# The Ultimate Alias Guide for CachyOS (Bash & Fish)

---

## Bash Aliases

### Setup

All Bash aliases live in `~/.bashrc`. Open it:

```bash
nano ~/.bashrc
```

Add aliases at the bottom using this syntax:

```bash
alias name='command'
```

After saving, apply changes to your current session:

```bash
source ~/.bashrc
```

### Syntax Rules

```bash
# No spaces around the = sign
alias ll='ls -la'          # correct
alias ll = 'ls -la'        # wrong — breaks

# Use single quotes to prevent early expansion
alias now='date +"%T"'

# Use double quotes if you need variables to expand at definition time
alias mydir="cd $HOME/projects"
```

---

## Fish Aliases

Fish gives you two methods. They behave differently — pick the one that fits your use case.

### Method A — Config File (Persistent, works like Bash)

Open your Fish config:

```bash
nano ~/.config/fish/config.fish
```

Add aliases using this syntax:

```fish
alias name="command"
```

Apply immediately without restarting:

```bash
source ~/.config/fish/config.fish
```

### Method B — The Fish Way (Interactive + Saved as a Function)

Run the alias directly in your terminal, then save it:

```fish
alias update "sudo pacman -Syu"
funcsave update
```

This saves it to `~/.config/fish/functions/update.fish` and loads it automatically on every session — no config file editing needed.

### Method C — Abbreviations (Recommended for Fish)

Abbreviations (`abbr`) are unique to Fish. Instead of silently running a shortcut, they expand into the full command when you press **Space** or **Enter**, so you always see exactly what's about to run.

Add to `~/.config/fish/config.fish`:

```fish
abbr -a name "full command"
```

| Feature | `alias` | `abbr` |
|---|---|---|
| Expands visibly in terminal | No | Yes |
| Works in scripts | Yes | No |
| Good for long commands you want to review | No | Yes |
| Good for short utility shortcuts | Yes | Yes |

---

## Conda Environment Aliases

Stacking lets you activate a new Conda environment on top of the current one instead of replacing it, by combining their `PATH` entries.

```bash
conda activate --stack <env_name>
```

### In Bash (`~/.bashrc`)

```bash
# Activate a new env on top of the current one
alias cstack='conda activate --stack'

# Shortcut to deactivate one level
alias cdeact='conda deactivate'

# List all available environments
alias clist='conda env list'

# Activate a specific env from scratch (replace current)
alias cact='conda activate'
```

Usage:

```bash
cstack my_analysis_env
cstack gpu_tools          # stack a second env on top
cdeact                    # pop one level
```

### In Fish (`~/.config/fish/config.fish`)

```fish
alias cstack "conda activate --stack"
alias cdeact "conda deactivate"
alias clist  "conda env list"
alias cact   "conda activate"
```

Or as abbreviations (recommended — you'll see the full command before it runs):

```fish
abbr -a cstack "conda activate --stack"
abbr -a cdeact "conda deactivate"
abbr -a clist  "conda env list"
abbr -a cact   "conda activate"
```

---

## Useful Alias Patterns

### Safety Aliases

```bash
# Ask for confirmation before overwriting or deleting
alias cp='cp -i'
alias mv='mv -i'
alias rm='rm -i'
```

### Navigation

```bash
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias proj='cd ~/projects'
```

### System (CachyOS / Arch)

```bash
alias update='sudo pacman -Syu'
alias install='sudo pacman -S'
alias remove='sudo pacman -Rns'
alias search='pacman -Ss'
alias orphans='sudo pacman -Rns $(pacman -Qdtq)'  # remove unused packages
```

### Shortcuts

```bash
alias ll='ls -la'
alias la='ls -A'
alias grep='grep --color=auto'
alias df='df -h'           # human-readable disk usage
alias free='free -h'       # human-readable RAM usage
alias ports='ss -tuln'     # show open ports
```

---

## Managing Aliases

| Task | Bash | Fish |
|---|---|---|
| List all active aliases | `alias` | `alias` |
| Check what an alias does | `alias name` | `alias name` |
| Remove an alias (current session) | `unalias name` | `functions -e name` |
| Remove permanently | Delete the line from `~/.bashrc` | `rm ~/.config/fish/functions/name.fish` |
| Reload config | `source ~/.bashrc` | `source ~/.config/fish/config.fish` |

---

## Quick Reference

```
~/.bashrc                          → Bash aliases
~/.config/fish/config.fish         → Fish aliases (Method A)
~/.config/fish/functions/          → Fish saved functions (Method B)
```
