function tunnelaries --description 'Open SSH tunnel for Jupyter / Web services on ARIES'
    set port 8888
    if test -n "$argv[1]"
        set port $argv[1]
    end
    echo "================================================="
    echo " Forwarding localhost:$port -> ARIES:$port"
    echo " Access Jupyter at: http://localhost:$port"
    echo " Press [Ctrl+C] to disconnect the tunnel."
    echo "================================================="
    ssh -N -L $port:localhost:$port aries
end
