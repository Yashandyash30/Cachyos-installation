# MESA Remote GUI Environments Guide
*(Live PGSTAR Forwarding, Persistent Zellij Sessions & Niri Integration)*

This guide extends the remote architecture from [08_Advanced_Bidirectional_Remote_Environments.md](file:///home/void/Cachyos-installation/Configuration/08_Advanced_Bidirectional_Remote_Environments.md) to **MESA (Modules for Experiments in Stellar Astrophysics)** on **Surya HPC** (`192.168.4.1`) and **ARIES** (`172.18.1.5`).

---

## 1. Overview: How MESA GUI (PGSTAR) Works Over Remote SSH

When you run a stellar simulation in MESA (`./rn` or `./star`), its built-in visualization engine, **PGSTAR** (powered by PGPLOT), can generate live diagnostic plots as the star evolves:
* **HR Diagram** (Luminosity vs. Effective Temperature)
* **TRho Profile** (Internal Temperature vs. Density)
* **Abundance Profile** (Hydrogen, Helium, Carbon, Iron vs. Mass Coordinate)
* **Kippenhahn Diagram** (Convective vs. Radiative core/envelope boundaries over time)

Depending on your workflow, you have two primary ways to run this from your Laptop or PC:

```
┌──────────────────────────────────────────────────────────────────────────────────┐
│                             MESA Execution Workflows                             │
├────────────────────────────────────────┬─────────────────────────────────────────┤
│    Mode 1: Live Interactive PGSTAR     │      Mode 2: Overnight Persistent       │
│               (mesagui)                │                (mesaz)                  │
├────────────────────────────────────────┼─────────────────────────────────────────┤
│ • Best for: Testing inlists, debugging │ • Best for: Multi-hour/overnight runs   │
│ • Connection: Trusted X11 (`ssh -Y`)   │ • Connection: Zellij detachable session │
│ • Graphics: Live Xwayland popups       │ • Graphics: Auto-saved PNGs to disk     │
│ • Disconnect safety: No (Wi-Fi drop    │ • Disconnect safety: 100% immune to     │
│   kills X11 connection)                │   laptop sleep, lid close, Wi-Fi drops  │
└────────────────────────────────────────┴─────────────────────────────────────────┘
```

---

## 2. Part 1: Smart Fish Jump Functions

Add these smart functions to your Laptop and PC. They handle trusted X11 authentication, bypass slow server profile scripts (`--noprofile`), and automatically activate the selected MESA subshell environment (`mesa23` or `mesa26`).

### 2.1 Function: `mesagui` (Live Interactive PGSTAR)
Run this on your Laptop or PC terminal to start an interactive MESA session with live X11/Xwayland GUI forwarding:

```fish
function mesagui --description 'Launch remote MESA session with live PGSTAR GUI forwarding'
    # Usage: mesagui <server> [version 23|26] [work_directory]
    # Examples:
    #   mesagui aries 23
    #   mesagui surya 26 ~/my_mesa_run
    set server $argv[1]
    set version $argv[2]
    set work_dir $argv[3]

    if test -z "$server"
        echo "Usage: mesagui <aries|surya> [23|26] [work_directory]"
        return 1
    end

    if test -z "$version"
        set version 23
    end

    # Determine host mapping
    switch $server
        case aries
            set target_host "shashi@172.18.1.5"
        case surya
            set target_host "yashsharma@192.168.4.1"
        case '*'
            set target_host $server
    end

    # Determine initial launch command
    set cmd "mesa$version"
    if test -n "$work_dir"
        set cmd "cd '$work_dir' && mesa$version"
    end

    echo "Connecting to $server with Trusted X11 Forwarding for MESA $version..."
    ssh -Y -t $target_host "exec bash --noprofile --rcfile ~/.bashrc -i -c '$cmd'"
end

funcsave mesagui
```

### 2.2 Function: `mesaz` (Persistent Zellij Session)
For runs lasting several hours or overnight where you want to close your laptop lid without interrupting the simulation:

```fish
function mesaz --description 'Attach or create persistent Zellij session for MESA on remote server'
    # Usage: mesaz <server> [session_name]
    # Examples:
    #   mesaz aries
    #   mesaz surya stellar_merger
    set server $argv[1]
    set session_name $argv[2]

    if test -z "$server"
        echo "Usage: mesaz <aries|surya> [session_name]"
        return 1
    end

    if test -z "$session_name"
        set session_name "mesa_$server"
    end

    switch $server
        case aries
            set target_host "shashi@172.18.1.5"
        case surya
            set target_host "yashsharma@192.168.4.1"
        case '*'
            set target_host $server
    end

    echo "Jumping into persistent Zellij session '$session_name' on $server..."
    ssh -t $target_host "exec bash --noprofile --rcfile ~/.bashrc -i -c 'zellij attach -c $session_name'"
end

funcsave mesaz
```

---

## 3. Part 2: Niri Window Rules for PGSTAR

In Niri (the scrolling Wayland compositor on CachyOS), Xwayland windows default to opening in a new column. Because PGSTAR generates multiple diagnostic windows (Grid, HR, TRho), you want them to open as **floating, crisp windows** over your terminal rather than filling entire columns.

Edit your Niri configuration:
```bash
nano ~/.config/niri/config.kdl
```

Add this rule block:

```kdl
// Float and keep PGSTAR / PGPLOT graphic windows centered
window-rule {
    match app-id=r"^pgplot" title=r"^pgstar"
    open-floating true
    opacity 1.0
    default-floating-position x=100 y=100 relative-to="top-left"
}

// Fallback for general Xwayland PGPLOT windows
window-rule {
    match title=r".*pgplot.*"
    open-floating true
    opacity 1.0
}
```

Reload Niri with `niri msg action load-config` (or restart the session).

---

## 4. Part 3: Configuring PGSTAR (`inlist_pgstar`)

Inside your MESA experiment folder (e.g., copied from `$MESA_DIR/star/work`), edit `inlist_pgstar` to customize window behavior.

### 4.1 For Live Interactive Viewing (`mesagui`)
Open `inlist_pgstar` and ensure window flags are enabled:

```fortran
&pgstar

   ! Overall switch for PGSTAR
   pgstar_flag = .true.

   ! 1. Live On-Screen HR Diagram
   HR_win_flag = .true.
   HR_win_width = 7
   HR_win_aspect_ratio = 0.75

   ! 2. Live On-Screen Multi-panel Grid (TRho, Abundances, Kippenhahn)
   Grid1_win_flag = .true.
   Grid1_win_width = 11
   Grid1_win_aspect_ratio = 0.65

   ! Update plot frequency (every 5 timesteps)
   Grid1_win_interval = 5

/ ! end of pgstar namelist
```

When you execute `./rn`, the PGPLOT windows will instantly project from the remote server onto your laptop screen.

---

### 4.2 For Overnight Persistent Runs (`mesaz`)
> [!WARNING]
> If you close your laptop while `_win_flag = .true.` is active over SSH, the lost X11 connection will cause PGPLOT to crash MESA with an `X11 I/O Error`.

For long runs inside Zellij, configure PGSTAR to save **high-resolution PNG frames directly to disk** instead of opening on-screen windows:

```fortran
&pgstar

   pgstar_flag = .true.

   ! Disable live windows to prevent disconnect crashes
   Grid1_win_flag = .false.
   HR_win_flag = .false.

   ! Enable automated PNG file generation
   Grid1_file_flag = .true.
   Grid1_file_dir = 'png'
   Grid1_file_prefix = 'grid1_'
   Grid1_file_interval = 10     ! Save an image every 10 steps
   Grid1_file_width = 1600
   Grid1_file_aspect_ratio = 0.65

   HR_file_flag = .true.
   HR_file_dir = 'png'
   HR_file_prefix = 'hr_'
   HR_file_interval = 10

/ ! end of pgstar namelist
```

#### How to monitor the simulation in real time:
Because you have native Dolphin remote network shares (`remote:/ARIES` or `remote:/Surya_HPC`), you can:
1. Open the `png/` folder inside Dolphin on your laptop.
2. Hit `F5` or watch new `.png` frames generated by MESA as the star evolves.
3. Open any frame in your local image viewer (e.g., `loupe`, `imv`, or `feh`).

---

## 5. Part 4: Step-by-Step Test Procedure

To verify your live GUI setup:

1. **Open a terminal on your Laptop or PC.**
2. **Connect to ARIES with live GUI forwarding:**
   ```fish
   mesagui aries 23
   ```
3. **Verify X11 Forwarding is active:**
   ```bash
   echo $DISPLAY
   # Output should display localhost:10.0 or similar
   ```
4. **Test an interactive PGSTAR work directory:**
   ```bash
   # Copy sample work directory
   cp -r $MESA_DIR/star/work ~/mesa_test_work
   cd ~/mesa_test_work

   # Compile the work code
   ./mk

   # Run the model
   ./rn
   ```
5. **Result:**
   The MESA terminal output will scroll inside your local terminal, while the PGSTAR graphical windows (HR Diagram and Stellar Interior Grid) pop up as floating windows on your desktop!

---

## 6. Summary of Commands

| Workflow | Command | Use Case |
| :--- | :--- | :--- |
| **Live GUI (ARIES MESA 23)** | `mesagui aries 23` | Interactive tuning & live visual inspection |
| **Live GUI (Surya MESA 26)** | `mesagui surya 26` | Interactive tuning & live visual inspection |
| **Persistent Run (ARIES)** | `mesaz aries` | Long/overnight run immune to laptop lid close |
| **Persistent Run (Surya)** | `mesaz surya` | Long/overnight run immune to laptop lid close |
| **Full Remote Desktop** | X2Go Client | Full GUI desktop session with multi-window persistence |
