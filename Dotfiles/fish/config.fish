# =========================================================================
# SYSTEM & ENVIRONMENT SETTINGS
# =========================================================================
source /usr/share/cachyos-fish-config/cachyos-config.fish
set -x TERM xterm-256color

# Wayland Display Bridge for Legacy X11/Distrobox
# Suppress output so it doesn't spam the terminal on startup
xhost +si:localuser:void > /dev/null 2>&1

# overwrite greeting
# potentially disabling fastfetch
#function fish_greeting
#    # smth smth
#end


# =========================================================================
# PACKAGE MANAGERS (CONDA / MAMBA)
# =========================================================================
# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
if test -f /home/void/miniforge3/bin/conda
    eval /home/void/miniforge3/bin/conda "shell.fish" "hook" $argv | source
else
    if test -f "/home/void/miniforge3/etc/fish/conf.d/conda.fish"
        . "/home/void/miniforge3/etc/fish/conf.d/conda.fish"
    else
        set -x PATH "/home/void/miniforge3/bin" $PATH
    end
end
# <<< conda initialize <<<

# >>> mamba initialize >>>
# !! Contents within this block are managed by 'mamba shell init' !!
# 'set -gx' creates a global, exported variable.
# This line tells the system exactly where your mamba executable is located.
set -gx MAMBA_EXE "/home/void/miniforge3/bin/mamba"

# This sets the root directory for your miniforge installation.
set -gx MAMBA_ROOT_PREFIX "/home/void/miniforge3"

# This line runs the mamba setup script specifically tailored for the fish shell.
# The pipe (|) feeds the output into the 'source' command to apply it immediately.
$MAMBA_EXE shell hook --shell fish --root-prefix $MAMBA_ROOT_PREFIX | source
# <<< mamba initialize <<<


# =========================================================================
# CONDA ENVIRONMENT MANAGEMENT & SHORTCUTS
# =========================================================================
abbr -a c "conda activate"
abbr -a dc "conda deactivate"

# Usage: type 'cstack <env_name>' and hit space, then enter.
abbr -a cstack "conda activate --stack"

# 'function [name]' defines the shortcut word you will type in the terminal.
function pyrafinit
    clear
    # Step 1: Tell conda to activate the specific environment.
    conda activate pyraf
    # Step 2: Change the terminal text color.
    set_color cyan
    # Step 3: Print your custom confirmation message.
    echo "pyraf env activated"
    # Step 4: Reset the text color back to normal so your prompt doesn't stay colored.
    set_color normal
end

function henvinit
    clear
    echo -e "\e[32mEntering bash and activating henv...\e[0m"
    # This opens bash and uses a temporary init file to source your bashrc and activate conda
    bash --rcfile (echo "source ~/.bashrc; conda activate henv; echo -e '\e[32mhenv env activated\e[0m'" | psub)
end

function fermiinit
    clear
    echo -e "\e[33mEntering bash and activating fermi...\e[0m"
    bash --rcfile (echo "source ~/.bashrc; conda activate fermi; echo -e '\e[33mfermi env activated\e[0m'" | psub)
end

function cigale
    clear
    conda activate cigale
    set_color yellow
    echo "cigale env activated"
    set_color normal
end

function cigale2s
    clear
    conda activate cigale2s
    set_color yellow
    echo "cigale2s env activated"
    set_color normal
end

function threemlinit
    clear
    conda activate threeML
    set_color magenta
    echo "threeML env activated"
    set_color normal
end

# Note: I made the function name entirely lowercase (threeml) so it is faster to type.
function prospectorinit
    clear
    conda activate prospector
    set_color magenta
    echo "prospector env activated"
    set_color normal
end


# =========================================================================
# ASTROPHYSICS & RESEARCH PIPELINES
# =========================================================================
# PyRAF & Image Viewer (Native 64-bit inside container)
alias pyraf="distrobox enter astro-box -- pyraf"
alias ds9="distrobox enter astro-box -- ds9"

# DAOPHOT II Suite (Wrapped in bash to bypass 32-bit crun limitation)
alias daophot="distrobox enter astro-box -- bash -c '~/dao2/daophot'"
alias allstar="distrobox enter astro-box -- bash -c '~/dao2/allstar'"
alias daomatch="distrobox enter astro-box -- bash -c '~/dao2/ndaomatch'"
alias daomaster="distrobox enter astro-box -- bash -c '~/dao2/ndaomaster'"

# MESA alias
alias mesa="bash --rcfile ~/.bashrc_mesa"


# =========================================================================
# SYSTEM UTILITIES & ALIASES
# =========================================================================
# System info
abbr -a fetchfull "fastfetch -c full"

# General Shortcuts
abbr -a z "zeditor"
abbr -a a "antigravity"
abbr -a wl "wol 74:4c:a1:7f:41:09"

# Qylock SDDM Theme Management
abbr -a theme "cd ~/qylock && ./sddm.sh"
abbr -a theme-test "sddm-greeter-qt6 --test-mode --theme /usr/share/sddm/themes/"

# Monitor Brightness Controls (MSI External Monitor)
abbr -a dset 'ddcutil setvcp 10'
abbr -a dget 'ddcutil getvcp 10'
abbr -a dup 'ddcutil setvcp 10 + 10'
abbr -a ddown 'ddcutil setvcp 10 - 10'

# KDE Dolphin Cache Reload
function rdolphin
    # Step 1: Run the KDE cache reload command silently
    kbuildsycoca6 --noincremental
    # Step 2: Change text color
    set_color blue
    # Step 3: Print the confirmation message
    echo "Dolphin cache reloaded"
    # Step 4: Reset text color
    set_color normal
end
