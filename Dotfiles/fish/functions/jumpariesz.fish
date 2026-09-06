function jumpariesz --description 'Jump to persistent Zellij session on ARIES server'
    set session_name "aries_main"
    if test -n "$argv[1]"
        set session_name $argv[1]
    end
    set target_dir (_get_aries_target_dir $argv[2])
    echo "Jumping to Zellij session '$session_name' on ARIES at $target_dir..."
    ssh -t shashi@172.18.1.5 "cd '$target_dir' && exec bash --noprofile --rcfile ~/.bashrc -i -c 'zellij attach -c $session_name'"
end
