# MESA 26.04.1 and SDK 26.3.2 Installation Guide

This is the definitive, start-to-finish master guide for perfectly configuring the MESA SDK and installing the MESA source code on CachyOS. This guide incorporates every optimization, Wayland dependency, Conda isolation rule, and folder-structure fix required for a seamless installation.

## System Prerequisites

CachyOS uses `zlib-ng-compat` for performance, which conflicts with standard `zlib`. We will omit `zlib` to preserve your system optimizations, while installing Xwayland to ensure MESA's legacy graphics render properly inside Niri.

Open your standard Fish terminal and run:

```fish
sudo pacman -Syu binutils make perl libx11 tcsh glibc xorg-xwayland
```

## Phase 1: Download and Extract the MESA SDK 26.3.2

The SDK must be extracted and precisely named `~/mesasdk` for the initialization scripts to locate the custom compilers.

**1. Download and Extract:**
Navigate to the folder where you downloaded `mesasdk-x86_64-linux-26.3.2.tar.gz` (e.g., your Downloads folder) and extract it into your home directory:

```fish
tar xvfz mesasdk-x86_64-linux-26.3.2.tar.gz -C ~/
```

**2. Rename the folder:**

```fish
mv ~/mesasdk-26.3.2 ~/mesasdk
```

## Phase 2: Download and Extract MESA 26.04.1

Fetch the massive astrophysics suite containing all the required stellar data.

**1. Download the full package from Zenodo:**
Run this exact command to pull the version and ensure it saves as a clean zip file:

```bash
cd ~
wget "https://zenodo.org/records/19722306/files/mesa-26.04.1.zip?download=1" -O mesa-26.04.1.zip
```

**2. Extract the archive:**
*(If your system says `unzip: command not found`, open a normal Fish terminal, run `sudo pacman -S unzip`, and come back).*

```bash
unzip mesa-26.04.1.zip
# This extracts the contents to ~/mesa-26.04.1
```

## Phase 3: Configure Multi-Version Environment Loading (Aliases)

To prevent MESA's Fortran compilers from clashing with your Conda/Miniforge environments, and to allow seamlessly switching between MESA versions, we will create a dedicated Bash configuration file and alias.

**1. Create the MESA 26 Configuration File:**

```fish
nano ~/.bashrc_mesa_26
```

Paste this exact content:

```bash
# Ensure the shell is interactive
[[ $- != *i* ]] && return

# Prevent Conda from clashing
export CONDA_AUTO_ACTIVATE_BASE=false

# Load standard bashrc
if [ -f ~/.bashrc ]; then
    source ~/.bashrc
fi

export OMP_NUM_THREADS=16

# Initialize MESA SDK 26
export MESASDK_ROOT=~/mesasdk
source $MESASDK_ROOT/bin/mesasdk_init.sh

# Initialize MESA 26 Directory
export MESA_DIR=~/mesa-26.04.1
export PATH=$PATH:$MESA_DIR/scripts/shmesa

# Custom Prompt
export PS1="[MESA 26] [\u@\h \W]\$ "
```

Save and exit (`Ctrl+O`, `Enter`, `Ctrl+X`).

**2. Add the Alias to Fish:**
Open your Fish config:

```fish
nano ~/.config/fish/config.fish
```

Add this alias to the bottom of the file:

```fish
alias mesa26="bash --rcfile ~/.bashrc_mesa_26"
```

Save, exit, and reload the terminal (or run `source ~/.config/fish/config.fish`).

## Phase 4: Verify the SDK Configuration

Run these steps one by one to ensure your custom toolkit is airtight before compiling the source code.

**1. Launch the Isolated Environment**
From your standard Fish terminal, type your new alias:

```fish
mesa26
```

*(You should see the three `mesasdk_init.sh` initialization lines, followed immediately by your prompt changing to `[MESA 26] [void@void-pc ~]$ `. You should not see a massive Conda Python traceback).*

**2. Verify the Compiler Version**

```bash
gfortran --version
```

*(The first line must read exactly: **`GNU Fortran (GCC) 15.2.0`**).*

**3. Verify the Executable Path**

```bash
which gfortran
```

*(The output should be exactly `/home/void/mesasdk/bin/gfortran`).*

**4. The Ultimate Test: Compile a Fortran Script**
Write a tiny script to ensure the linker and compiler are working natively:

```bash
echo "print *, 'The MESA SDK compiler is working' ; end" > test.f90
gfortran test.f90 -o test_run
./test_run
```

*(You can completely ignore any warning from the linker about `.sframe`. The terminal will proudly output `The MESA SDK compiler is working`).*

## Phase 5: Compile MESA 26.04.1

With the environment fully configured and the source code extracted, it is time to build the physics libraries.

**1. Launch your MESA 26 environment:**

```fish
mesa26
```

**2. Navigate to the MESA directory:**

```bash
cd $MESA_DIR
```

**3. Start the compiler:**

```bash
./install
```

The script will now sequentially build the math, physics, equation-of-state (EOS), and opacity libraries. Let it run until the terminal displays the massive `MESA installation was successful` banner.
