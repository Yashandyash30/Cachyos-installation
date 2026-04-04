# Miniforge Installation & Setup Guide (Arch/CachyOS)

> This guide installs Miniforge entirely in user space, providing both `conda` and the faster `mamba` solver, correctly initialized for both Bash and Fish shells.

---

## Phase 1: Installation

```bash
# Download the installer
wget "https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh"

# Run the installer
bash Miniforge3-Linux-x86_64.sh
```

Navigate the prompts:

- Press `Enter` to read the license, or `q` to skip
- Type `yes` to accept
- Press `Enter` to accept the default install path (`~/miniforge3`)
- When asked **"Do you wish the installer to initialize Miniforge3?"** — type `yes`

---

## Phase 2: Shell Initialization

Initialization injects a small script into your shell config so your terminal recognizes `mamba` and `conda` commands.

### Bash

```bash
~/miniforge3/bin/conda init bash
```

Close and reopen your terminal. You should see `(base)` in your prompt.

---

### Fish (Required — Fish is not initialized automatically)

Run this from inside a bash session:

```bash
bash
conda init fish
exit
```

Reload the Fish config:

```fish
source ~/.config/fish/config.fish
```

If `mamba activate <env>` still throws an error, run this extra step:

```fish
mamba shell init --shell fish --root-prefix /home/void/miniforge3
source ~/.config/fish/config.fish
```

You should now see `(base)` in your Fish prompt and both `conda` and `mamba` will work directly without switching to bash.

---

## Phase 3: Channel Priority (Critical)

Astrophysics software mixes Python wrappers with heavy C and Fortran binaries. Mixing packages from `defaults` and `conda-forge` channels breaks environments. This step enforces strict priority so mamba always pulls from conda-forge.

```bash
# Set conda-forge as top priority channel
conda config --add channels conda-forge

# Enforce strict priority
conda config --set channel_priority strict
```

Verify it worked:

```bash
conda config --show channel_priority
# Expected output: channel_priority: strict
```

> **Why strict matters:** If a package exists in both `defaults` and `conda-forge`, strict priority forces mamba to always use the `conda-forge` version — preventing ABI mismatches when building astronomy tools.

---

## Phase 4: Daily Workflow

> Because `conda-forge` is now your strict default, you no longer need to type `-c conda-forge` in every command.

| Task | Command |
|---|---|
| Create a new environment | `mamba create -n my_env python=3.11 numpy scipy astropy` |
| Activate an environment | `mamba activate my_env` |
| Deactivate (return to base) | `mamba deactivate` |
| List all environments | `mamba env list` |
| Delete a broken environment | `mamba env remove -n my_env` |

---

## Fix: "terminals database is inaccessible" Warning

This harmless warning appears when bash is launched inside a Fish session and can't resolve the terminfo database correctly. It does not affect conda or any science tools — just an annoyance.

### Bash (Permanent Fix)

```bash
echo 'export TERM=xterm-256color' >> ~/.bashrc
source ~/.bashrc
```

### Fish (Permanent Fix)

```fish
echo 'set -x TERM xterm-256color' >> ~/.config/fish/config.fish
source ~/.config/fish/config.fish
```

---

## Troubleshooting

| Error | Fix |
|---|---|
| `conda: command not found` in bash | Run `~/miniforge3/bin/conda init bash` then reopen terminal |
| `mamba: command not found` in fish | Run `conda init fish` from bash, then `source ~/.config/fish/config.fish` |
| `mamba activate` fails in fish | Run `mamba shell init --shell fish --root-prefix /home/void/miniforge3` then `source ~/.config/fish/config.fish` |
| `(base)` not showing in prompt | Close terminal completely and reopen — do not just run `source` |
| Two conda installs conflicting | Run `which mamba` — if it points to `miniconda3`, remove it: `rm -rf ~/miniconda3` |
| `terminals database is inaccessible` | Apply the TERM fix above for your shell |
