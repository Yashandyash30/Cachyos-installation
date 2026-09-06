# MESA r23.05.1 and SDK 23.7.3 Installation Guide

This guide covers how to specifically install the legacy version of MESA (r23.05.1) and its corresponding SDK (23.7.3) without causing any conflicts with your system or existing MESA installations.

## Phase 1: Download, Extract, and Fix the MESA SDK 23.7.3

MESA r23.05.1 requires the older MESA SDK 23.7.3 to compile successfully. We will install it in a uniquely named folder.

**1. Download the SDK:**
Download the Linux x86_64 tarball for version 23.7.3 directly via `curl`:
```bash
curl -C - -L -O "http://user.astro.wisc.edu/~townsend/resource/download/mesasdk/mesasdk-x86_64-linux-23.7.3.tar.gz"
```
*(If downloading on your local PC/Laptop to transfer to the server, use the `transfer` command: `transfer surya mesasdk-x86_64-linux-23.7.3.tar.gz`)*

**2. Extract and rename the SDK:**
```bash
# Extract the archive into your home directory
tar xvfz mesasdk-x86_64-linux-23.7.3.tar.gz -C ~/

# Rename the folder so it doesn't conflict with any other SDK folder
mv ~/mesasdk ~/mesasdk-23.7.3
```

**3. Apply the System Headers Fix:**
Due to conflicts with newer rolling-release distributions like CachyOS, the older SDK's bundled fixed-headers will cause compilation errors (`sys/cdefs.h` missing binary operator). We must disable them so the compiler falls back to your native system headers:
```bash
mv ~/mesasdk-23.7.3/lib/gcc/x86_64-pc-linux-gnu/13.1.0/include-fixed ~/mesasdk-23.7.3/lib/gcc/x86_64-pc-linux-gnu/13.1.0/include-fixed.bak
```

## Phase 2: Download and Extract MESA r23.05.1

**1. Download the Source Code:**
Download the `mesa-r23.05.1.zip` release file directly from Zenodo:
```bash
curl -C - -L -o mesa-r23.05.1.zip "https://zenodo.org/records/7983526/files/mesa-r23.05.1.zip"
```
*(If transferring from your PC/Laptop: `transfer surya mesa-r23.05.1.zip`)*

**2. Extract to a versioned folder:**
```bash
cd ~
unzip mesa-r23.05.1.zip
# This should extract the contents into a folder named ~/mesa-r23.05.1
```

## Phase 3: Configure Environment Loading

To launch the MESA 23 environment cleanly, we will create a dedicated Bash configuration file and alias for it.

**1. Create the MESA 23 Configuration File:**
```fish
nano ~/.bashrc_mesa_23
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

# Initialize MESA SDK 23
export MESASDK_ROOT=~/mesasdk-23.7.3
source $MESASDK_ROOT/bin/mesasdk_init.sh

# Initialize MESA 23 Directory
export MESA_DIR=~/mesa-r23.05.1
export PATH=$PATH:$MESA_DIR/scripts/shmesa

# Custom Prompt
export PS1="[MESA 23] [\u@\h \W]\$ "
```
Save and exit.

**2. Add the Alias to Fish:**
Open your Fish configuration file:
```fish
nano ~/.config/fish/config.fish
```

Add this line at the bottom:
```fish
alias mesa23="bash --rcfile ~/.bashrc_mesa_23"
```
Save and exit. Then reload your terminal by running `source ~/.config/fish/config.fish`.

## Phase 4: Compile MESA r23.05.1

Now that your MESA 23 environment is completely set up and isolated, you can compile the older source code.

**1. Launch your MESA 23 environment directly from Fish:**
```fish
mesa23
```
*(Your prompt should immediately change to `[MESA 23]`).*

**2. Navigate to the MESA 23 source folder:**
```bash
cd $MESA_DIR
```

**3. Run the installer:**
```bash
./install
```

Let the compilation run to completion. *(Note: You may see a linker warning regarding `.sframe`, this is perfectly normal and safe to ignore).* 

From now on, whenever you want to work on a MESA 23 project, just type `mesa23` to enter your tailored legacy environment!
