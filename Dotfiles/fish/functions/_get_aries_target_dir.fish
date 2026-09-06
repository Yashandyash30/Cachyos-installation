function _get_aries_target_dir
    if test -n "$argv[1]"
        echo $argv[1]
    else if string match -q "/mnt/ARIES*" $PWD
        set target_dir (string replace "/mnt/ARIES" "/home/shashi" $PWD)
        echo $target_dir
    else
        echo "/home/shashi"
    end
end
