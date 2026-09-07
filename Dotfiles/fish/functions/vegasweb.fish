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

    # 3. Clean up any stale processes on ports 8000 and 3000
    fuser -k 8000/tcp 2>/dev/null; or true
    fuser -k 3000/tcp 2>/dev/null; or true

    # 4. Start Backend in background
    echo "Starting VegasAfterglow Backend on 0.0.0.0:8000..."
    set -l UVICORN "$VEGAS_DIR/webtool/backend/.venv/bin/uvicorn"
    if not test -x "$UVICORN"
        set UVICORN "$HOME/miniforge3/envs/vegas_env/bin/uvicorn"
    end
    if not test -x "$UVICORN"
        set UVICORN uvicorn
    end

    $UVICORN app.main:app --app-dir "$VEGAS_DIR/webtool/backend" --host 0.0.0.0 --port 8000 </dev/null > /tmp/vegas_backend.log 2>&1 &
    set -l BACKEND_PID $last_pid

    # 5. Start Frontend in background
    echo "Starting VegasAfterglow Frontend on 0.0.0.0:3000..."
    set -l START_DIR $PWD
    cd "$VEGAS_DIR/webtool/frontend"
    npm run dev -- -H 0.0.0.0 -p 3000 </dev/null > /tmp/vegas_frontend.log 2>&1 &
    set -l FRONTEND_PID $last_pid
    cd "$START_DIR"

    echo ""
    echo "================================================="
    echo " VegasAfterglow Web Tool is LIVE!"
    echo " -> PC Local Access:           http://localhost:3000"
    echo " -> Remote Access (Tailscale): http://$TS_IP:3000"
    echo " -> Backend API Docs:          http://$TS_IP:8000/docs"
    echo "================================================="
    echo " Logs:"
    echo "   Backend:  tail -f /tmp/vegas_backend.log"
    echo "   Frontend: tail -f /tmp/vegas_frontend.log"
    echo " Press [Ctrl+C] to stop both servers."
    echo "================================================="

    trap "kill $BACKEND_PID $FRONTEND_PID 2>/dev/null; fuser -k 8000/tcp 2>/dev/null; fuser -k 3000/tcp 2>/dev/null; stty sane 2>/dev/null; command echo ''; command echo 'Servers stopped cleanly.'; trap - EXIT INT TERM" EXIT INT TERM
    wait
end
