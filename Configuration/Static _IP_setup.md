Here is a clean, Markdown-formatted guide that you can copy and paste directly into a GitHub Gist or a repository `README.md` file. It covers everything from gathering the network variables to applying them via the terminal GUI.

---

# How to Set a Static IP in Linux (Wi-Fi & Ethernet)

This guide covers how to set a persistent static IP address for both wired (Ethernet) and wireless (Wi-Fi) connections using `nmtui` (NetworkManager Text User Interface). This is especially useful on distributions like CachyOS, Arch Linux, and Fedora.

## Phase 1: Gather Your Network Information
Before changing any settings, you need to find out how your local network is currently configured so you don't accidentally break your internet routing.

### 1. Find Your Current IP and Subnet Mask
Open a terminal and run:
```bash
ip a

```

* Look for your active connection (`enp...` for Ethernet, or `wlan0` for Wi-Fi).
* Find the line starting with `inet`. It will look something like `inet 172.21.1.129/22`.
* **Note this down:** `172.21.1.129` is the IP address, and `/22` (or `/24`) is the subnet mask. You will need both!

### 2. Find Your Default Gateway (Router IP)

Next, find out where your machine sends its traffic to reach the internet:

```bash
ip route | grep default

```

* The output will look like: `default via 172.21.3.254 dev wlan0...`
* **Note this down:** The IP address immediately following `via` (e.g., `172.21.3.254`) is your Gateway.

### 3. Choose Your DNS Servers

You can use your Gateway IP as your DNS, but it is often faster to use public DNS servers:

* **Cloudflare:** `1.1.1.1`
* **Google:** `8.8.8.8`

---

## Phase 2: Configure the Static IP via `nmtui`

Now that you have your IP/Subnet, Gateway, and DNS, you can lock them in.

1. Open the NetworkManager terminal UI:
```bash
nmtui

```


2. Use your arrow keys to select **Edit a connection** and press `Enter`.
3. Select your active network interface (e.g., `Wired connection 1` or your Wi-Fi network name) and press `Enter`.
4. Scroll down to **IPv4 CONFIGURATION**.
5. Change `<Automatic>` to **`<Manual>`**.
6. Arrow over to **`<Show>`** and press `Enter` to expand the manual settings.
7. Fill in the fields using the data you gathered in Phase 1:
* **Addresses:** `<Add...>` -> Enter your desired IP + subnet (e.g., `172.21.1.250/22`).
* **Gateway:** Enter your gateway IP (e.g., `172.21.3.254`).
* **DNS servers:** `<Add...>` -> Enter `1.1.1.1`, then `<Add...>` again to enter `8.8.8.8`.


8. Scroll all the way down to the bottom right and select **`<OK>`** to save.

---

## Phase 3: Apply and Verify

To make the system use your new static settings, you need to restart the connection.

1. Back on the main `nmtui` menu, select **Activate a connection**.
2. Find your connection in the list (it will have a `*` next to it, indicating it is active).
3. Press `Enter` to **Deactivate** it.
4. Wait 1-2 seconds.
5. Press `Enter` again to **Activate** it.
6. Press `Esc` to exit `nmtui`.

### Verification

Run `ip a` one last time to confirm your new static IP is locked in, and run a quick ping test to ensure you still have internet access:

```bash
ping -c 4 google.com

```

If you get replies, your static IP is successfully configured!

```

```
