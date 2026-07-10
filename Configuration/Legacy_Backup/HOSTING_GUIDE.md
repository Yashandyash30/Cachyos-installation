# Multiplayer Game Hosting Guide (CachyOS / Arch Linux)

## Method 1: The Local "LAN Party" Server

**Best for:** When everyone is in the same room connected to the exact same Wi-Fi router. It has zero lag, bypasses all internet firewalls, and works even if the building's internet goes down.

### Step 1: Open the Firewall

By default, CachyOS blocks incoming connections. You need to open the ports your Node server uses.

1. Open your terminal and allow the standard Node ports:
```fish
sudo ufw allow 3000/tcp
sudo ufw allow 10000/tcp

```


2. Reload the firewall to apply the changes:
```fish
sudo ufw reload

```



*(Note: You only ever have to do this step once. The firewall will remember these rules forever!)*

### Step 2: Start Your Game

Open a terminal inside your `quiz-game` folder and start the server:

```fish
node server.js

```

*Look at the terminal output to confirm which port it grabbed (usually `3000`). Leave this terminal tab running.*

### Step 3: Find Your Local IP Address

Open a **new** terminal tab and run:

```fish
ip -br a

```

Look down the list for your active connection (it will say `UP`, like `enp3s0` for Ethernet or `wlan0` for Wi-Fi). Grab the IP address next to it (e.g., `172.21.3.204` or `192.168.1.50`).

### Step 4: Give Players the Link

Combine your IP address and your port. Tell everyone in the room to type this exact URL into their phone browser:
**`http://YOUR_IP:YOUR_PORT`** *(e.g., `http://172.21.3.204:3000`)*

*(Crucial: Make sure they are connected to the same Wi-Fi and do NOT type `https://`)*

---

## Method 2: The Cloudflare Global Tunnel

**Best for:** When players are on different Wi-Fi networks, using cellular 4G/5G mobile data, or when the venue's Wi-Fi router prevents local devices from talking to each other. This creates a secure, global internet link pointing right to your laptop.

### Step 1: Install Cloudflared (First Time Only)

Since you are on Arch, install the Cloudflare daemon using pacman:

```fish
sudo pacman -S cloudflared

```

### Step 2: Start Your Game

Open a terminal inside your `quiz-game` folder and start the server:

```fish
node server.js

```

*Note the port (e.g., `3000`). Leave this terminal tab running.*

### Step 3: Launch the Encrypted Tunnel

Open a **new** terminal tab. To bypass strict institutional firewalls that block standard UDP gaming connections, you must force Cloudflare to use the standard HTTP2 protocol.

Run this command (change the port if your Node server isn't on 3000):

```fish
cloudflared tunnel --protocol http2 --url http://localhost:3000

```

### Step 4: Grab the Golden Link

Cloudflare will print a large block of text. Look for the box that says "Your quick Tunnel has been created!" and copy the secure link. It will look like this:
**`https://random-words-here.trycloudflare.com`**

Give this exact link to your players. They can connect from anywhere in the world, and Cloudflare will securely funnel their clicks directly into your local laptop.

---

**Game Master Pro-Tip:** Keep both terminal tabs visible on your screen during the event! One tab will show your Node.js logs (so you can watch players connecting), and the other will show your Cloudflare tunnel staying alive.
