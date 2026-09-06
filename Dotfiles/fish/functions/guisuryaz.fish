function guisuryaz --description 'Jump to persistent Zellij session with live GUI support on Surya HPC'
    set session_name "surya_gui"
    if test -n "$argv[1]"
        set session_name $argv[1]
    end
    set target_dir (_get_surya_target_dir $argv[2])
    echo "Connecting to persistent GUI Zellij session '$session_name' on Surya HPC..."
    ssh -Y -t yashsharma@192.168.4.1 "echo \$DISPLAY > ~/.current_display ; cd '$target_dir' && exec bash --noprofile --rcfile ~/.bashrc -i -c 'zellij attach -c $session_name'"
end
