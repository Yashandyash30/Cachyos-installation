function jumpsuryaz --description 'Jump to persistent Zellij session on Surya HPC'
    set session_name "surya_main"
    if test -n "$argv[1]"
        set session_name $argv[1]
    end
    set target_dir (_get_surya_target_dir $argv[2])
    echo "Jumping to Zellij session '$session_name' on Surya HPC at $target_dir..."
    ssh -t yashsharma@192.168.4.1 "cd '$target_dir' && exec bash --noprofile --rcfile ~/.bashrc -i -c 'zellij attach -c $session_name'"
end
