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
