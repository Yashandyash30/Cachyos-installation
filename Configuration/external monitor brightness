Here is the streamlined, terminal-only guide to setting up and controlling your monitor brightness from the command line.

### 1. Install DDCUtil

First, install the core package directly from the repositories.

```bash
sudo pacman -S ddcutil

```

### 2. Configure Kernel Modules & Permissions

For `ddcutil` to communicate with your monitor over HDMI, it needs access to the I2C kernel module. You also need to grant your user account permission so you don't have to use `sudo` every time you change the brightness.

- **Load the kernel module:**

```bash
sudo modprobe i2c-dev

```
- **Make it persistent across reboots:**

```bash
echo i2c-dev | sudo tee /etc/modules-load.d/i2c-dev.conf

```
- **Grant your user permission:**

```bash
sudo usermod -aG i2c $USER

```

*(Note: You must reboot your system after running this command for the user group permission to take effect).*

### 3. Verify the Connection

Once you have rebooted, open your terminal and verify that your system can successfully read the monitor data:

```bash
ddcutil detect

```

If you see your external monitor listed in the output without any errors, the hardware communication is perfect.

### 4. Set Up Terminal Shortcuts

Using abbreviations is the fastest way to control the monitor straight from the prompt without typing the full `ddcutil` commands.

- **Open your shell configuration file:**

```bash
nano ~/.config/fish/config.fish

```
- **Paste these lines at the bottom of the file:**

```code snippet
# External Monitor Brightness Controls
abbr -a bset 'ddcutil setvcp 10'
abbr -a bget 'ddcutil getvcp 10'
abbr -a bup 'ddcutil setvcp 10 + 10'
abbr -a bdown 'ddcutil setvcp 10 - 10'

```
- **Save and reload:** Save the file in nano (`Ctrl+O`, `Enter`, `Ctrl+X`), then reload your shell environment so the shortcuts activate:

```bash
source ~/.config/fish/config.fish

```

### Using Your Shortcuts

From any open terminal window, simply type your abbreviation, hit space, and hit enter.

- **Set an exact level:** Type `bset 70` to set the brightness to 70%.
- **Adjust relative levels:** Type `bup` to bump it up by 10%, or `bdown` to lower it by 10%.
- **Check the level:** Type `bget` to see what the monitor is currently set to.
