Here is the definitive, start-to-finish master guide for perfectly configuring the MESA SDK and installing the MESA source code. This guide incorporates every optimization, Wayland dependency, Conda isolation rule, and folder-structure fix required for a seamless installation.

### Phase 1: Install System Prerequisites

CachyOS uses `zlib-ng-compat` for performance, which conflicts with standard `zlib`. We will omit `zlib` to preserve your system optimizations, while installing Xwayland to ensure MESA's legacy graphics render properly inside Niri.

Open your standard Fish terminal and run:

```fish
sudo pacman -Syu binutils make perl libx11 tcsh glibc xorg-xwayland

```

### Phase 2: Extract and Structure the SDK

The SDK must be extracted and precisely named `~/mesasdk` for the initialization scripts to locate the custom compilers.

1. Navigate to the folder where you downloaded `mesasdk-x86_64-linux-26.3.2.tar.gz` (e.g., your Downloads folder).
2. Extract the archive into your home directory:
```fish
tar xvfz mesasdk-x86_64-linux-26.3.2.tar.gz -C ~/

```


3. Rename the resulting folder to exactly match what the environment expects:
```fish
mv ~/mesasdk-26.3.2 ~/mesasdk

```



### Phase 3: Create the Isolated MESA Environment

To prevent MESA's Fortran compilers from clashing with your Conda/Miniforge environments, create a dedicated Bash configuration file that safely puts Conda to sleep before loading MESA.

1. Create and open the file:
```fish
nano ~/.bashrc_mesa

```


2. Paste this exact configuration inside:
```bash
# Ensure the shell is interactive
[[ $- != *i* ]] && return

# 1. Prevent Conda from clashing with MESA's compilers
export CONDA_AUTO_ACTIVATE_BASE=false

# 2. Load your standard bashrc (aliases, TERM settings)
if [ -f ~/.bashrc ]; then
    source ~/.bashrc
fi

# 3. Initialize MESA SDK (Takes priority in $PATH)
export MESASDK_ROOT=~/mesasdk
source $MESASDK_ROOT/bin/mesasdk_init.sh

# 4. Custom Prompt to indicate the environment is active
PS1="[MESA] [\u@\h \W]\$ "

```


3. Save and exit (`Ctrl+O`, `Enter`, `Ctrl+X`).

### Phase 4: Create the Fish Launcher

Add an alias to your Fish configuration so you can launch this isolated environment with a single command.

1. Open your Fish config:
```fish
nano ~/.config/fish/config.fish

```


2. Add this alias to the bottom of the file:
```fish
alias mesa="bash --rcfile ~/.bashrc_mesa"

```


3. Save, exit, and reload the terminal (or run `source ~/.config/fish/config.fish`).

Here is the updated, foolproof verification guide tailored specifically for your CachyOS + Fish setup. This incorporates the Conda isolation fixes, the exact paths for your `void` user account, and bypasses the Bash history expansion quirk we ran into earlier.

Run these steps one by one to ensure your custom toolkit is airtight before moving on to the actual MESA source code.

### Phase 5: Verify the SDK Configuration

**1. Launch the Isolated Environment**
From your standard Fish terminal, type your new alias:

```fish
mesa

```

* **What to expect:** You should see the three `mesasdk_init.sh` initialization lines, followed immediately by your prompt changing to `[MESA] [void@void-pc ~]$ `. You should *not* see a massive Conda Python traceback.

**2. Verify the Compiler Version**
Check that the highly optimized MESA compiler is active:

```bash
gfortran --version

```

* **What to expect:** The very first line must read exactly: **`GNU Fortran (GCC) 15.2.0`**.

**3. Verify the Executable Path**
Confirm the system is pulling the compiler directly from your new SDK folder and not the Arch/CachyOS system directories:

```bash
which gfortran

```

* **What to expect:** The output should be exactly `/home/void/mesasdk/bin/gfortran`.

**4. Verify SDK Environment Variables**
Check that the root directory variable was exported correctly:

```bash
echo $MESASDK_ROOT

```

* **What to expect:** The output should be exactly `/home/void/mesasdk`.

**5. The Ultimate Test: Compile a Fortran Script**
Let's write a tiny script to ensure the linker and compiler are working natively. Run this command to generate the file (notice we removed the exclamation mark `!` to prevent Bash from panicking):

```bash
echo "print *, 'The MESA SDK compiler is working' ; end" > test.f90

```

Now, compile it using your new SDK:

```bash
gfortran test.f90 -o test_run

```

* **What to expect:** You will likely see a warning from the linker that looks like `/ld: error in /lib/../lib64/crt1.o(.sframe); no .sframe will be created`. **You can completely ignore this.** It is just MESA's stable linker telling you it doesn't recognize CachyOS's bleeding-edge stack-tracing format. It has zero impact on performance or physics.

Execute the compiled program:

```bash
./test_run

```

* **What to expect:** The terminal will proudly output `The MESA SDK compiler is working`.

If all of these checks pass exactly as described, your MESA SDK is flawlessly configured, fully isolated from Conda, and ready to compile stellar evolution models!

