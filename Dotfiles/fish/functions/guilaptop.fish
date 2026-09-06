function guilaptop
    set app_cmd $argv[1]
    if test -z "$app_cmd"
        echo "Please specify a tool (e.g., guilaptop pyraf)"
        return 1
    end
    
    set target_dir (_get_laptop_target_dir)
    
    echo "Starting Xpra Graphics Tunnel to Laptop..."
    ssh void@100.70.236.70 "xpra start :100 2>/dev/null"
    
    env GDK_BACKEND=x11 xpra attach ssh://void@100.70.236.70/100 >/dev/null 2>&1 &
    set xpra_pid $last_pid
    
    echo "Launching $app_cmd on Laptop at $target_dir..."
    ssh -t void@100.70.236.70 "cd '$target_dir' && set -x DISPLAY :100 && exec fish -i -C '$app_cmd'"
    
    kill $xpra_pid
end
