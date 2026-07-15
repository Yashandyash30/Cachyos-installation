Here is a complete guide you can save for the future. 

### Why this happens on Arch Linux (and newer Ubuntu/Debian)
Modern Linux distributions block you from running `pip install <package>` globally. This is an intentional security feature (called "Externally Managed Environment") designed to prevent `pip` from accidentally breaking critical system packages that rely on Python. 

Because of this, you have to use **Virtual Environments** for everything. Below are the two exact methods I used today to give you global tools while still respecting the OS rules.

---

### 1. How to install global CLI tools (like `jupytext`)
When you want a command-line tool to be available in every directory, the best approach is to install it in its own isolated virtual environment and link it to a folder that is in your system's `PATH` (like `~/.local/bin`).

**Option A: The manual way (What I did)**
```bash
# 1. Ensure your local binary folder exists
mkdir -p ~/.local/bin

# 2. Create a dedicated virtual environment for the tool
python3 -m venv ~/.local/jupytext_env

# 3. Install the tool into that environment
~/.local/jupytext_env/bin/pip install jupytext

# 4. Create a shortcut (symlink) in your PATH so you can run it anywhere
ln -sf ~/.local/jupytext_env/bin/jupytext ~/.local/bin/jupytext
```

**Option B: The automatic way (Using `pipx`)**
Instead of doing it manually, you can use `pipx`, which automates the exact steps above.
```bash
# 1. Install pipx via your system package manager
sudo pacman -S python-pipx

# 2. Use pipx to install tools globally
pipx install jupytext
```

---

### 2. How to create a Global Jupyter Kernel
When VS Code asks you to install `ipykernel`, it tries to install it into your *current* virtual environment. If you want a "Global" kernel that you can use across multiple different projects without reinstalling your favorite data science packages, do this:

```bash
# 1. Create a dedicated virtual environment just for your global Jupyter kernel
python3 -m venv ~/.local/global_jupyter_env

# 2. Install ipykernel and any packages you use frequently (numpy, pandas, etc.)
~/.local/global_jupyter_env/bin/pip install ipykernel numpy astropy pandas matplotlib

# 3. Register this environment as a Jupyter kernel for your user profile
~/.local/global_jupyter_env/bin/python -m ipykernel install --user --name "global_data_science" --display-name "Global Python (Data Science)"
```

**How to use it:**
Once registered, this kernel will permanently show up in your editor's **"Change Kernel" -> "Jupyter Kernel"** menu, no matter what folder or project you are currently working in!

*(Tip: If you ever need to add a new package to this global kernel later, just run: `~/.local/global_jupyter_env/bin/pip install <package_name>`)*
