#!/bin/bash

echo "========================================"
echo " Phase 4: Research Apps & Subsystems"
echo "========================================"
read -p "Proceed with setting up Distrobox, PyRAF, and Conda? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Skipping Phase 4."
    exit 0
fi

REPO_DIR="/home/void/Cachyos-installation"
BACKUP_DIR="$REPO_DIR/conda-backups"

# --- Distrobox Setup ---
echo -e "\n--- Distrobox Astrophysics Environment ---"
GPU=$(lspci | grep -i 'vga\|3d\|2d')
if echo "$GPU" | grep -iq 'nvidia'; then
    echo "NVIDIA GPU detected. You may need CDI/Nvidia-SMI support for Distrobox."
    CREATE_ARGS="--nvidia"
else
    echo "No NVIDIA GPU detected. Using clean CPU-only sandboxed Distrobox."
    CREATE_ARGS=""
fi

mkdir -p ~/.local/share/astro-container-home
if ! distrobox list | grep -q 'astrobox'; then
    echo "Creating 'astrobox' Ubuntu 22.04 container..."
    distrobox create $CREATE_ARGS --name astrobox --image ubuntu:22.04 --home ~/.local/share/astro-container-home
else
    echo "'astrobox' already exists."
fi

echo "Installing PyRAF, IRAF, and DAOPHOT II inside astrobox..."
distrobox enter astrobox -- bash -c "sudo dpkg --add-architecture i386 && \
    sudo apt update && \
    sudo apt install -y iraf iraf-dev xgterm python3-pyraf saods9 wget curl bzip2 git build-essential libc6:i386 libncurses5:i386 unzip nano && \
    cd /run/host/home/void/Cachyos-installation/Pyraf/Pyraf_Files && \
    sudo dpkg -i gcc-3.4-base_3.4.6-6ubuntu5_i386.deb && \
    sudo dpkg -i libg2c0_3.4.6-6ubuntu5_i386.deb && \
    unzip -o dao2.zip -d ~/dao2 && \
    if [ -d ~/dao2/dao2 ]; then \
        mv ~/dao2/dao2/* ~/dao2/; \
        rmdir ~/dao2/dao2; \
    fi && \
    chmod +x ~/dao2/*"

# Set up aliases inside the container's .bashrc
if ! grep -q "alias daophot" ~/.local/share/astro-container-home/.bashrc 2>/dev/null; then
    cat << 'EOF' >> ~/.local/share/astro-container-home/.bashrc

# Daophot
alias daophot=~/dao2/daophot
alias allstar=~/dao2/allstar
alias daomatch=~/dao2/ndaomatch
alias daomaster=~/dao2/ndaomaster
EOF
fi

# --- Conda Setup on Host ---
echo -e "\n--- Conda / Miniforge Setup ---"
if ! command -v mamba &> /dev/null; then
    echo "Miniforge not found. Installing..."
    wget -qO /tmp/Miniforge3.sh "https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh"
    bash /tmp/Miniforge3.sh -b -p "$HOME/miniforge3"
    "$HOME/miniforge3/bin/conda" init bash
    "$HOME/miniforge3/bin/conda" init fish
    export PATH="$HOME/miniforge3/bin:$PATH"
fi

# Ensure mamba is in path for the script
MAMBA_BIN="$HOME/miniforge3/bin/mamba"
CONDA_BIN="$HOME/miniforge3/bin/conda"

