function guiaries --description 'Run remote GUI application on ARIES server with live X11 forwarding'
    set app_cmd $argv[1]
    if test -z "$app_cmd"
        echo "Usage: guiaries <command> [target_dir]"
        echo "Examples: guiaries ds9, guiaries 'rmfit', guiaries 'mesa23 && ./rn'"
        return 1
    end
    set target_dir (_get_aries_target_dir $argv[2])
    echo "Launching $app_cmd on ARIES at $target_dir with live GUI forwarding..."
    ssh -Y -t shashi@172.18.1.5 "cd '$target_dir' && exec bash --noprofile --rcfile ~/.bashrc -i -c '$app_cmd'"
end
