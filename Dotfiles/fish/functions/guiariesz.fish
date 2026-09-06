function guiariesz --description 'Jump to persistent Zellij session with live GUI support on ARIES server'
    set session_name "aries_gui"
    if test -n "$argv[1]"
        set session_name $argv[1]
    end
    set target_dir (_get_aries_target_dir $argv[2])
    echo "Connecting to persistent GUI Zellij session '$session_name' on ARIES..."
    ssh -Y -t shashi@172.18.1.5 "echo \$DISPLAY > ~/.current_display ; cd '$target_dir' && exec bash --noprofile --rcfile ~/.bashrc -i -c 'zellij attach -c $session_name'"
end
