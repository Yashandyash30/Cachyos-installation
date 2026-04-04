# rmfit Installation Guide for CachyOS

## Overview

Since modern Linux distributions have completely abandoned the 32-bit and outdated X11 libraries that IDL 8.1 relies on, this guide uses the "surgical extraction" method to keep your host system clean.

## Phase 1: Download and Extract rmfit

First, grab the software from the Fermi Science Support Center and put it in your preferred directory.

```bash
# Create your program directory if it doesn't exist
mkdir -p ~/Downloads/Programmes
cd ~/Downloads/Programmes

# Download the Linux 64-bit tarball
wget https://fermi.gsfc.nasa.gov/ssc/data/analysis/rmfit/rmfit_v432_linux64.tar.gz

# If it fails manually download from here
https://fermi.gsfc.nasa.gov/ssc/data/p7rep/analysis/rmfit/rmfit_v432_64bit.tar.gz


# Extract it (this creates the rmfit_v432 folder)
tar -zxvf rmfit_v432_64bit.tar.gz
```

## Phase 2: Enter the Distrobox Container
To install boxbuddy
See boxbuddy installation steps in this reopository.

To prevent these ancient dependencies from breaking your CachyOS host, do the actual installation inside an Ubuntu container (like your void container).

```bash
# Enter your Ubuntu Distrobox container
distrobox enter ubuntu
```

Once inside the container, install the basic dependencies that still exist in the modern Ubuntu repositories:

```bash
sudo apt update
sudo apt install libxpm4 libncurses5 libtinfo5 libx11-6 libxext6 libxtst6 libxaw7
```

## Phase 3: The libXp Surgery

The critical `libXp.so.6` library cannot be installed via apt anymore because of the missing multiarch-support package. You have to manually download the old Debian package, extract the library file, and drop it into the system.

Run these commands strictly inside your Distrobox container:

```bash
# 1. Move to a temporary folder
cd /tmp

# 2. Download the ancient Debian package
wget http://archive.debian.org/debian/pool/main/libx/libxp/libxp6_1.0.2-2_amd64.deb

# 3. Unpack the contents without installing
dpkg -x libxp6_1.0.2-2_amd64.deb libxp_temp

# 4. Copy the shared objects (.so files) into the system library folder
sudo cp -d libxp_temp/usr/lib/x86_64-linux-gnu/libXp.so.6* /usr/lib/x86_64-linux-gnu/

# 5. Tell the system to rescan the libraries
sudo ldconfig

# 6. Clean up the temp files
rm -rf libxp_temp libxp6_1.0.2-2_amd64.deb
```
## Phase 4: Mathematical Library Linking (GSL)

Even with the graphics libraries installed, rmfit will fail during spectral fitting if it cannot find the GNU Scientific Library. Since modern Ubuntu uses a newer version than what rmfit expects, we must link them manually.

Run these commands inside your container:
```bash
# 1. Install the modern GSL packages
sudo apt update
sudo apt install libgsl-dev libgslcblas0

# 2. Create compatibility links for the legacy names
cd /usr/lib/x86_64-linux-gnu/
sudo ln -s libgsl.so.27 libgsl.so.0
sudo ln -s libgslcblas.so.0.0.0 libgslcblas.so.0

# 3. Update the system library cache
sudo ldconfig
```

## Phase 5: Create the Launch Shortcuts

Because rmfit requires specific environment variables and directory locations, creating a shortcut is the only way to stay sane.

### Inside the Ubuntu Container (Bash)

If you are already inside the container and want to launch it:
For fish :
```bash
alias rmfit="cd ~/Downloads/Programmes/rmfit_v432; and set -x IDL_DIR \$PWD/idl81; and ./idl81/bin/idl -rt=rmfit.sav"
# Save the function permanently
funcsave rmfit
```
For bash:
```bash
echo 'alias rmfit="cd ~/Downloads/Programmes/rmfit_v432 && export IDL_DIR=\$PWD/idl81 && ./idl81/bin/idl -rt=rmfit.sav"' >> ~/.bashrc

```
Outside the Container (CachyOS Host / Fish Shell):
If you want to be able to type rmfit directly into your main host terminal and have it automatically wake up the container, set the variables, and launch the GUI, run this in your Fish shell:

```bash
function rmfit
    # Tells Distrobox to enter 'ubuntu', navigate to the folder, set the IDL path, and run the VM
    distrobox enter ubuntu -- bash -c "cd ~/Downloads/Programmes/rmfit_v432 && export IDL_DIR=\$PWD/idl81 && ./idl81/bin/idl -rt=rmfit.sav"
end

# Save the function permanently
funcsave rmfit
```
Note (Fix the libXpm.so.4 Error): If typing rmfit throws this error 
```bash
/home/void/Downloads/Programmes/rmfit_v432/idl81/bin/bin.linux.x86_64/idl: error while loading shared libraries: libXpm.so.4: cannot open shared object file: No such file or directory 
```
still doesnt work Run this again

```bash
sudo apt update
sudo apt install libxpm4 libncurses5 libtinfo5 libx11-6 libxext6 libxtst6 libxaw7
```

Troubleshooting Note: If the application ever throws an error about libtinfo.so.5 or libncurses.so.5 down the line, it just means you need to reinstall the compatibility layer inside the container: sudo apt install libncurses5 libtinfo5.
