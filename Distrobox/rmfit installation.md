# rmfit Installation Guide (Arch/CachyOS)

> rmfit is an IDL 8.1 runtime binary that depends on libraries no longer available on modern Linux. This guide uses a surgical extraction method inside a Distrobox Ubuntu container to keep your host system clean.

---

## Prerequisites

- Distrobox installed and configured on CachyOS
- An Ubuntu container running (referred to as `ubuntu` throughout)
- See BoxBuddy installation steps for GUI-based container management

---

## Phase 1: Download and Extract rmfit (On Host)

```bash
# Create your program directory
mkdir -p ~/Downloads/Programmes
cd ~/Downloads/Programmes

# Download the Linux 64-bit tarball
wget https://fermi.gsfc.nasa.gov/ssc/data/analysis/rmfit/rmfit_v432_linux64.tar.gz

# If the above fails, use this mirror URL instead
# https://fermi.gsfc.nasa.gov/ssc/data/p7rep/analysis/rmfit/rmfit_v432_64bit.tar.gz

# Extract the archive
tar -zxvf rmfit_v432_64bit.tar.gz
```

---

## Phase 2: Enter the Distrobox Container

```bash
distrobox enter ubuntu
```

Once inside, install the base dependencies:

```bash
sudo apt update
sudo apt install libxpm4 libncurses5 libtinfo5 libx11-6 libxext6 libxtst6 libxaw7
```

---

## Phase 3: The libXp Surgery

`libXp.so.6` cannot be installed via apt due to the missing multiarch-support package. Extract it manually.

> All commands below must be run **inside the Distrobox container**.

```bash
# 1. Move to a temporary folder
cd /tmp

# 2. Download the archived Debian package
wget http://archive.debian.org/debian/pool/main/libx/libxp/libxp6_1.0.2-2_amd64.deb

# 3. Unpack without installing
dpkg -x libxp6_1.0.2-2_amd64.deb libxp_temp

# 4. Copy the shared objects into the system library folder
sudo cp -d libxp_temp/usr/lib/x86_64-linux-gnu/libXp.so.6* /usr/lib/x86_64-linux-gnu/

# 5. Rescan system libraries
sudo ldconfig

# 6. Clean up
rm -rf libxp_temp libxp6_1.0.2-2_amd64.deb
```

---

## Phase 4: Mathematical Library Linking (GSL)

Modern Ubuntu uses a newer GSL version than rmfit expects. Link them manually inside the container.

```bash
# 1. Install modern GSL packages
sudo apt update
sudo apt install libgsl-dev libgslcblas0

# 2. Create compatibility links for the legacy names
cd /usr/lib/x86_64-linux-gnu/
sudo ln -s libgsl.so.27 libgsl.so.0
sudo ln -s libgslcblas.so.0.0.0 libgslcblas.so.0

# 3. Update the library cache
sudo ldconfig
```

---

## Phase 5: The Legacy Fortran Fix (libgfortran3)

> ⚠️ **Do not symlink libgfortran3 to a modern version.** Fortran ABI changes between versions cause silent numerical errors in spectral fitting, not just crashes. Always extract the exact version below.

```bash
sudo apt install libquadmath0
cd /tmp

wget http://archive.ubuntu.com/ubuntu/pool/universe/g/gcc-6/libgfortran3_6.4.0-17ubuntu1_amd64.deb
dpkg -x libgfortran3_6.4.0-17ubuntu1_amd64.deb libgfortran_temp

sudo cp libgfortran_temp/usr/lib/x86_64-linux-gnu/libgfortran.so.3.0.0 /usr/lib/x86_64-linux-gnu/

cd /usr/lib/x86_64-linux-gnu/
sudo ln -sf libgfortran.so.3.0.0 libgfortran.so.3
sudo ldconfig

rm -rf /tmp/libgfortran_temp /tmp/libgfortran3_6.4.0-17ubuntu1_amd64.deb
```

---

## Phase 6: Create Launch Shortcuts

### Inside the Container (Bash)

```bash
echo 'alias rmfit="cd ~/Downloads/Programmes/rmfit_v432 && export IDL_DIR=\$PWD/idl81 && ./idl81/bin/idl -rt=rmfit.sav"' >> ~/.bashrc
```

### Inside the Container (Fish)

```bash
alias rmfit="cd ~/Downloads/Programmes/rmfit_v432; and set -x IDL_DIR \$PWD/idl81; and ./idl81/bin/idl -rt=rmfit.sav"
funcsave rmfit
```

### From the CachyOS Host (Fish — Recommended)

Type `rmfit` directly from your host terminal and have it automatically enter the container, set variables, and launch the GUI:

```bash
function rmfit
    distrobox enter ubuntu -- bash -c "cd ~/Downloads/Programmes/rmfit_v432 && export IDL_DIR=\$PWD/idl81 && ./idl81/bin/idl -rt=rmfit.sav"
end

funcsave rmfit
```

---

## Troubleshooting

| Error | Fix |
|---|---|
| `libXpm.so.4: cannot open shared object file` | Run `sudo apt install libxpm4 libncurses5 libtinfo5 libx11-6 libxext6 libxtst6 libxaw7` inside the container |
| `libtinfo.so.5` or `libncurses.so.5` errors | Run `sudo apt install libncurses5 libtinfo5` inside the container |

---

## Why Distrobox Is Required for rmfit

Unlike the other tools in this stack, rmfit has no conda package, no PyPI package, and no clean installation path. It is an IDL 8.1 runtime binary from 2013 that depends on libraries removed from all modern Linux systems:

| Library | Status |
|---|---|
| `libXp.so.6` | Removed from all modern distros |
| `libgfortran.so.3` | GCC 6 era Fortran ABI |
| `libgsl.so.0` | Ancient GSL ABI |

These cannot be solved with conda, mamba, or any environment manager. The Distrobox Ubuntu container is the only clean solution.
