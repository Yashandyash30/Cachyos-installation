Here is the complete, start-to-finish installation guide for running the standalone, 32-bit version of DAOPHOT II inside your modern workstation architecture.

This guide documents the exact pipeline used to securely run ancient legacy astrophysics binaries by utilizing a containerized Ubuntu 22.04 environment, preventing any conflicts with your host system.

### Prerequisites

* Your `astrobox` Distrobox container (Ubuntu 22.04) is already built and running.
* You have downloaded `dao2.zip`, `gcc-3.4-base_3.4.6-6ubuntu5_i386.deb`, and `libg2c0_3.4.6-6ubuntu5_i386.deb` into a folder on your host machine (e.g., `~/Pyraf_Files`).

---

### Step 1: Enter the Subsystem and Prepare Tools

Open your standard terminal and step into the isolated astrophysics environment. Ensure you are using a standard Bash shell, and install the necessary utility tools.

```bash
distrobox enter astrobox
bash
sudo apt update
sudo apt install nano unzip -y

```

### Step 2: Enable 32-bit Architecture Support

DAOPHOT II was compiled for 32-bit (`i386`) architecture. You must configure the Ubuntu container to accept 32-bit packages and install the foundational C libraries required to run older software.

```bash
sudo dpkg --add-architecture i386
sudo apt update
sudo apt install libc6:i386 libncurses5:i386 -y

```

### Step 3: Install Legacy Fortran Dependencies

Navigate across the container bridge to the folder on your host machine where you stored the ancient `.deb` files. Install them in this specific order to satisfy dependency requirements.

```bash
cd /run/host/home/void/Pyraf_Files
sudo dpkg -i gcc-3.4-base_3.4.6-6ubuntu5_i386.deb
sudo dpkg -i libg2c0_3.4.6-6ubuntu5_i386.deb

```

### Step 4: Extract and Organize DAOPHOT

Extract the `dao2.zip` file directly into the container's isolated home directory. Address the common "double folder" extraction issue, and ensure the operating system has permission to execute the binaries.

```bash
# Extract the zip file
unzip dao2.zip -d ~/dao2

# Move the binaries out of the nested folder to the correct path
mv ~/dao2/dao2/* ~/dao2/

# Remove the empty nested folder
rmdir ~/dao2/dao2

# Grant execution permissions to all binaries
chmod +x ~/dao2/*

```

### Step 5: Configure System Aliases

Tell the container where to find the execution commands by adding them to the environment's configuration file.

1. Open the configuration file:
```bash
nano ~/.bashrc

```


2. Scroll to the very bottom and paste these exact lines:
```text
# Daophot
alias daophot=~/dao2/daophot
alias allstar=~/dao2/allstar
alias daomatch=~/dao2/ndaomatch
alias daomaster=~/dao2/ndaomaster

```


3. Save the file (`Ctrl+O`, then `Enter`) and exit (`Ctrl+X`).
4. Reload the configuration to activate the aliases:
```bash
source ~/.bashrc

```



### Step 6: Initial Configuration and Execution

Launch the software to trigger the initial hardware configuration file generation.

```bash
daophot

```

When the `Value unacceptable --- please re-enter` warning appears, it is waiting for your default camera parameters. Enter placeholder values (or your actual FITS header values) pressing `Enter` after each:

* `READ NOISE (ADU; 1 frame) =` **`5`**
* `GAIN (electrons/ADU; 1 frame) =` **`1`**
* `LOW GOOD DATUM (in sigmas) =` **`5`**
* `HIGH GOOD DATUM (in ADU) =` **`60000`**
* `FWHM OF OBJECT (in pixels) =` **`3`**

Once the last number is entered, DAOPHOT will create a `daophot.opt` file to save these preferences and drop you at the main `Command:` prompt, ready for data reduction.
