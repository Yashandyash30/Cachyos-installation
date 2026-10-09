**Yes, you can limit the battery charge to 80% on CachyOS.**

### Why It Stopped Working

On Acer laptops, the 80% battery limit is controlled by the Embedded Controller (EC) via Acer's proprietary ACPI/WMI interface. On Windows, Acer Care Center communicates with this interface. When the internal SSD was removed or power/battery reset, the EC reset back to default 100% charging.

We checked your laptop hardware:

* **Model:** Acer Aspire **A715-42G**
* **Hardware Interface:** The Acer battery health WMI interface (`79772EC5-04B1-4BFD-843C-61E7F77B6CC9`) is **present and active** on your system.
* **Kernel Headers:** `linux-cachyos-headers` is already installed.

To control this on Linux, you can use the community driver [acer-wmi-battery](https://github.com/frederik-h/acer-wmi-battery), which is specifically confirmed to work on the **Aspire A715-42G**.

---

### Step-by-Step Setup

Open your terminal and run the following commands:

#### 1. Install the DKMS module from AUR

Using `paru` (which is already installed on your system):

```bash
paru -S acer-wmi-battery-dkms
```

*(Using DKMS ensures that every time CachyOS updates your kernel, the driver rebuilds automatically).*

---

#### 2. Configure it to always limit to 80% on boot

Create a modprobe configuration to set `enable_health_mode=1` automatically:

```bash
echo "options acer-wmi-battery enable_health_mode=1" | sudo tee /etc/modprobe.d/acer-wmi-battery.conf
```

And ensure the module is loaded at boot:

```bash
echo "acer-wmi-battery" | sudo tee /etc/modules-load.d/acer-wmi-battery.conf
```

---

#### 3. Load the module immediately (no reboot required)

```bash
sudo modprobe acer-wmi-battery enable_health_mode=1
```

---

#### 4. Verify that the 80% limit is active

Check the status:

```bash
cat /sys/bus/wmi/drivers/acer-wmi-battery/health_mode
```

* Output `1`: **80% limit is active** (charging will stop when it hits 80%).
* Output `0`: Limit disabled (charges to 100%).

---

### Toggling Between 80% and 100% on the Fly

If you ever need to charge up to 100% before traveling:

* **Charge to 100%:**
  ```bash
  echo 0 | sudo tee /sys/bus/wmi/drivers/acer-wmi-battery/health_mode
  ```
* **Restore 80% limit:**
  ```bash
  echo 1 | sudo tee /sys/bus/wmi/drivers/acer-wmi-battery/health_mode
  ```
