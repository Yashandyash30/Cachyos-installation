function _get_surya_target_dir
    if test -n "$argv[1]"
        echo $argv[1]
    else if string match -q "/mnt/Surya*" $PWD
        set target_dir (string replace "/mnt/Surya" "/home/yashsharma" $PWD)
        echo $target_dir
    else
        echo "/home/yashsharma"
    end
end
