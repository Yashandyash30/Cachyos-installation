Here is the dedicated guide to strictly install and configure the MESA source code, picking up exactly where your verified SDK setup left off.

### Step 1: Add MESA Variables to Your Environment

Since your `~/.bashrc_mesa` file is currently only configured for the SDK, we need to add the specific variables for the MESA source code.

**1. Open your isolated configuration file:**

```fish
nano ~/.bashrc_mesa

```

**2. Add these three lines to the very bottom of the file:**

```bash
# Define MESA Source Directory
export MESA_DIR=~/mesa-26.04.1

# Set Thread Count for your CPU (Change '4' to your actual physical core count)
export OMP_NUM_THREADS=4

# Add shmesa tools to your PATH
export PATH=$PATH:$MESA_DIR/scripts/shmesa

```

**3. Save and exit** (`Ctrl+O`, `Enter`, `Ctrl+X`).

---

### Step 2: Download and Extract MESA 26.04.1

Now, fetch the massive 2.3 GB astrophysics suite containing all the required stellar data.

**1. Launch your clean MESA terminal:**
From your standard Fish shell, activate the environment so Conda is isolated and the SDK is live.

```fish
mesa

```

**2. Download the full package from Zenodo:**
Run this exact command to pull the version you found, ensuring it saves as a clean zip file:

```bash
cd ~
wget "https://zenodo.org/records/19722306/files/mesa-26.04.1.zip?download=1" -O mesa-26.04.1.zip

```

**3. Extract the archive:**
*(If your system says `unzip: command not found`, open a normal Fish terminal, run `sudo pacman -S unzip`, and come back).*

```bash
unzip mesa-26.04.1.zip

```

---

### Step 3: Compile the Code

With the environment fully configured and the source code extracted, it is time to build the physics libraries.

**1. Reload the environment so the new paths take effect:**

```bash
source ~/.bashrc_mesa

```

**2. Navigate to the new directory:**

```bash
cd $MESA_DIR

```

**3. Start the compiler:**

```bash
./install

```

The script will now sequentially build the math, physics, equation-of-state (EOS), and opacity libraries. Let it run until the terminal displays the massive `MESA installation was successful` banner.
