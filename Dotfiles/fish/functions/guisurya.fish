function guisurya --description 'Run remote GUI application on Surya HPC with live X11 forwarding'
    set app_cmd $argv[1]
    if test -z "$app_cmd"
        echo "Usage: guisurya <command> [target_dir]"
        echo "Examples: guisurya ds9, guisurya pyraf, guisurya 'mesa26 && ./rn'"
        return 1
    end
    set target_dir (_get_surya_target_dir $argv[2])
    echo "Launching $app_cmd on Surya HPC at $target_dir with live GUI forwarding..."
    ssh -Y -t yashsharma@192.168.4.1 "cd '$target_dir' && exec bash --noprofile --rcfile ~/.bashrc -i -c '$app_cmd'"
end