# --- Conda Environment Recovery ---
echo -e "\n--- Restoring Conda Environments ---"
if [ -d "$BACKUP_DIR" ]; then
    for portable_yml in "$BACKUP_DIR"/*_portable.yml; do
        if [ -f "$portable_yml" ]; then
            env_name=$(basename "$portable_yml" _portable.yml)
            echo -e "\n----------------------------------------"
            echo "📦 Restoring environment: $env_name"
            
            # Check if environment already exists
            if $MAMBA_BIN env list | awk '{print $1}' | grep -Fxq "$env_name"; then
                echo "Environment '$env_name' already exists. Skipping creation."
                ENV_SUCCESS=0
            else
                $MAMBA_BIN env create -f "$portable_yml" --yes
                ENV_SUCCESS=$?
            fi
            
            # Check if creation was successful
            if [ $ENV_SUCCESS -eq 0 ]; then
                echo "✅ Environment '$env_name' is ready. Applying automated bug fixes..."
                
                # ----------------------------------------------------
                # 🛠️ MANUAL BUG FIXES (Applied Automatically)
                # ----------------------------------------------------
                
                # ---> PROSPECTOR
                if [[ "$env_name" == "prospector" ]]; then
                    echo "⚙️  Configuring Prospector..."
                    mkdir -p ~/Prospectus
                    if [ ! -d "$HOME/Prospectus/fsps" ]; then
                        git clone https://github.com/cconroy20/fsps.git ~/Prospectus/fsps
                    fi
                    $CONDA_BIN run -n prospector conda env config vars set SPS_HOME="$HOME/Prospectus/fsps"
                    
                    # Install PyPI dependencies
                    $CONDA_BIN run -n prospector python -m pip install fsps astro-sedpy astro-prospector
                    
                    # Register Kernel
                    $CONDA_BIN run -n prospector python -m ipykernel install --user --name=prospector --display-name="PROSPECTOR (Stable Release)"
                fi
                
                # ---> HEASOFT (henv)
                if [[ "$env_name" == "henv" ]]; then
                    echo "⚙️  Configuring HEASoft CALDB..."
                    mkdir -p ~/caldb/software/tools
                    cd ~/caldb/software/tools || exit
                    if [ ! -f "caldbinit.sh" ]; then
                        wget -q --show-progress https://heasarc.gsfc.nasa.gov/FTP/caldb/software/tools/caldb_setup_files.tar.Z
                        tar -zxvf caldb_setup_files.tar.Z
                        rm caldb_setup_files.tar.Z
                        sed -i "s|^CALDB=.*|CALDB=$HOME/caldb; export CALDB|" ~/caldb/software/tools/caldbinit.sh
                    fi
                    
                    ENV_PATH=$($CONDA_BIN info --base)/envs/henv
                    mkdir -p $ENV_PATH/etc/conda/activate.d
                    mkdir -p $ENV_PATH/etc/conda/deactivate.d
                    
                    cat << 'EOF' > $ENV_PATH/etc/conda/activate.d/caldb_env.sh
#!/bin/bash
export CALDB=$HOME/caldb
source $CALDB/software/tools/caldbinit.sh
EOF

                    cat << 'EOF' > $ENV_PATH/etc/conda/deactivate.d/caldb_env.sh
#!/bin/bash
unset CALDB
unset CALDBCONFIG
unset CALDBALIAS
EOF
                    cd "$REPO_DIR" || exit
                fi
                
                # ---> THREEML
                if [[ "$env_name" == "threeML" ]]; then
                    echo "⚙️  Configuring ThreeML and XSPEC..."
                    # Fix heainit.sh
                    HEAINIT_PATH="$HOME/miniforge3/envs/threeML/etc/conda/activate.d/heainit.sh"
                    if [ -f "$HEAINIT_PATH" ]; then
                        sed -i "s|export HEADAS=\$CONDA_PREFIX/heasoft|export HEADAS=$HOME/miniforge3/envs/threeML/heasoft|" "$HEAINIT_PATH"
                        sed -i 's|$HEADAS/BUILD_DIR/headas-init.sh|$HEADAS/headas-init.sh|' "$HEAINIT_PATH"
                    fi
                    
                    # Fix missing conda-meta history if needed
                    mkdir -p ~/miniforge3/envs/threeML/conda-meta
                    if [ ! -f ~/miniforge3/envs/threeML/conda-meta/history ]; then
                        echo "# Created by manual fix" > ~/miniforge3/envs/threeML/conda-meta/history
                    fi
                    
                    # Env vars
                    $CONDA_BIN run -n threeML conda env config vars set OMP_NUM_THREADS=1 MKL_NUM_THREADS=1 NUMEXPR_NUM_THREADS=1
                    
                    # Install pynchrotron
                    $CONDA_BIN run -n threeML python -m pip install git+https://github.com/grburgess/pynchrotron.git
                    
                    # Register Kernel
                    $CONDA_BIN run -n threeML python -m ipykernel install --user --name threeML --display-name "Python (threeML)"
                    
                    # Distrobox VS Code Bridge
                    mkdir -p ~/.local/share/jupyter/kernels/threeml-distrobox
                    cat << 'EOF' > ~/.local/share/jupyter/kernels/threeml-distrobox/kernel.json
{
  "argv": [
    "distrobox",
    "enter",
    "astrobox",
    "--",
    "/home/void/miniforge3/envs/threeML/bin/python",
    "-m",
    "ipykernel_launcher",
    "-f",
    "{connection_file}"
  ],
  "display_name": "3ML (Distrobox GPU)",
  "language": "python"
}
EOF
                fi
                
                # ---> ASTRO PHOTOMETRY
                if [[ "$env_name" == "astro_photometry" ]]; then
                    echo "⚙️  Configuring Astro Photometry..."
                    # Register Kernel
                    $CONDA_BIN run -n astro_photometry python -m ipykernel install --user --name=astro_photometry --display-name="Python (Astro Photometry)"
                    
                    echo ""
                    read -p "Download 5GB Astrometry.net 4200-series indices? (y/n) " -n 1 -r
                    echo
                    if [[ $REPLY =~ ^[Yy]$ ]]; then
                        echo "Downloading Astrometry Indices (this will take a while)..."
                        mkdir -p ~/astrometry_data
                        cd ~/astrometry_data || exit
                        for series in 4203 4204 4205 4206 4207; do
                            wget -q --show-progress -r -l1 --no-parent -nd -A "index-${series}-*.fits" http://data.astrometry.net/4200/
                        done
                        
                        cat << EOF > ~/astrometry_data/local.cfg
add_path $HOME/astrometry_data
inparallel
cpulimit 300
EOF
                        cd "$REPO_DIR" || exit
                    else
                        echo "Skipping index downloads."
                    fi
                fi
                
                # ---> MESA_ENV (Conda Environment for MESA Reader)
                if [[ "$env_name" == "mesa_env" ]]; then
                    echo "⚙️  Configuring MESA Conda Environment..."
                    $CONDA_BIN run -n mesa_env python -m pip install mesa-reader
                    $CONDA_BIN run -n mesa_env python -m ipykernel install --user --name mesa_env --display-name "Python (MESA)"
                fi

                echo "✅ Bug fixes applied for $env_name."
            else
                echo "❌ Failed to create environment: $env_name"
            fi
        fi
    done
else
    echo "Conda backup directory not found at $BACKUP_DIR!"
fi

# --- MESA System Installation ---
echo -e "\n--- MESA SDK & Source Code Setup ---"
read -p "Install MESA System SDK and download Source Code (2.3GB)? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    # 1. System packages
    echo "Installing MESA system dependencies..."
    sudo pacman -S --needed binutils make perl libx11 tcsh glibc xorg-xwayland --noconfirm

    # 2. SDK download & extract
    if [ ! -d "$HOME/mesasdk" ]; then
        echo "Downloading MESA SDK..."
        cd ~ || exit
        wget -q --show-progress "http://user.astro.wisc.edu/~townsend/resource/download/mesasdk/mesasdk-x86_64-linux-26.3.2.tar.gz" -O mesasdk-x86_64-linux-26.3.2.tar.gz
        tar xvfz mesasdk-x86_64-linux-26.3.2.tar.gz -C ~/
        mv ~/mesasdk-26.3.2 ~/mesasdk
        rm mesasdk-x86_64-linux-26.3.2.tar.gz
    else
        echo "✅ MESA SDK already exists at ~/mesasdk"
    fi

    # 3. Create bashrc_mesa
    if [ ! -f ~/.bashrc_mesa ]; then
        echo "Configuring ~/.bashrc_mesa isolation file..."
        cat << 'EOF' > ~/.bashrc_mesa
[[ $- != *i* ]] && return
export CONDA_AUTO_ACTIVATE_BASE=false
if [ -f ~/.bashrc ]; then
    source ~/.bashrc
fi
export MESASDK_ROOT=~/mesasdk
source $MESASDK_ROOT/bin/mesasdk_init.sh
PS1="[MESA] [\u@\h \W]\$ "
export MESA_DIR=~/mesa-26.04.1
export OMP_NUM_THREADS=4
export PATH=$PATH:$MESA_DIR/scripts/shmesa
EOF
    fi

    # Add fish alias if not present
    if ! grep -q 'alias mesa="bash --rcfile ~/.bashrc_mesa"' ~/.config/fish/config.fish; then
        echo 'alias mesa="bash --rcfile ~/.bashrc_mesa"' >> ~/.config/fish/config.fish
    fi

    # 4. Download Source Code
    if [ ! -d "$HOME/mesa-26.04.1" ]; then
        echo "Downloading MESA Source Code (2.3GB)..."
        cd ~ || exit
        wget -q --show-progress "https://zenodo.org/records/19722306/files/mesa-26.04.1.zip?download=1" -O mesa-26.04.1.zip
        unzip -q mesa-26.04.1.zip
        rm mesa-26.04.1.zip
        
        # 5. Compile prompt
        echo ""
        read -p "MESA Download complete. Do you want to run the compiler right now? (This will take hours) (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "Starting MESA compilation..."
            cd ~/mesa-26.04.1 || exit
            # We must run it within the SDK bash environment
            bash --rcfile ~/.bashrc_mesa -c "./install"
        else
            echo "Skipping compilation. You can run './install' inside ~/mesa-26.04.1 later using the 'mesa' environment."
        fi
    else
        echo "✅ MESA source code already exists at ~/mesa-26.04.1"
    fi
else
    echo "Skipping MESA setup."
fi

cd "$REPO_DIR" || exit
echo -e "\nPhase 4 Complete! Research subsystem is ready."
