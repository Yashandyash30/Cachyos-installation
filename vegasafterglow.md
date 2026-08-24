
This complete reference guide covers everything needed to rebuild your VegasAfterglow workstation on any future CachyOS system, ensuring seamless remote access for your Galaxy Tab S9 and other Tailscale devices.

### 1. Python Environment & Jupyter Setup

CachyOS enforces strict package management rules (PEP 668), so you must explicitly install `pip` inside your Conda environment to avoid conflicts with system packages.

1. Create and activate the stable Python environment:

```fish
conda create -n vegas_env python=3.11 -y
conda activate vegas_env

```

2. Install an isolated pip package, then install the physics engine with MCMC tools:

```fish
conda install pip -y
python -m pip install VegasAfterglow[mcmc]

```

3. Bind this environment to Jupyter as a selectable kernel:

```fish
conda install conda-forge::ipykernel -y
python -m ipykernel install --user --name=vegas_env --display-name="Python (VegasAfterglow)"

```

### 2. Web Tool Initialization

The web interface requires the source code repository and Node.js for the frontend dashboard.

1. Install the system requirements and clone the codebase:

```fish
sudo pacman -S nodejs npm
git clone https://github.com/YihanWangAstro/VegasAfterglow.git
cd VegasAfterglow
```

2. Set up the backend virtual environment using the Fish-specific script:

```fish
cd webtool/backend
python -m venv .venv
source .venv/bin/activate.fish
python -m pip install -e '../..[webtool]'
```

3. Initialize the frontend configuration (do not start the server yet):

```fish
cd ../frontend
cp .env.local.example .env.local
npm install
```

### 3. Network & Security Overrides

By default, the VegasAfterglow web tool strictly blocks cross-device communication. You must manually override the CORS (Cross-Origin Resource Sharing) and CSP (Content Security Policy) rules.

**Backend Fix (FastAPI CORS):**

1. Open `nano ~/VegasAfterglow/webtool/backend/app/main.py`.
2. Locate the `CORSMiddleware` configuration block.
3. Modify the `allow_origins` parameter to accept all incoming connections:

```python
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Changed from the default list
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

**Frontend Fix (Next.js CSP):**

1. Open `nano ~/VegasAfterglow/webtool/frontend/next.config.mjs` (or `.js`).
2. Locate the `Content-Security-Policy` header block.
3. Add `http://*:8000` to the end of the `connect-src` string to whitelist your backend across all network interfaces (including Tailscale):

```javascript
"connect-src 'self' http://localhost:8000 http://127.0.0.1:8000 https://api.vegasafterglow.com https://*.vegasafterglow.com http://8.136.116.255 http://*:8000",
```

4. *Important:* If reinstalling in the future, you must delete the `.next` cache directory (`rm -rf .next`) before starting the frontend so it registers the new security policy.

### 4. Fish Automation Script

This function dynamically detects your active Tailscale IP, injects it into the Next.js environment, launches both servers, and tears them down cleanly.

1. Create the function file: `nano ~/.config/fish/functions/vegasweb.fish`
2. Paste the following configuration:

```fish
function vegasweb --description "Launch VegasAfterglow web tool on Tailscale"
    set -l VEGAS_DIR "$HOME/VegasAfterglow"

    # 1. Grab the current Tailscale IP
    set -l TS_IP (tailscale ip -4 2>/dev/null)
    if test -z "$TS_IP"
        echo "Could not detect Tailscale IP. Defaulting to localhost."
        set TS_IP "127.0.0.1"
    end
    echo "Detected Tailscale IP: $TS_IP"

    # 2. Automatically configure the frontend to talk to the backend over Tailscale
    echo "Updating frontend configuration..."
    sed -i '/^NEXT_PUBLIC_API_URL=/d' "$VEGAS_DIR/webtool/frontend/.env.local" 2>/dev/null
    echo "NEXT_PUBLIC_API_URL=http://$TS_IP:8000" >> "$VEGAS_DIR/webtool/frontend/.env.local"

    echo "Starting VegasAfterglow Backend..."
    "$VEGAS_DIR/webtool/backend/.venv/bin/uvicorn" app.main:app --app-dir "$VEGAS_DIR/webtool/backend" --host 0.0.0.0 --port 8000 >/dev/null 2>&1 &
    set -l BACKEND_PID $last_pid

    echo "Starting VegasAfterglow Frontend..."
    set -l START_DIR $PWD
    cd "$VEGAS_DIR/webtool/frontend"
    # The -H 0.0.0.0 flag ensures the frontend is accessible from other devices
    npm run dev -- -H 0.0.0.0 >/dev/null 2>&1 &
    set -l FRONTEND_PID $last_pid
    cd "$START_DIR"

    echo "VegasAfterglow Web Tool is starting up!"
    echo "--> PC Local Access: http://localhost:3000"
    echo "--> Remote Access (Tailscale): http://$TS_IP:3000"
    echo "Press Ctrl+C to stop both servers."

    trap "kill $BACKEND_PID $FRONTEND_PID 2>/dev/null; echo '\nServers stopped cleanly.'; trap - EXIT INT TERM" EXIT INT TERM
    wait
end
```

Does this cover all the specific networking configurations and workarounds you needed for your setup notes?
