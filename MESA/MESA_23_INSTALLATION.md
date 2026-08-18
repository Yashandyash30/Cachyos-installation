# MESA r23.05.1 and SDK 23.7.3 Installation Guide

This guide covers how to install an older version of MESA (r23.05.1) and its corresponding SDK (23.7.3) side-by-side with your existing MESA 26 installation, without causing any conflicts.

## Phase 1: Download and Extract the MESA SDK 23.7.3

MESA r23.05.1 requires the older MESA SDK 23.7.3 to compile successfully. We will install it in a uniquely named folder.

**1. Download the SDK:**
Go to the official MESA SDK website and download the Linux x86_64 tarball for version 23.7.3 (`mesasdk-x86_64-linux-23.7.3.tar.gz`).

**2. Extract and rename the SDK:**

```bash
# Extract the archive into your home directory
tar xvfz mesasdk-x86_64-linux-23.7.3.tar.gz -C ~/

# Rename the folder so it doesn't conflict with your current ~/mesasdk folder
mv ~/mesasdk ~/mesasdk-23.7.3
```

## Phase 2: Download and Extract MESA r23.05.1

**1. Download the Source Code:**
Download the `mesa-r23.05.1.zip` release file (usually from Zenodo or the official MESA archives).

**2. Extract to a versioned folder:**

```bash
cd ~
unzip mesa-r23.05.1.zip
# This should extract the contents into a folder named ~/mesa-r23.05.1
```

## Phase 3: Configure Multi-Version Environment Loading (Aliases)

To switch seamlessly by simply typing `mesa26` or `mesa23`, we need to split your single `~/.bashrc_mesa` file into two separate configuration files, one for each version.

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

Save and exit.

**2. Create the MESA 23 Configuration File:**

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

**3. Add the Aliases to Fish:**
Open your Fish configuration file:

```fish
nano ~/.config/fish/config.fish
```

Remove the old `alias mesa="bash --rcfile ~/.bashrc_mesa"` if you wish, and add these two lines at the bottom:

```fish
alias mesa26="bash --rcfile ~/.bashrc_mesa_26"
alias mesa23="bash --rcfile ~/.bashrc_mesa_23"
```

Save and exit. Then reload your terminal by running `source ~/.config/fish/config.fish`.

## Phase 4: Compile MESA r23.05.1

Now that your environments are completely separated and aliased, you can compile the older source code.

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

Let the compilation run to completion. From now on, whenever you want to work on a project, just type `mesa26` or `mesa23` to enter the respective tailored environment!
