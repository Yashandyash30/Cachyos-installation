# Voidphone Battery Notifier Guide (Uptime Kuma & ntfy)

This guide sets up a background script on your phone that pushes battery updates to your Uptime Kuma dashboard. If the battery drops below 15%, Uptime Kuma triggers an alert using `ntfy.sh`, which instantly sends a push notification to your PC, laptop, and any other devices listening to it.

---

## Phase 1: Setup Uptime Kuma Monitor
1. Open your Uptime Kuma dashboard (`http://100.103.187.97:3001`).
2. Click **+ Add New Monitor**.
3. **Monitor Type:** Select `Push`.
4. **Friendly Name:** `Voidphone Battery`.
5. **Heartbeat Interval:** 60.
6. Click **Save**.
7. Look for the **Push URL** (it looks like `/api/push/XXXX?status=up&msg=OK&ping=`). Copy this URL; you'll need it for the script in Phase 3.

---

## Phase 2: Setup Uptime Kuma Notifications
To get alerted when your battery drops, simply set up a notification in Uptime Kuma.
1. In Uptime Kuma, go to **Settings > Notifications > Setup Notification**.
2. Select your preferred service (e.g., **Telegram**, **Discord**, or **Email**) and follow the built-in prompts to link it.
3. Once saved, go to your "Voidphone Battery" monitor and check the box next to your new notification service so it knows to alert you.

---

## Phase 3: Create the Battery Monitor Script
1. Open Termux on your phone and make sure `jq` and `curl` are installed:
   ```bash
   pkg install jq curl -y
   ```
2. Create the script:
   ```bash
   nano ~/battery-monitor.sh
   ```
3. Paste the following code:
   ```bash
   #!/bin/bash

   # IMPORTANT NOTE: Replace "YOUR_PUSH_ID_HERE" with the actual ID from your Kuma Push URL. 
   # Example: If your URL is .../api/push/a1b2c3d4, then put "a1b2c3d4" below.
   KUMA_URL="http://127.0.0.1:3001/api/push/YOUR_PUSH_ID_HERE"
   THRESHOLD=15

   while true; do
       BATT_INFO=$(termux-battery-status)
       PERCENT=$(echo "$BATT_INFO" | jq '.percentage')
       STATUS=$(echo "$BATT_INFO" | jq -r '.status')

       # By sending "ping=${PERCENT}", Kuma will graph your battery level on its response-time chart!
       if [ "$STATUS" = "DISCHARGING" ] && [ "$PERCENT" -le "$THRESHOLD" ]; then
           curl -s "${KUMA_URL}?status=down&msg=Battery+at+${PERCENT}%25&ping=${PERCENT}" > /dev/null
           sleep 1800
       else
           curl -s "${KUMA_URL}?status=up&msg=${PERCENT}%25&ping=${PERCENT}" > /dev/null
           sleep 60
       fi
   done
   ```
4. Save and make it executable:
   ```bash
   chmod +x ~/battery-monitor.sh
   ```

---

## Phase 4: Run it in the background & Persist Reboots

To start the script immediately without rebooting, run this in Termux:
```bash
nohup ~/battery-monitor.sh > /dev/null 2>&1 &
```

### Make it Persist Reboots (Magisk)
To ensure the battery monitor starts silently every time your phone restarts, we need to add it to your existing Magisk boot script.

1. Open Termux and edit your Magisk services script as root:
   ```bash
   sudo nano /data/adb/service.d/termux_services.sh
   ```

2. Scroll to the very bottom of the file. You will see the lines that start your SSH server and Uptime Kuma. Add the new battery monitor command as the **very last line**, so your file looks like this:

   ```bash
   #!/system/bin/sh
   until [ "$(getprop sys.boot_completed)" = "1" ]; do sleep 2; done

   # Load Termux environment and start services as your Termux user
   su u0_a183 -c "source /data/data/com.termux/files/usr/etc/profile && sshd"
   su u0_a183 -c "source /data/data/com.termux/files/usr/etc/profile && nohup proot-distro login ubuntu -- bash -c \"cd ~/uptime-kuma && node server/server.js --port=3001\" > /data/data/com.termux/files/home/uptime-kuma-server.log 2>&1 &"
   
   # Start the Battery Monitor script
   su u0_a183 -c "source /data/data/com.termux/files/usr/etc/profile && nohup /data/data/com.termux/files/home/battery-monitor.sh > /dev/null 2>&1 &"
   ```

3. Save and exit (`Ctrl+O`, `Enter`, `Ctrl+X`).

That's it! Now `voidphone` will quietly run this script in the background forever, automatically surviving any reboots.
